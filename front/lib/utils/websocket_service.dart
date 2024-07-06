import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void disconnect() {
    _channel?.sink.close();
  }

  void send(dynamic message) {
    print('Sending message: $message');
    print(message is String ? message : jsonEncode(message));
    _channel?.sink.add(jsonEncode(message));
  }

  Stream get stream => _channel!.stream;
}