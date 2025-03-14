import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class Message {
  final String userId;
  final String content;
  final DateTime sentAt = DateTime.now();
  final String type = 'text';

  Message({required this.userId, required this.content});
}

class MessageProvider with ChangeNotifier {
  late WebSocketChannel channel;
  final List<Message> _messages = [];

  List<Message> get messages => _messages;

  void connect(String channelId) {
    channel = WebSocketChannel.connect(Uri.parse('${dotenv.env['WS_PATH']}/channels/$channelId/send'));

    channel.stream.listen((message) {
      final decodedMessage = json.decode(message);
      _messages.add(Message(userId: decodedMessage['UserID'], content: decodedMessage['Content']));
      notifyListeners();
    });
  }

  void sendMessage(String userId, String content, DateTime sentAt, String type) {
    final message = jsonEncode({'UserID': userId, 'Content': content, 'SentAt': sentAt.toString(), 'Type': type});
    channel.sink.add(message);
  }

  void disconnect() {
    channel.sink.close();
  }
}
