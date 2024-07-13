import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_hub/providers/group_provider.dart';
import 'create_group_page.dart';
import 'group_chat_page.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  //get the user id
  Future<String> getUserId() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(token!);
    return decodedToken['jti'];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DMs & Groupes'),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            itemCount: provider.groups.length,
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              return ListTile(
                leading: group.type == 'dm' ? group.image.isNotEmpty ?
                group.image.contains('svg') ? SvgPicture.string(group.image, width:50, height:50) : CircleAvatar(backgroundImage: NetworkImage(group.image), radius: 25,) : const CircleAvatar(child: Icon(Icons.person)) : const CircleAvatar(radius: 25, child: Icon(Icons.group)),
                title: group.type == 'dm' ? Text(group.name) : Text(group.name),
                titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                ),
                horizontalTitleGap: 10,
                minVerticalPadding: 20,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GroupChatPage(group: group, userId: getUserId())),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
