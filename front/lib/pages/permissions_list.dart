import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class PermissionsPage extends StatefulWidget {
  final String roleId;
  const PermissionsPage({super.key, required this.roleId});

  @override
  _PermissionsPageState createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  List permissions = [];
  bool _isLoading = true;

  void _getPermissions() async {
    const storage = FlutterSecureStorage();
    final token = await(storage.read(key: 'token'));

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/permissions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          permissions = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }



  @override
  void initState() {
    super.initState();
    _getPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions'),
      ),
      body: permissions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: permissions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(permissions[index].name),
            trailing: Switch(
              value: permissions[index].isEnabled,
              onChanged: (bool value) {
                // Mettre à jour l'état de la permission (local ou via API)
                setState(() {
                  permissions[index].isEnabled = value;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
