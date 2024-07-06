import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SendInvitationPage extends StatefulWidget {
  final int serverId;

  const SendInvitationPage({super.key, required this.serverId});

  @override
  _SendInvitationPageState createState() => _SendInvitationPageState();
}

class _SendInvitationPageState extends State<SendInvitationPage> {
  bool _isLoading = false;
  List _friends = [];
  final List<int> _selectedFriends = [];

  @override
  void initState() {
    super.initState();
    _getFriends();
  }

  void _getFriends() async {
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
      setState(() {
        _friends = response.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendInvitations() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    for (int friendId in _selectedFriends) {
      final response = await Dio().post(
        'http://10.0.2.2:8080/invitations/server/${widget.serverId}',
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
                  return CheckboxListTile(
                    title: Text(friend['UserPseudo']),
                    value: _selectedFriends.contains(friend['FriendID']),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedFriends.add(friend['FriendID']);
                        } else {
                          _selectedFriends.remove(friend['FriendID']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _selectedFriends.isEmpty ? null : _sendInvitations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              ),
              child: Text(
                AppLocalizations.of(context)!.sendButton,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
