import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  bool isPending = false; // Ajout de cet état pour les invitations en attente
  Map<String, dynamic> userInfo = {};
  Map<String, dynamic> _friendInfo = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUserID();
    await _fetchUserInfo();
    await _checkFriendStatus();
    await _checkPendingInvitations(); // Ajout de cette ligne pour vérifier les invitations en attente
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

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/users/${widget.userId}',
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

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().get(
      '$apiPath/friends',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.data != null) {
      final friends = response.data as List;
      final friend = friends.firstWhere(
            (friend) => friend['FriendID'] == widget.userId,
        orElse: () => null,
      );

      if (friend != null) {
        setState(() {
          isFriend = true;
          _friendInfo = friend;
        });
      }
    }
  }

  Future<void> _checkPendingInvitations() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().get(
      '$apiPath/friends/pending/${userInfo['ID']}',
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

    if (response.data != null) {
      if (response.data.isEmpty) {
        setState(() {
          isPending = false;
        });
      }
        final pendingInvitations = response.data as List;
      final pending = pendingInvitations.firstWhere(
            (invitation) => invitation['FriendID'] == widget.userId,
        orElse: () => null,
      );

      if (pending != null) {
        setState(() {
          isPending = true;
          _friendInfo = pending;
        });
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      await Dio().post(
        '$apiPath/friends/request',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
        data: {
          'userId': currentUserID,
          'userPseudo': userInfo['Pseudo'],
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent')),
      );
      _checkPendingInvitations(); // Vérifie les invitations en attente après avoir envoyé la demande
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending friend request: $e')),
      );
    }
  }

  Future<void> _removeFriend() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      await Dio().delete(
        '$apiPath/friends/${_friendInfo['ID']}',
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
      _checkPendingInvitations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing friend: $e')),
      );
    }
  }

  Future<void> _cancelFriendRequest() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      await Dio().delete(
        '$apiPath/friends/${_friendInfo['ID']}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request cancelled')),
      );
      _checkPendingInvitations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling friend request: $e')),
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

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final reportData = {
      "message": reportMessage,
      "status": "pending",
      "userID": userID,
      "serverID": widget.serverId,
      "ReportedID": reportedID,
    };

    try {
      await Dio().post(
        '$apiPath/reports',
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
              onPressed: isFriend
                  ? _removeFriend
                  : isPending
                  ? _cancelFriendRequest
                  : _sendFriendRequest,
              child: Text(isFriend
                  ? 'Supprimer l\'ami'
                  : isPending
                  ? 'Annuler la demande d\'ami'
                  : 'Ajouter en ami'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFriend
                    ? Colors.red
                    : isPending
                    ? Colors.blueGrey
                    : Colors.green,
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