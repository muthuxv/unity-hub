import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? userId;
  String? token;
  bool _isLoading = false;
  List _invitations = [];
  List _friendRequests = [];

  void _getInvitations() async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/invitations/user/$userId',
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
        _getFriendRequests();
        setState(() {
          _invitations = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(response.data['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.errorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.closeButton),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
      ),
    );
  }

  void _getFriendRequests() async {
    const storage = FlutterSecureStorage();
    token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/friends/pending/$userId',
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
          _friendRequests = response.data;
        });
      } else {
        _showErrorDialog(response.data['message']);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _acceptFriendRequest(String friendId) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().post(
      '$apiPath/friends/accept',
      data: {
        'ID': friendId,
        'UserID2': userId,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    if (response.statusCode == 200) {
      _getFriendRequests();
      _showSuccessDialog(AppLocalizations.of(context)!.friendRequestAccepted);
    } else {
      _showErrorDialog(AppLocalizations.of(context)!.friendRequestRefused);
    }
  }

  void _refuseFriendRequest(String friendId) async {

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().post(
      '$apiPath/friends/refuse',
      data: {
        'ID': friendId,
        'UserID2': userId,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200) {
      _getFriendRequests();
    } else {
      _showErrorDialog(AppLocalizations.of(context)!.errorCancellingFriendRequest);
    }
  }

  @override
  void initState() {
    super.initState();
    _getInvitations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationsTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invitations.isEmpty && _friendRequests.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.noInvitations))
          : ListView.separated(
        separatorBuilder: (context, index) => const Divider(color: Colors.grey),
        itemCount: _invitations.length + _friendRequests.length,
        itemBuilder: (context, index) {
          if (index < _invitations.length) {
            var invitation = _invitations[index];
            return ListTile(
              title: Text(
                  '${invitation['UserSender']['Pseudo']} '
                      '${AppLocalizations.of(context)!.invitationMessage(invitation['Server']['Name'])}'
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      final response = await Dio().post(
                        '${dotenv.env['API_PATH']}/servers/${invitation['Server']['ID']}/join',
                        options: Options(
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                        ),
                      );
                      if (response.statusCode == 200) {
                        final response = await Dio().delete(
                          '${dotenv.env['API_PATH']}/invitations/${invitation['ID']}',
                          options: Options(
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $token',
                            },
                          ),
                        );
                        if (response.statusCode == 204) {
                          _getInvitations();
                          _showSuccessDialog(AppLocalizations.of(context)!.joinSuccessMessage);
                        } else {
                          _showErrorDialog(AppLocalizations.of(context)!.deleteInvitationError);
                        }
                      } else {
                        _showErrorDialog(AppLocalizations.of(context)!.acceptInvitationError);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      final response = await Dio().delete(
                        '${dotenv.env['API_PATH']}/invitations/${invitation['ID']}',
                        options: Options(
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                        ),
                      );
                      if (response.statusCode == 204) {
                        _getInvitations();
                      } else {
                        _showErrorDialog(AppLocalizations.of(context)!.deleteInvitationError);
                      }
                    },
                  ),
                ],
              ),
            );
          } else {
            var friendRequest = _friendRequests[index - _invitations.length];
            return ListTile(
              title: Text(
                '${friendRequest['UserPseudo']} '
                    '${AppLocalizations.of(context)!.friend_invitation}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      _acceptFriendRequest(friendRequest['ID']);
                      _getFriendRequests();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      _refuseFriendRequest(friendRequest['ID']);
                      _getFriendRequests();
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}