import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:unity_hub/pages/roles/role_form_page.dart';
import 'package:unity_hub/pages/roles/role_update_form_page.dart';

class RolePage extends StatefulWidget {
  final int serverId;

  const RolePage({super.key, required this.serverId});

  @override
  _RolePageState createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  List _roles = [];
  bool _isLoading = true;
  Map _connectedUser = {};
  String? token;

  @override
  void initState() {
    super.initState();
    _getRoles();
    _getUsers();
  }

  void _getRoles() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await Dio().get(
        'http://10.0.2.2:8080/roles/server/${widget.serverId}',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _roles = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load roles'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while fetching roles'),
        ),
      );
    }
  }

  void _getUsers() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    try {
      final response = await Dio().get(
        'http://10.0.2.2:8080/users/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _connectedUser = response.data;
        });
        // Log the connected user data to the console
        print(_connectedUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load user data'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while fetching user data'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Les rôles du serveur',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      return ListTile(
                        title: Text(role['Label']),
                        tileColor: Colors.purple.shade50,
                        trailing: _connectedUser['Role'] == 'admin'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RoleUpdatePageForm(roleId: role['ID'], roleLabel: role['Label']),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      final response = await Dio().delete(
                                        'http://10.0.2.2:8080/roles/${role['ID']}',
                                        options: Options(
                                          headers: {
                                            'Content-Type': 'application/json',
                                            'Authorization': 'Bearer $token',
                                          },
                                        ),
                                      );
                                      if (response.statusCode == 204) {
                                        _getRoles();
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Failed to delete role'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Divider(
                        color: Colors.deepPurple,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 16.0),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RolePageForm(serverId: widget.serverId),
                        ),
                      );
                    },
                    child: const Text(
                      'Créer un rôle',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
