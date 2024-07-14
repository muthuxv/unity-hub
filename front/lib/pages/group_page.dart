import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_hub/providers/group_provider.dart';
import 'create_group_page.dart';
import 'group_chat_page.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  String _filter = 'all'; // State to hold the current filter selection

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
        actions: [
          PopupMenuButton<String>(
              onSelected: (String result) {
                setState(() {
                  _filter = result;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'all',
                  child: Text('Tous', style: TextStyle(
                      color: Colors.white
                  ),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'dm',
                  child: Text('DM', style: TextStyle(
                      color: Colors.white
                  ),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'group',
                  child: Text('Groupes', style: TextStyle(
                      color: Colors.white
                  ),
                  ),
                ),
              ],
              icon: const Icon(Icons.filter_list),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(15.0),
                ),
              ),
              color: Colors.deepPurpleAccent
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          final filteredGroups = provider.groups.where((group) {
            if (_filter == 'all') return true;
            return group.type == _filter;
          }).toList();

          return filteredGroups.isEmpty ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message_rounded, color: Colors.grey, size: 32),
                SizedBox(height: 10),
                Text(
                  'Aucune discussion.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ) : ListView.builder(
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final group = filteredGroups[index];
              return ListTile(
                leading: group.type == 'dm'
                    ? group.image.isNotEmpty
                    ? group.image.contains('svg')
                    ? SvgPicture.string(group.image, width: 50, height: 50)
                    : CircleAvatar(
                  backgroundImage: NetworkImage(group.image),
                  radius: 25,
                )
                    : const CircleAvatar(child: Icon(Icons.person))
                    : const CircleAvatar(radius: 25, child: Icon(Icons.group)),
                title: Text(
                  group.name.length > 25
                      ? '${group.name.substring(0, 25)}...'
                      : group.name,
                ),
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
                    MaterialPageRoute(
                      builder: (context) => GroupChatPage(
                        group: group,
                        userId: getUserId(),
                      ),
                    ),
                  );
                },
                onLongPress: () {
                  if (group.type == 'group') {
                    _showLeaveGroupModal(context, group, provider);
                  }
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

  void _showLeaveGroupModal(BuildContext context, group, GroupProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                title: const Text('Quitter le groupe', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  _showLeaveGroupConfirmationDialog(context, group, provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaveGroupConfirmationDialog(BuildContext context, group, GroupProvider provider) async {
    final userId = await getUserId(); // Get the user ID before showing the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer'),
          content: const Text('Voulez-vous vraiment quitter ce groupe ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await provider.leaveGroup(group.id, userId);
                  Navigator.of(context).pop(); // Close the dialog
                } catch (e) {
                  // Handle error
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Échec de la sortie du groupe.')),
                  );
                }
              },
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );
  }
}
