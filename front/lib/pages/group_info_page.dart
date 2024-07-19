import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unity_hub/models/group_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'create_group_page.dart';

class GroupInfoPage extends StatefulWidget {
  final Group group;

  const GroupInfoPage({super.key, required this.group});

  @override
  _GroupInfoPageState createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await getUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<String> getUserId() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(token!);
    return decodedToken['jti'];
  }

  void _addMember() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupPage(
          groupId: widget.group.id,
          members: widget.group.members,
        ),
      ),
    );
  }

  Future<void> _kickMember(String memberId) async {
    final dio = Dio();

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final url = '$apiPath/groups/${widget.group.id}/members/$memberId';
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await dio.delete(url,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            }
          )
      );

      if (response.statusCode == 204) {
        setState(() {
          widget.group.members.removeWhere((member) => member.id == memberId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membre supprimé du groupe.')),
        );
      } else {
        throw Exception('Failed to kick member');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la suppression du membre: $error')),
      );
    }
  }

  void _showKickMemberDialog(String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer'),
          content: Text('Voulez-vous vraiment expulser $memberName du groupe ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _kickMember(memberId);
              },
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informations du groupe", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Column(
              children: [
                widget.group.type == 'dm'
                    ? widget.group.image.isNotEmpty
                    ? widget.group.image.contains('svg')
                    ? SvgPicture.string(widget.group.image, width: 100, height: 100)
                    : CircleAvatar(
                  backgroundImage: NetworkImage(widget.group.image),
                  radius: 45,
                )
                    : const CircleAvatar(child: Icon(Icons.person))
                    : const CircleAvatar(radius: 45, child: Icon(Icons.group)),
                const SizedBox(height: 15),
                Text(
                  widget.group.name.length > 25 ? '${widget.group.name.substring(0, 25)}...' : widget.group.name,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 15),
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
                    trailing: widget.group.type == "group" ? widget.group.ownerId == _currentUserId && member.id != _currentUserId
                        ? IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        _showKickMemberDialog(member.id, member.name);
                      },
                    )
                        : null : null,
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
