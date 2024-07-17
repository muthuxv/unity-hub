import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:unity_hub/utils/messaging_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FriendPage extends StatefulWidget {
  const FriendPage({super.key});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  final MessagingService messagingService = MessagingService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _showLoading = false;
  List _friends = [];
  List _filteredFriends = [];
  List _pendingRequests = [];
  List _sentRequests = [];

  void _getFriends() async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().get(
      '$apiPath/friends/users/$userId',
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
        _filteredFriends = _friends;
        _isLoading = false;
      });
      _getPendingRequests();
    } else {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(response.data['message']);
    }
  }

  void _getSentRequests() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().get(
      '$apiPath/friends/sent/$userId',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        _sentRequests = response.data;
      });
    } else {
      print('Erreur lors de la récupération des demandes envoyées');
    }
  }

  void _getPendingRequests() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

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
        _pendingRequests = response.data;
      });
    } else {
      print('Erreur de récupération des demandes en attente');
    }
  }

  void _acceptFriendRequest(String friendId) async {
    setState(() {
      _showLoading = true;
    });

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
      setState(() {
        _pendingRequests.removeWhere((item) => item['ID'].toString() == friendId);

        var newFriend = {
          'ID': response.data['ID'],
          'FriendID': response.data['FriendID'],
          'Status': response.data['Status'],
          'UserPseudo': response.data['UserPseudo'],
          'Email': response.data['UserMail'],
          'Profile': response.data['Profile']
        };

        _pendingRequests.removeWhere((item) => item['FriendID'].toString() == friendId);
        if (!_friends.any((friend) => friend['FriendID'] == newFriend['FriendID'])) {
          _friends.add(newFriend);
        }

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.friendRequestAccepted))
        );
      });
    } else {
      _showErrorDialog('Failed to accept friend request: ${response.data['message']}');
    }

    setState(() {
      _pendingRequests.removeWhere((item) => item['FriendID'].toString() == friendId);
      _showLoading = false;
    });
  }

  void _refuseFriendRequest(String friendId) async {
    setState(() {
      _showLoading = true;
    });

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
      setState(() {
        _pendingRequests.removeWhere((item) => item['ID'].toString() == friendId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.friendRequestRefused)));
    } else {
      _showErrorDialog('Failed to refuse friend request: ${response.data['message']}');
    }

    setState(() {
      _pendingRequests.removeWhere((item) => item['FriendID'].toString() == friendId);
      _showLoading = false;
    });
  }

  void _cancelFriendRequest(String friendId) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().delete(
        '$apiPath/friends/$friendId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 204) {
        setState(() {
          _sentRequests.removeWhere((item) => item['ID'].toString() == friendId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.friendRequestCancelled)),
        );
      } else {
        _showErrorDialog(response.data['message'] ?? AppLocalizations.of(context)!.errorCancellingFriendRequest);
      }
    } on DioError catch (e) {
      if (e.response != null) {
        _showErrorDialog(e.response!.data['message'] ?? AppLocalizations.of(context)!.unexpectedError);
      } else {
        _showErrorDialog("Failed to cancel friend request. Please check your network connection.");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getFriends();
    _getSentRequests();
    _searchController.addListener(_filterFriends);
  }

  void _filterFriends() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      setState(() {
        _filteredFriends = _friends.where((friend) {
          return friend['UserPseudo'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    } else {
      setState(() {
        _filteredFriends = _friends;
      });
    }
  }

  Widget _buildPendingRequestCard(Map request) {
    return GestureDetector(
      onTap: () => _showFriendRequestDialog(request),
      child: Container(
        width: 200,
        height: 80,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.lightBlue[50],
          border: Border.all(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(5),
                image: request['Profile'] != null && !request['Profile'].contains('<svg')
                    ? DecorationImage(
                  image: NetworkImage(request['Profile']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: request['Profile'] != null && request['Profile'].contains('<svg')
                  ? SvgPicture.string(
                request['Profile'],
                height: 60,
                width: 60,
                fit: BoxFit.cover,
              )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    request['UserPseudo'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppLocalizations.of(context)!.pending,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendRequestDialog(Map request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${AppLocalizations.of(context)!.wantToBeFriendWith} ${request['UserPseudo']} ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _acceptFriendRequest(request['ID'].toString());
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.accept),
            ),
            TextButton(
              onPressed: () {
                _refuseFriendRequest(request['ID'].toString());
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.refuse),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBottomModal(Map friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height / 2,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  friend['UserPseudo'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.group_add),
                        title: Text(AppLocalizations.of(context)!.inviteToServer),
                        onTap: () {
                          Navigator.pop(context);
                          _getFriendServers(friend['FriendID'].toString()); // Appel pour récupérer les serveurs de l'ami
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 50),
                        child: Divider(color: Colors.grey[400], thickness: 1),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: Text(AppLocalizations.of(context)!.delete),
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteConfirmationDialog(friend);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _getFriendServers(String friendId) async {
    setState(() {
      _showLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/servers/friend/$friendId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        _showServerListDialog(response.data['data'], friendId);
      } else {
        _showErrorDialog(response.data['message'] ?? 'Failed to fetch friend servers');
      }
    } catch (e) {
      _showErrorDialog('Failed to connect to server. Please check your network connection.');
    }

    setState(() {
      _showLoading = false;
    });
  }

  void _showServerListDialog(List<dynamic> servers, String friendId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectServer),
          content: SingleChildScrollView(
            child: ListBody(
              children: servers.map((server) {
                return ListTile(
                  title: Text(server['Name']),
                  onTap: () {
                    _sendInvitation(server['ID'], friendId);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _sendInvitation(String serverId, String friendId) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().post(
        '$apiPath/invitations/server/$serverId',
        data: {'userReceiverId': friendId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 501,
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send invitation. Please check your network connection.'),
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(Map friend) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteFriendConfirmation),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFriend(friend);
              },
              child: Text(AppLocalizations.of(context)!.yes),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.no),
            ),
          ],
        );
      },
    );
  }

  void _deleteFriend(Map friend) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().delete(
        '$apiPath/friends/${friend['ID']}',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 204) {
        setState(() {
          _friends.removeWhere((f) => f['FriendID'].toString() == friend['FriendID'].toString());
          _filteredFriends.removeWhere((f) => f['FriendID'].toString() == friend['FriendID'].toString());
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.friendDeleted)),
        );
      } else {
        _showErrorDialog(response.data['message'] ?? AppLocalizations.of(context)!.errorDeletingFriend);
      }
    } on DioError catch (e) {
      if (e.response != null) {
        _showErrorDialog(e.response!.data['message'] ?? AppLocalizations.of(context)!.unexpectedErrorOccurred);
      } else {
        _showErrorDialog("Failed to delete friend. Please check your network connection.");
      }
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        String pseudo = "";
        String errorMessage = "";
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      AppLocalizations.of(context)!.addUserByPseudo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.whoWillBeYourNewFriend,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) {
                        pseudo = value;
                        if (errorMessage.isNotEmpty) {
                          setState(() => errorMessage = "");
                        }
                      },
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enterUserPseudo,
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      ),
                    ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _sendFriendRequest(pseudo, (msg) => setState(() => errorMessage = msg)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                      ),
                      child: Text(AppLocalizations.of(context)!.sendFriendRequest, style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _sendFriendRequest(String pseudo, Function(String) onError) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().post(
        '$apiPath/friends/request',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
        data: {
          'userId': userId,
          'userPseudo': pseudo,
        },
      );

      if (response.statusCode == 200) {
        try {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'token');

          await dotenv.load();
          final apiPath = dotenv.env['API_PATH']!;

          final response = await Dio().get(
            '$apiPath/users/pseudo/$pseudo',
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
          );
          final user = response.data;
          final fcmToken = user['fcm_token'];
          final accessToken = await messagingService.generateAccessToken();

          await Dio().post(
            'https://fcm.googleapis.com/v1/projects/unity-hub-446a0/messages:send',
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
            ),
            data: {
              'message': {
                'token': fcmToken,
                'notification': {
                  'title': AppLocalizations.of(context)!.friendRequest,
                  'body': "${AppLocalizations.of(context)!.youReceivedFriendRequest} ${decodedToken['pseudo']}",
                },
              },
            },
          );
        } catch (e) {
          print('Failed to get user by pseudo: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? "Friend request sent successfully!"))
        );
        Navigator.of(context).pop();
        setState(() {
          _sentRequests.add({
            'UserPseudo': pseudo,
            'Status': 'pending',
            'ID': response.data['friend']['ID'],
            'FriendID': response.data['friend']['UserID2'],
            'Profile': response.data['friend']['User2']['Profile'],
          });
        });
        _getFriends();
      } else {
        onError(response.data['message'] ?? "An error occurred");
      }
    } on DioError catch (e) {
      if (e.response != null) {
        onError(e.response!.data['message'] ?? "An unexpected error occurred");
      } else {
        onError("Failed to send request. Please check your network connection.");
      }
    }
  }

  void _showCancelFriendRequestDialog(Map request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.cancelFriendRequest),
          content: Text('${AppLocalizations.of(context)!.cancelFriendRequestConfirmation + request['UserPseudo']}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelFriendRequest(request['ID'].toString());
              },
              child: Text(AppLocalizations.of(context)!.cancelFriendRequest),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.back),
            ),
          ],
        );
      },
    );
  }

  Widget buildSentRequestsTab() {
    return _sentRequests.isEmpty
        ? Center(child: Text(AppLocalizations.of(context)!.noFriendRequestsSent, style: const TextStyle(fontSize: 16)))
        : ListView.builder(
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        var request = _sentRequests[index];
        return ListTile(
          leading: CircleAvatar(
            child: request['Profile'] != null && request['Profile'].contains('<svg')
                ? SvgPicture.string(
              request['Profile'],
              height: 40,
              width: 40,
            )
                : CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(request['Profile']),
            ),
          ),
          title: Text(request['UserPseudo']),
          subtitle: Text(AppLocalizations.of(context)!.friendRequestSent),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => _showCancelFriendRequestDialog(request),
          ),
        );
      },
    );
  }

  Widget buildFriendPageContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchFriends,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
        ),
        if (_showLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          Container(
            height: 120,
            child: _pendingRequests.isEmpty
                ? Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppLocalizations.of(context)!.noFriendRequests,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) => _buildPendingRequestCard(_pendingRequests[index]),
            ),
          ),
        Expanded(
          child: _friends.isEmpty
              ? Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppLocalizations.of(context)!.noFriendsYet,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          )
              : ListView.builder(
            itemCount: _filteredFriends.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    child: _filteredFriends[index]['Profile'] != null && _filteredFriends[index]['Profile'].contains('<svg')
                        ? SvgPicture.string(
                      _filteredFriends[index]['Profile'],
                      height: 40,
                      width: 40,
                    )
                        : CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_filteredFriends[index]['Profile']),
                    ),
                  ),
                  title: Text(
                    _filteredFriends[index]['UserPseudo'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(AppLocalizations.of(context)!.accept),
                  onTap: () => _showBottomModal(_filteredFriends[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.friends, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple[300],
          elevation: 0,
          actions: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: TextButton.icon(
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  AppLocalizations.of(context)!.addFriends,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: _showAddFriendDialog,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group, color: Colors.white)),
              Tab(icon: Icon(Icons.send, color: Colors.white)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildFriendPageContent(),
            buildSentRequestsTab(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
