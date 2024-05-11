import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

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
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Une erreur est survenue :('),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message)
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
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _invitations.isEmpty
          ? Center(child: Text('No invitations'))
          : ListView.separated(
        separatorBuilder: (context, index) => Divider(color: Colors.grey),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
          var invitation = _invitations[index];
          return ListTile(
            title: Text('${invitation['UserSender']['Pseudo']} vous invite à rejoindre le serveur ${invitation['Server']['Name']}.'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
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
                        _showSuccessDialog('You have successfully joined the server');
                      } else {
                        _showErrorDialog('Failed to delete invitation');
                      }
                    } else {
                      _showErrorDialog('Failed to accept invitation');
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
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
                      _showErrorDialog('Failed to delete invitation');
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }}