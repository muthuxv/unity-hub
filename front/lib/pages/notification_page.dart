import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

  void _getInvitations() async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    try {
      final response = await Dio().get(
        'http://10.0.2.2:8080/invitations/user/$userId',
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
          : _invitations.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.noInvitations))
          : ListView.separated(
        separatorBuilder: (context, index) => const Divider(color: Colors.grey),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
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
                      'http://10.0.2.2:8080/servers/${invitation['Server']['ID']}/join',
                      options: Options(
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer $token',
                        },
                      ),
                    );
                    if (response.statusCode == 200) {
                      final response = await Dio().delete(
                        'http://10.0.2.2:8080/invitations/${invitation['ID']}',
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
                      'http://10.0.2.2:8080/invitations/${invitation['ID']}',
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
        },
      ),
    );
  }
}