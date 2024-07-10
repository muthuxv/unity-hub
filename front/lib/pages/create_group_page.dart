import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:unity_hub/providers/group_provider.dart';
import 'package:unity_hub/models/group_model.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  List<User> friends = [];
  List<String> selectedFriends = [];
  bool _isLoading = false;

  @override
  void initState() {
    fetchFriends();
    super.initState();
  }

  //fetch friends
  Future<void> fetchFriends() async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    final response = await Dio().get(
      'http://10.0.2.2:8080/friends/users/$userId',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      if (data.isEmpty) {
        setState(() {
          _isLoading = false;
        });
      } else {
        friends = data.map((item) => User(id: item['FriendID'], name: item['UserPseudo'])).toList();
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un DM ou un groupe'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : friends.isEmpty
              ? const Center(child: Text('Aucun ami trouvé'))
              : ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return CheckboxListTile(
            title: Text(friend.name),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedFriends.length == 1) {
            Provider.of<GroupProvider>(context, listen: false).createDM(selectedFriends.first);
          } else if (selectedFriends.length > 1) {
            Provider.of<GroupProvider>(context, listen: false).createGroup(selectedFriends);
          }
          Navigator.pop(context);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
