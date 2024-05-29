import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unity_hub/pages/role_form_page.dart';

class RolePage extends StatefulWidget {
  final int serverId;

  const RolePage({super.key, required this.serverId});

  @override
  _RolePageState createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  List _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getRoles();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Server Roles',
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
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RolePageForm(serverId: widget.serverId),
                  ),
                );
              },
              child: const Text(
                'Créer un rôle',
                style: TextStyle(color: Colors.white),
              ),            ),
          ),
        ],
      ),
    );
  }
}
