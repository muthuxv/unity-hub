import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unity_hub/pages/profil/user_profil_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/svg.dart';
import 'package:giphy_picker/giphy_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:unity_hub/utils/messaging_service.dart';
import 'package:flutter/services.dart';

class ChannelPage extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String serverId;
  final bool canSendMessage;

  const ChannelPage({super.key, required this.channelId, required this.channelName, required this.serverId, required this.canSendMessage});

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
  final MessagingService messagingService = MessagingService();

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

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get('$apiPath/channels/${widget.channelId}/messages');
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

  Future<void> _connectToWebSocket() async {
    const storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');

    _channel = WebSocketChannel.connect(
      Uri.parse('${dotenv.env['WS_PATH']}/channels/${widget.channelId}/send?token=$jwtToken'),
    );

    _channel.stream.listen((message) async {
      final dynamic data = jsonDecode(message);
      final DateTime createdAt = DateTime.parse(data['SentAt']);
      final String formattedDate = DateFormat('yyyy-MM-dd').format(createdAt);

      setState(() {
        _messagesByDate.putIfAbsent(formattedDate, () => []);
        _messagesByDate[formattedDate]!.add(data);
      });

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

    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isNotEmpty) {
      _channel.sink.add(jsonEncode({
        'UserID': currentUserID,
        'Content': message,
        'Type': 'Text',
        'SentAt': DateTime.now().toIso8601String(),
      }));
      _messageController.clear();

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

  void _showConfirmationDialog(String messageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce message ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Oui'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _deleteMessage(messageId);
              },
            ),
            TextButton(
              child: Text('Non'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  void _showModalBottomSheet(BuildContext context, dynamic message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Copier'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message['Content']));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Message copié')),
                );
              },
            ),
            if (message['UserID'].toString() != currentUserID)
              ListTile(
                leading: Icon(Icons.report),
                title: Text('Signaler le message'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context, message);
                },
              ),
            if (message['UserID'].toString() != currentUserID)
              ListTile(
              leading: Icon(Icons.report),
              title: Text("Signaler l'utilisateur"),
              onTap: () {
                Navigator.pop(context);
                _showReportUserDialog(context, message);
              },
            ),
            if (message['UserID'].toString() == currentUserID)
              ListTile(
                leading: Icon(Icons.delete),
                iconColor: Colors.red,
                title: Text('Supprimer le message'),
                textColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmationDialog(message['ID']);
                },
              ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, dynamic message) {
    TextEditingController _reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool _isButtonDisabled = true;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Signaler le message'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _reportController,
                    decoration: InputDecoration(
                      labelText: 'Raison du signalement',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isButtonDisabled = value.trim().isEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuler'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Envoyer'),
                  onPressed: _isButtonDisabled
                      ? null
                      : () async {
                    Navigator.of(context).pop();
                    await _sendReport(message['ID'], _reportController.text);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportUserDialog(BuildContext context, dynamic message) {
    TextEditingController _reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool _isButtonDisabled = true;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Signaler l'utilisateur"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _reportController,
                    decoration: InputDecoration(
                      labelText: 'Raison du signalement',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isButtonDisabled = value.trim().isEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuler'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Envoyer'),
                  onPressed: _isButtonDisabled
                      ? null
                      : () async {
                    Navigator.of(context).pop();
                    await _sendUserReport(message['UserID'], _reportController.text);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }




  Future<void> _sendReport(String messageID, String reportMessage) async {
    const storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(jwtToken!);
    final userID = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final reportData = {
      "message": reportMessage,
      "status": "pending",
      "messageID": messageID,
      "userID": userID,
      "serverID": widget.serverId,
    };

    try {
      await Dio().post(
        '$apiPath/reports',
        data: reportData,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message signalé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du signalement: $e')),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    setState(() {
      _isLoading = true;
    });

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      await Dio().put(
        '$apiPath/messages/$messageId',
        data: {'Content': 'Ce message a été supprimé par l\'utilisateur'},
      );
      // Update the local state to reflect the message deletion
      setState(() {
        _messagesByDate.forEach((date, messages) {
          final messageIndex = messages.indexWhere((message) => message['ID'] == messageId);
          if (messageIndex != -1) {
            messages[messageIndex]['Content'] = 'Ce message a été supprimé par l\'utilisateur';
          }
        });
      });
    } catch (error) {
      _showErrorSnack('Une erreur s\'est produite lors de la suppression du message.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  List<TextSpan> formatMessage(String content) {
    List<TextSpan> spans = [];
    RegExp bold = RegExp(r'\*\*(.*?)\*\*');
    RegExp italic = RegExp(r'\*(.*?)\*');
    RegExp underline = RegExp(r'__(.*?)__');

    while (content.isNotEmpty) {
      if (bold.hasMatch(content)) {
        var match = bold.firstMatch(content)!;
        spans.add(TextSpan(text: match.group(1), style: TextStyle(fontWeight: FontWeight.bold)));
        content = content.substring(match.end);
      } else if (italic.hasMatch(content)) {
        var match = italic.firstMatch(content)!;
        spans.add(TextSpan(text: match.group(1), style: TextStyle(fontStyle: FontStyle.italic)));
        content = content.substring(match.end);
      } else if (underline.hasMatch(content)) {
        var match = underline.firstMatch(content)!;
        spans.add(TextSpan(text: match.group(1), style: TextStyle(decoration: TextDecoration.underline, decorationThickness: 1.5)));
        content = content.substring(match.end);
      } else {
        spans.add(TextSpan(text: content));
        content = '';
      }
    }

    return spans;
  }

  Future<void> _sendUserReport(String reportedID, String reportMessage) async {
    const storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(jwtToken!);
    final userID = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final reportData = {
      "message": reportMessage,
      "status": "pending",
      "userID": userID,
      "serverID": widget.serverId,
      "ReportedID": reportedID,
    };

    try {
      await Dio().post(
        '$apiPath/reports',
        data: reportData,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message signalé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du signalement: $e')),
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

                        return GestureDetector(
                          onLongPress: () => _showModalBottomSheet(context, message),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                if (!isCurrentUser)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UserProfilePage(serverId: widget.serverId, userId: message['User']['ID']),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: CircleAvatar(
                                        child: _buildProfileWidget(message),
                                      ),
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
                                        if (message['Type'] == 'Text') ...[
                                          Text.rich(
                                            TextSpan(
                                              children: formatMessage(message['Content']),
                                              style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
                                            ),
                                          ),
                                        ],
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
                    onSubmitted: widget.canSendMessage ? (value) {
                      _sendMessage(value);
                    } : null,
                    enabled: widget.canSendMessage,  // Disable the TextField if canSendMessage is false
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: widget.canSendMessage ? () {
                    _sendMessage(_messageController.text);
                  } : null,
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: widget.canSendMessage ? () async {
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
                  } : null,
                ),
              ],
            ),
          )
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
    ) : CircleAvatar(
        backgroundImage: NetworkImage(message['User']['Profile'])
    );
  }
}