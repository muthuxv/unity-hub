import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String serverId;

  const UserProfilePage({Key? key, required this.userId, required this.serverId}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late String currentUserID;
  bool isFriend = false;
  bool isLoading = true;
  Map<String, dynamic> userInfo = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUserID();
    await _fetchUserInfo();
    await _checkFriendStatus();
  }

  Future<void> _getCurrentUserID() async {
    const storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(jwtToken!);
    setState(() {
      currentUserID = decodedToken['jti'];
    });
  }

  Future<void> _fetchUserInfo() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await Dio().get(
        'http://10.0.2.2:8080/users/${widget.userId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      setState(() {
        userInfo = response.data;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user info: $e')),
      );
    }
  }

  Future<void> _checkFriendStatus() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await Dio().get(
        'http://10.0.2.2:8080/friends',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final List<dynamic> friends = response.data;

      setState(() {
        isFriend = friends.any((friend) =>
        (friend['UserID1'] == currentUserID && friend['UserID2'] == widget.userId) ||
            (friend['UserID2'] == currentUserID && friend['UserID1'] == widget.userId)
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking friend status: $e')),
      );
    }
  }

  Future<void> _sendFriendRequest() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      await Dio().post(
        'http://10.0.2.2:8080/friends/request',
        data: {
          'userID1': currentUserID,
          'userID2': widget.userId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent')),
      );
      _checkFriendStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending friend request: $e')),
      );
    }
  }

  Future<void> _removeFriend() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      await Dio().delete(
        'http://10.0.2.2:8080/friends/${widget.userId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend removed')),
      );
      _checkFriendStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing friend: $e')),
      );
    }
  }

  void _showReportUserDialog(BuildContext context) {
    TextEditingController _reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool _isButtonDisabled = true;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Signaler l'utilisateur"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _reportController,
                    decoration: InputDecoration(
                      labelText: 'Raison du signalement',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isButtonDisabled = value.trim().isEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuler'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Envoyer'),
                  onPressed: _isButtonDisabled
                      ? null
                      : () async {
                    Navigator.of(context).pop();
                    await _sendUserReport(widget.userId, _reportController.text);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendUserReport(String reportedID, String reportMessage) async {
    const storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(jwtToken!);
    final userID = decodedToken['jti'];

    final reportData = {
      "message": reportMessage,
      "status": "pending",
      "userID": userID,
      "serverID": widget.serverId,
      "ReportedID": reportedID,
    };

    try {
      await Dio().post(
        'http://10.0.2.2:8080/reports',
        data: reportData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message signalé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du signalement: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              child: _buildProfileWidget(),
            ),
            SizedBox(height: 8),
            Text(
              userInfo['Pseudo'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isFriend ? _removeFriend : _sendFriendRequest,
              child: Text(isFriend ? 'Supprimer l\'ami' : 'Ajouter en ami'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFriend ? Colors.red : Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showReportUserDialog(context),
              child: Text('Signaler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileWidget() {
    return userInfo['Profile'] != null && userInfo['Profile'].contains('<svg')
        ? SvgPicture.string(
      userInfo['Profile'],
      height: 100,
      width: 100,
    )
        : Text(
      userInfo['Pseudo']?.substring(0, 1) ?? '',
      style: TextStyle(fontSize: 40),
    );
  }
}