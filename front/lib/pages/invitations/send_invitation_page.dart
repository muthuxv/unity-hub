import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SendInvitationPage extends StatefulWidget {
  final String serverId;

  const SendInvitationPage({super.key, required this.serverId});

  @override
  _SendInvitationPageState createState() => _SendInvitationPageState();
}

class _SendInvitationPageState extends State<SendInvitationPage> {
  bool _isLoading = false;
  List _friends = [];
  List _bannedUsers = [];
  final Map<String, bool> _selectedFriends = {};

  @override
  void initState() {
    super.initState();
    _getFriendsAndBans();
  }

  Future<void> _getFriendsAndBans() async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    try {
      // Fetch friends
      final friendsResponse = await Dio().get(
        'https://unityhub.fr/friends/users/$userId',
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

      // Fetch banned users
      final bansResponse = await Dio().get(
        'https://unityhub.fr/servers/${widget.serverId}/bans',
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

      if (friendsResponse.statusCode == 200 && bansResponse.statusCode == 200) {
        setState(() {
          _friends = friendsResponse.data;
          _bannedUsers = bansResponse.data.map((ban) => ban['UserID']).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('An error occurred: $e');
    }
  }

  void _sendInvitations() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    for (String friendId in _selectedFriends.keys) {
      final response = await Dio().post(
        'https://unityhub.fr/invitations/server/${widget.serverId}',
        data: {'userReceiverId': friendId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            return status! < 501;
          },
        ),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.invitationSentSuccess),
          ),
        );
      } else {
        String errorMessage = AppLocalizations.of(context)!.invitationSendFailure;
        if (response.data != null && response.data['error'] != null) {
          errorMessage = response.data['error'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );
      }
    }

    setState(() {
      _selectedFriends.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sendInvitations),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  // Filter out banned friends
                  if (_bannedUsers.contains(friend['FriendID'])) {
                    return SizedBox.shrink();
                  }
                  return ListTile(
                    title: Text(friend['UserPseudo']),
                    leading: CircleAvatar(
                      child: (friend['Profile'] != null && friend['Profile'].contains('<svg'))
                          ? SvgPicture.string(
                        friend['Profile'],
                        height: 40,
                        width: 40,
                      )
                          : (friend['Profile'] != null && friend['UserPseudo'].isNotEmpty)
                          ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(friend['Profile']),
                      )
                          : CircleAvatar(
                        child: Text(friend['UserPseudo'] != null ? friend['UserPseudo'][0] : 'U'),
                      ),
                    ),
                    trailing: Checkbox(
                      value: _selectedFriends[friend['FriendID']] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          _selectedFriends[friend['FriendID']] = value ?? false;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _selectedFriends.values.any((isSelected) => isSelected) ? _sendInvitations : null,
              child: Text(AppLocalizations.of(context)!.sendButton),
            ),
          ],
        ),
      ),
    );
  }
}