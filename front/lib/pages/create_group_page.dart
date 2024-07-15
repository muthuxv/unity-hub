import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:unity_hub/providers/group_provider.dart';
import 'package:unity_hub/models/group_model.dart';

class CreateGroupPage extends StatefulWidget {
  final String groupId;
  final List<dynamic> members;

  const CreateGroupPage({super.key, this.groupId = '', this.members = const []});

  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  List<User> friends = [];
  List<String> selectedFriends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception("Token not found");
      }
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['jti'];

      final dio = Dio();
      dio.options.headers['Content-Type'] = 'application/json';
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.get('http://10.0.2.2:8080/friends/users/$userId');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        friends = data.map((item) => User(id: item['FriendID'], name: item['UserPseudo'])).toList();
        if (widget.members.isNotEmpty) {
          friends = friends.where((friend) => !widget.members.any((member) => member.id == friend.id)).toList();
        }
      } else {
        throw Exception("Failed to load friends");
      }
    } catch (e) {
      print("Error fetching friends: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildFriendList() {
    return friends.isEmpty
        ? const Center(child: Text('Aucun ami trouvé'))
        : ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return CheckboxListTile(
          title: Text(friend.name, style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          )),
          value: selectedFriends.contains(friend.id),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selectedFriends.add(friend.id);
              } else {
                selectedFriends.remove(friend.id);
              }
            });
          },
        );
      },
    );
  }

  Future<void> handleCreateGroup() async {
    if (selectedFriends.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception("Token not found");
    }

    final dio = Dio();
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['Authorization'] = 'Bearer $token';

    if (selectedFriends.length == 1 && widget.groupId.isEmpty) {
      Provider.of<GroupProvider>(context, listen: false).createDM(selectedFriends.first);
    } else {
      List<String> memberIds = selectedFriends;
      if (widget.groupId.isNotEmpty) {
        final response = await dio.get('http://10.0.2.2:8080/groups/${widget.groupId}');
        if (response.statusCode == 200) {
          final groupData = response.data;
          if (groupData['Type'] == 'dm') {
            List<String> existingMemberIds = List<String>.from(widget.members.map((member) => member.id));
            memberIds.addAll(existingMemberIds);
            memberIds = memberIds.toSet().toList();
          }
        }
      }
      Provider.of<GroupProvider>(context, listen: false).createGroup(memberIds, widget.groupId);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un DM ou un groupe'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildFriendList(),
      floatingActionButton: FloatingActionButton(
        onPressed: handleCreateGroup,
        child: const Icon(Icons.check),
      ),
    );
  }
}
