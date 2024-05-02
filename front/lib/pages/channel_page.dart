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

  //get current user id
  String currentUserID = '';

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

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _getCurrentUserID();
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8080/channels/${widget.channelId}/send'),
    );
    _channel.stream.listen((message) {
      print('Received message: $message');
      // Handle received message here
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  void _sendMessage(String message) {
    _channel.sink.add(message);
    print('Sent message: $message');
    // Optionally, update UI with sent message
    setState(() {
      _messages.add({
        'userID': currentUserID,
        'Content': message,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : // Display messages + input field
      Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Align(
                    alignment: _messages[index]['userID'] == currentUserID ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _messages[index]['userID'] == currentUserID ? Colors.blue[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.all(8.0),
                      child: Text(_messages[index]['Content']),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
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
