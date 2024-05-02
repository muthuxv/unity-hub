import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ChannelPage extends StatefulWidget {
  final int channelId;
  const ChannelPage({super.key, required this.channelId});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  bool _isLoading = false;
  List<dynamic> _messages = [];

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Dio().get('http://195.35.29.110:8080/channels/${widget.channelId}/messages');
      print('Response: $response');
      setState(() {
        _messages = response.data['data'];
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
                      return ListTile(
                        title: Text(message['content']),
                        subtitle: Text(message['user_id']),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
