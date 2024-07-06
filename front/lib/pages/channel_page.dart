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

class ChannelPage extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelPage({super.key, required this.channelId, required this.channelName});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> with WidgetsBindingObserver {
  bool _isLoading = false;
  late String currentUserID;
  late WebSocketChannel _channel;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final Map<String, List<dynamic>> _messagesByDate = {};

  @override
  void initState() {
    super.initState();
    _initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _channel.sink.close();
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
      final List<dynamic> messages = response.data;

      setState(() {
        for (dynamic message in messages) {
          final DateTime createdAt = DateTime.parse(message['SentAt']);
          final String formattedDate = DateFormat('yyyy-MM-dd').format(createdAt);

          _messagesByDate.putIfAbsent(formattedDate, () => []);
          _messagesByDate[formattedDate]!.add(message);
        }
      });
    } catch (error) {
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
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8080/channels/${widget.channelId}/send'),
    );

    _channel.stream.listen((message) {
      final dynamic data = jsonDecode(message);
      final DateTime createdAt = DateTime.parse(data['SentAt']);
      final String formattedDate = DateFormat('yyyy-MM-dd').format(createdAt);

      setState(() {
        _messagesByDate.putIfAbsent(formattedDate, () => []);
        _messagesByDate[formattedDate]!.add(data);
      });
    });
  }

  void _sendMessage(String message) {
    if (message.trim().isNotEmpty) {
      _channel.sink.add(jsonEncode({
        'UserID': currentUserID,
        'Content': message,
        'Type': 'Text',
        'SentAt': DateTime.now().toIso8601String(),
      }));
      _messageController.clear();

      // Delay the scrolling slightly to ensure the new message is added to the list
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
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
                      _channel.sink.add(jsonEncode({
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