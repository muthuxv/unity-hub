import 'package:flutter/material.dart';
import 'package:unity_hub/models/group_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';

import 'create_group_page.dart';

class GroupInfoPage extends StatefulWidget {
  final Group group;

  const GroupInfoPage({super.key, required this.group});

  @override
  _GroupInfoPageState createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  void _addMember() {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateGroupPage(groupId: widget.group.id, members: widget.group.members))
      );
  }

  void _removeMember(int index) {
    setState(() {
      widget.group.members.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informations du groupe", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: widget.group.type == 'dm'
                  ? widget.group.image.isNotEmpty
                  ? widget.group.image.contains('svg')
                  ? SvgPicture.string(widget.group.image, width: 50, height: 50)
                  : CircleAvatar(
                backgroundImage: NetworkImage(widget.group.image),
                radius: 25,
              )
                  : const CircleAvatar(child: Icon(Icons.person))
                  : const CircleAvatar(radius: 25, child: Icon(Icons.group)),
              title: Text(widget.group.name),
              titleTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
              horizontalTitleGap: 10,
              minVerticalPadding: 20,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.add),
              label: widget.group.type == 'dm' ? const Text('Créer un groupe') : const Text('Ajouter un membre'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Membres',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.group.members.length,
                itemBuilder: (context, index) {
                  final member = widget.group.members[index];
                  return ListTile(
                    leading: member.image.isNotEmpty
                        ? member.image.contains('svg')
                        ? SvgPicture.string(member.image, width: 50, height: 50)
                        : CircleAvatar(
                      backgroundImage: NetworkImage(member.image),
                      radius: 25,
                    )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member.name),
                    titleTextStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                    horizontalTitleGap: 10,
                    minVerticalPadding: 20,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
