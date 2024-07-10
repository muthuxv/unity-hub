import 'package:flutter/material.dart';

class GroupChatPage extends StatelessWidget {
  final String groupId;
  final String groupName;
  final Future<String> userId;

  const GroupChatPage({super.key, required this.groupId, required this.groupName, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Message 1'),
                ),
                ListTile(
                  title: const Text('Message 2'),
                ),
                ListTile(
                  title: const Text('Message 3'),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
