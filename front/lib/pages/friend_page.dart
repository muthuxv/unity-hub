import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class FriendPage extends StatefulWidget {
  const FriendPage({Key? key}) : super(key: key);

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
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

    final response = await Dio().get(
      'http://10.0.2.2:8080/friends/sent/$userId',
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

    final response = await Dio().get(
      'http://10.0.2.2:8080/friends/pending/$userId',
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

    final response = await Dio().post(
      'http://10.0.2.2:8080/friends/accept',
      data: {
        'ID': int.tryParse(friendId),
        'UserID2': int.tryParse(userId),
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
          'FriendID': response.data['FriendID'],
          'Status': response.data['Status'],
          'UserPseudo': response.data['UserPseudo'],
          'Email': response.data['UserMail']
        };

        _pendingRequests.removeWhere((item) => item['FriendID'].toString() == friendId);
        if (!_friends.any((friend) => friend['FriendID'] == newFriend['FriendID'])) {
          _friends.add(newFriend);
        }

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Demande d'ami acceptée avec succès"))
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
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    final response = await Dio().post(
      'http://10.0.2.2:8080/friends/refuse',
      data: {
        'ID': int.tryParse(friendId),
        'UserID2': int.tryParse(userId),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Demande refusée avec succès')));
    } else {
      _showErrorDialog('Failed to refuse friend request: ${response.data['message']}');
    }
  }

  void _cancelFriendRequest(String friendId) async {
    print("Attempting to cancel friend request with ID: $friendId");
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    try {
      final response = await Dio().delete(
        'http://10.0.2.2:8080/friends/$friendId',
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
          _sentRequests.removeWhere((item) => item['FriendID'].toString() == friendId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Demande d'ami annulée avec succès")),
        );
      } else {
        _showErrorDialog(response.data['message'] ?? "Erreur lors de l'annulation de la demande d'ami");
      }
    } on DioError catch (e) {
      if (e.response != null) {
        _showErrorDialog(e.response!.data['message'] ?? "Une erreur inattendue s'est produite");
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
        height: 80,  // Hauteur fixe pour la carte
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.lightBlue[50],  // Couleur de fond claire
          border: Border.all(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 60,  // Largeur de l'avatar
              height: 60,  // Hauteur de l'avatar
              decoration: BoxDecoration(
                color: Colors.blueGrey,  // Couleur de fond de l'avatar
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text(
                request['UserPseudo'][0].toUpperCase(),  // Première lettre du pseudo
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    request['UserPseudo'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    request['Status'],
                    style: TextStyle(fontSize: 16),
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
    print(request);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Voulez-vous devenir ami avec ${request['UserPseudo']} ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _acceptFriendRequest(request['FriendID'].toString());
                Navigator.of(context).pop();
              },
              child: Text('Accepter'),
            ),
            TextButton(
              onPressed: () {
                _refuseFriendRequest(request['FriendID'].toString());
                Navigator.of(context).pop();
              },
              child: Text('Refuser'),
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
        title: const Text('Erreur'),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height / 2,
          decoration: BoxDecoration(
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
                  friend['UserPseudo'], // Assurez-vous que la clé est correcte
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // Vous pouvez ajuster cette couleur
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.account_circle),
                        title: Text('Profil'),
                        onTap: () {
                          Navigator.pop(context);
                          // Naviguer au profil de l'ami
                        },
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 50), // Ajustez selon le design souhaité
                        child: Divider(color: Colors.grey[400], thickness: 1),
                      ),
                      ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Supprimer'),
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteConfirmationDialog(friend); // Afficher la boîte de dialogue de confirmation
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

  void _showDeleteConfirmationDialog(Map friend) {
    print(friend);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Êtes-vous sûr de supprimer cet ami ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue de confirmation
                _deleteFriend(friend); // Supprimer l'ami
              },
              child: Text('Oui'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue de confirmation
              },
              child: Text('Non'),
            ),
          ],
        );
      },
    );
  }

  void _deleteFriend(Map friend) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await Dio().delete(
        'http://10.0.2.2:8080/friends/${friend['FriendID']}',
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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ami supprimé avec succès")),
        );
      } else {
        _showErrorDialog(response.data['message'] ?? "Erreur lors de la suppression de l'ami");
      }
    } on DioError catch (e) {
      if (e.response != null) {
        _showErrorDialog(e.response!.data['message'] ?? "Une erreur inattendue s'est produite");
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
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "Ajouter par pseudo d'utilisateur",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Qui sera ton nouvel ami ?",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      onChanged: (value) {
                        pseudo = value;
                        if (errorMessage.isNotEmpty) {
                          setState(() => errorMessage = "");
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Entrez un pseudo d'utilisateur",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      ),
                    ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _sendFriendRequest(pseudo, (msg) => setState(() => errorMessage = msg)),
                      child: Text("Envoyer une demande d'ami", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                      ),
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

    try {
      final response = await Dio().post(
        'http://10.0.2.2:8080/friends/request',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
        data: {
          'userId': int.tryParse(userId),
          'userPseudo': pseudo,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? "Friend request sent successfully!"))
        );
        Navigator.of(context).pop();
        setState(() {
          _sentRequests.add({
            'UserPseudo': pseudo,
            'Status': 'pending',
            'ID': response.data['friend']['UserID2'],
            'FriendID': response.data['friend']['ID'],
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
          title: Text('Annuler la demande d\'ami'),
          content: Text('Voulez-vous annuler la demande d\'ami à ${request['UserPseudo']} ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelFriendRequest(request['FriendID'].toString());
              },
              child: Text('Annuler la demande d\'ami'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Retour'),
            ),
          ],
        );
      },
    );
  }

  Widget buildSentRequestsTab() {
    return _sentRequests.isEmpty
        ? Center(child: Text("Tu n'as pas encore fait de demande", style: TextStyle(fontSize: 16)))
        : ListView.builder(
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        var request = _sentRequests[index];
        return ListTile(
          leading: Icon(Icons.person),
          title: Text(request['UserPseudo']),
          subtitle: Text("Demande envoyée"),
          trailing: IconButton(
            icon: Icon(Icons.arrow_forward),
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
              hintText: 'Rechercher des amis...',
              prefixIcon: Icon(Icons.search),
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
          Expanded(
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
                  "Pas de demande d'ami",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
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
                "Pas encore d'ami 😭",
                style: TextStyle(fontSize: 16, color: Colors.black54),
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
                    backgroundColor: Colors.blueGrey,
                    child: Text(_filteredFriends[index]['UserPseudo'][0].toUpperCase()),
                  ),
                  title: Text(
                    _filteredFriends[index]['UserPseudo'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_filteredFriends[index]['Status']),
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
      length: 2, // Total number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Amis', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple[300],
          elevation: 0,
          actions: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: TextButton.icon(
                icon: Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  'Ajouter des amis',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _showAddFriendDialog,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group, color: Colors.white)),
              Tab(icon: Icon(Icons.send, color: Colors.white)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildFriendPageContent(), // Existing friends page content
            buildSentRequestsTab(), // Placeholder for second tab
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
