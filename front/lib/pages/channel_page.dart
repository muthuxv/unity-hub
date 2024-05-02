import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChannelPage extends StatefulWidget {
  final int channelId;

  const ChannelPage({Key? key, required this.channelId}) : super(key: key);

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  bool _isLoading = false;
  List<dynamic> _messages = [];
  final _messageController = TextEditingController();
  late WebSocketChannel _channel;

  late String currentUserID;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUserID();
    await _fetchMessages();
    _connectToWebSocket();
  }

  Future<void> _getCurrentUserID() async {
    final storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(jwtToken!);
    setState(() {
      currentUserID = decodedToken['jti'];
    });

    print('Current user ID: $currentUserID');
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
      await Dio().get('http://10.0.2.2:8080/channels/${widget.channelId}/messages');
      print('Response: $response');
      setState(() {
        _messages = response.data;
      });
      print('Messages fetched: $_messages');
    } catch (error) {
      print('Error fetching messages: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8080/channels/${widget.channelId}/send'),
    );
    _channel.stream.listen(
          (message) {
        print('Received message: $message');
        // Handle received message here
      },
      onError: (error) {
        print('WebSocket error: $error');
        // Handle WebSocket error here
      },
      onDone: () {
        print('WebSocket connection closed');
        // Handle WebSocket connection closed here, maybe attempt reconnection
      },
    );
  }

  void _sendMessage(String message) {
    _channel.sink.add(jsonEncode({
      'userID': currentUserID,
      'Content': message,
    }));
    print('Sent message: $message');
    setState(() {
      _messages.add({
        'UserID': currentUserID,
        'Content': message,
      });
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  child: Align(
                    alignment: message['UserID'].toString() == currentUserID
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: message['UserID'].toString() == currentUserID
                                ? Colors.blue[200]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(message['Content']),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['UserID'].toString() == currentUserID
                              ? 'You'
                              : 'Other user',
                          style: TextStyle(
                            color: message['UserID'].toString() == currentUserID
                                ? Colors.blue
                                : Colors.grey,

                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration:
            BoxDecoration(color: Theme.of(context).cardColor),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_messageController.text);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}