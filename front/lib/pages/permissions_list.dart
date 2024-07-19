import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unity_hub/utils/input_formatter.dart';

class PermissionsPage extends StatefulWidget {
  final String roleId;
  const PermissionsPage({Key? key, required this.roleId}) : super(key: key);

  @override
  _PermissionsPageState createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  List permissions = [];
  bool _isLoading = true;
  final Map<String, TextEditingController> _controllers = {};

  void _getPermissions() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/roles/${widget.roleId}/permissions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          if (response.data != null) {
            permissions = response.data;
            for (var permission in permissions) {
              _controllers[permission['label']] = TextEditingController(text: permission['power'].toString());
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _savePermissions() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    Map<String, int> updatedPermissions = {};

    for (var permission in permissions) {
      if (permission['label'] != 'sendMessage' &&
          permission['label'] != 'editChannel' &&
          permission['label'] != 'accessChannel') {
        updatedPermissions[permission['label']] = permission['power'] == '1' ? 1 : 0;
      } else {
        updatedPermissions[permission['label']] = int.parse(permission['power'].toString());
      }
    }

    try {
      final response = await Dio().put(
        '$apiPath/roles/${widget.roleId}/permissions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: updatedPermissions,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les permissions ont été mises à jour'),
            backgroundColor: Colors.green,
          ),
        );
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
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePermissions,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: _buildPermissionCategories(),
      ),
    );
  }

  List<Widget> _buildPermissionCategories() {
    List<Widget> categories = [];

    // Group permissions by categories
    Map<String, List<dynamic>> categorizedPermissions = {
      'Gestion serveur': [],
      'Modération': [],
      'Salons': [],
    };

    for (var permission in permissions) {
      String label = permission['label'];

      if (label == 'createChannel' ||
          label == 'createRole' ||
          label == 'accessLog' ||
          label == 'profileServer') {
        categorizedPermissions['Gestion serveur']!.add(permission);
      } else if (label == 'kickUser' ||
          label == 'banUser' ||
          label == 'accessReport') {
        categorizedPermissions['Modération']!.add(permission);
      } else if (label == 'editChannel' ||
          label == 'sendMessage' ||
          label == 'accessChannel') {
        categorizedPermissions['Salons']!.add(permission);
      }
    }

    // Build widgets for each category
    categorizedPermissions.forEach((category, permissionsList) {
      List<Widget> permissionTiles = [];

      for (var permission in permissionsList) {
        permissionTiles.add(ListTile(
          title: Text(permission['label']),
          trailing: (permission['label'] != 'sendMessage' &&
              permission['label'] != 'editChannel' &&
              permission['label'] != 'accessChannel') ?
          Switch(
            activeColor: Colors.deepPurple,
            activeTrackColor: Colors.deepPurple.shade100,
            inactiveThumbColor: Colors.red.shade200,
            inactiveTrackColor: Colors.red.shade100,
            trackOutlineColor: MaterialStateColor.resolveWith((states) => Colors.deepPurpleAccent),
            value: permission['power'].toString() == '1',
            onChanged: (value) {
              setState(() {
                permission['power'] = value ? '1' : '0';
              });
            },
          ) : SizedBox(
            width: 50,
            child: TextField(
              decoration: InputDecoration(
                hintText: permission['power'].toString(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                NumberRangeTextInputFormatter(min: 0, max: 99),
              ],
              controller: _controllers[permission['power']],
              onChanged: (value) {
                setState(() {
                  permission['power'] = value;
                });
              },
            ),
          ),
        ));
      }

      categories.add(ExpansionTile(
        title: Text(category, style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            fontSize: 18
        )),
        children: permissionTiles,
      ));
    });

    return categories;
  }
}