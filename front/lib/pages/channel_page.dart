import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/svg.dart';
import 'package:giphy_picker/giphy_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:unity_hub/utils/messaging_service.dart';

class ChannelPage extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String serverId;

  const ChannelPage({super.key, required this.channelId, required this.channelName, required this.serverId});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> with WidgetsBindingObserver {
  bool _isLoading = false;
  late String currentUserID;
  late WebSocketChannel _channel_message;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final Map<String, List<dynamic>> _messagesByDate = {};
  final MessagingService messagingService = MessagingService();

  @override
  void initState() {
    super.initState();
    _initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _channel_message.sink.close();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scrollToBottom();
  }

  void _initialize() async {
    await _getCurrentUserID();
    await _fetchMessages();
    _connectToWebSocket();
  }

  Future<void> _getCurrentUserID() async {
    const storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(jwtToken!);
    setState(() {
      currentUserID = decodedToken['jti'];
    });
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Dio().get('http://10.0.2.2:8080/channels/${widget.channelId}/messages');

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;

        if (responseData == null) {
          setState(() {
            _messagesByDate.clear();
          });
        } else if (responseData is List<dynamic>) {
          // Process valid list of messages
          final List<dynamic> messages = responseData;

          if (messages.isEmpty) {
            setState(() {
              _messagesByDate.clear(); // Clear existing messages
            });
          } else {
            Map<String, List<dynamic>> tempMessagesByDate = {};

            for (dynamic message in messages) {
              final DateTime createdAt = DateTime.parse(message['SentAt']);
              final String formattedDate = DateFormat('yyyy-MM-dd').format(createdAt);

              tempMessagesByDate.putIfAbsent(formattedDate, () => []);
              tempMessagesByDate[formattedDate]!.add(message);
            }

            setState(() {
              _messagesByDate.clear(); // Clear existing messages
              _messagesByDate.addAll(tempMessagesByDate); // Update with new messages
            });
          }
        } else {
          // Handle unexpected data type in response
          _showErrorSnack('Réponse inattendue du serveur.');
        }
      } else {
        // Handle unexpected status codes
        _showErrorSnack('Erreur: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching messages: $error'); // Log error details
      _showErrorSnack('Une erreur s\'est produite lors de la récupération des messages.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(message),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: () {
            _fetchMessages();
          },
        ),
      ),
    );
  }

  void _connectToWebSocket() {
    _channel_message = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8080/channels/${widget.channelId}/send'),
    );

    _channel_message.stream.listen((message) async {
      final dynamic data = jsonDecode(message);
      final DateTime createdAt = DateTime.parse(data['SentAt']);
      final String formattedDate = DateFormat('yyyy-MM-dd').format(createdAt);


      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic('channel-${widget.channelId}');

        final accessToken = await messagingService.generateAccessToken();
        final dio = Dio();
        await dio.post(
          'https://fcm.googleapis.com/v1/projects/unity-hub-446a0/messages:send',
          data: {
            'message': {
              'topic': 'channel-${widget.channelId}',
              'notification': {
                'title': data['User']['Pseudo'],
                'body': data['Content'],
              },
            },
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          ),
        );

        await FirebaseMessaging.instance.subscribeToTopic('channel-${widget.channelId}');
      } catch (e) {
        debugPrint('Error sending notification: $e');
      }

      setState(() {
        _messagesByDate.putIfAbsent(formattedDate, () => []);
        _messagesByDate[formattedDate]!.add(data);
      });
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isNotEmpty) {
      _channel_message.sink.add(jsonEncode({
        'UserID': currentUserID,
        'Content': message,
        'Type': 'Text',
        'SentAt': DateTime.now().toIso8601String(),
      }));
      _messageController.clear();

      // Wait for the message to be added to the list
      await Future.delayed(const Duration(milliseconds: 100));

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.channelName),
        elevation: 1.0,
        backgroundColor: Theme.of(context).cardColor,
        shadowColor: Colors.grey[50],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messagesByDate.length,
              itemBuilder: (context, index) {
                final String date = _messagesByDate.keys.elementAt(index);
                final List<dynamic> messagesForDate = _messagesByDate[date]!;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(date),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: messagesForDate.length,
                      itemBuilder: (context, index) {
                        final dynamic message = messagesForDate[index];
                        final bool isCurrentUser = message['UserID'].toString() == currentUserID;

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              if (!isCurrentUser)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: CircleAvatar(
                                    child: _buildProfileWidget(message),
                                  ),
                                ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            message['User']['Pseudo'],
                                            style: TextStyle(
                                              color: isCurrentUser ? Colors.white : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            DateFormat('HH:mm').format(DateTime.parse(message['SentAt'])),
                                            style: TextStyle(
                                              color: isCurrentUser ? Colors.white : Colors.black,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4.0),
                                      if (message['Type'] == 'Text')
                                        Text(
                                          message['Content'],
                                          style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
                                        ),
                                      if (message['Type'] == 'Image')
                                        Image.network(
                                          message['Content'],
                                          width: 200,
                                          height: 200,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isCurrentUser)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: CircleAvatar(
                                    child: _buildProfileWidget(message),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _sendMessage(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_messageController.text);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () async {
                    final GiphyGif? gif = await GiphyPicker.pickGif(
                      context: context,
                      apiKey: dotenv.env['GIPHY_KEY']!,
                      lang: GiphyLanguage.french,
                    );

                    if (gif != null) {
                      _channel_message.sink.add(jsonEncode({
                        'UserID': currentUserID,
                        'Content': gif.images.original?.url,
                        'Type': 'Image',
                        'SentAt': DateTime.now().toIso8601String(),
                      }));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileWidget(dynamic message) {
    return message['User']['Profile'] != null && message['User']['Profile'].contains('<svg')
        ? SvgPicture.string(
      message['User']['Profile'],
      height: 40,
      width: 40,
    )
        : Text(
      message['User']['Profile'] ?? 'No Profile',
      style: const TextStyle(fontSize: 20),
    );
  }
}