import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      'Permissions Gestion serveur': [],
      'Permissions Modération': [],
      'Permissions Salons': [],
    };

    for (var permission in permissions) {
      String label = permission['label'];

      if (label == 'createChannel' ||
          label == 'createRole' ||
          label == 'accessLog' ||
          label == 'profileServer') {
        categorizedPermissions['Permissions Gestion serveur']!.add(permission);
      } else if (label == 'kickUser' ||
          label == 'banUser' ||
          label == 'accessReport') {
        categorizedPermissions['Permissions Modération']!.add(permission);
      } else if (label == 'editChannel' ||
          label == 'sendMessage' ||
          label == 'accessChannel') {
        categorizedPermissions['Permissions Salons']!.add(permission);
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
            trackOutlineColor: MaterialStateColor.resolveWith((states) => Colors.red.shade100),
            value: permission['power'] == '1',
            onChanged: (value) {
              setState(() {
                permission['power'] = value ? '1' : '0';
              });
            },
          ) : SizedBox(
            width: 50,
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                NumberRangeTextInputFormatter(min: 0, max: 99),
              ],
              controller: _controllers[permission['label']],
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
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        children: permissionTiles,
      ));
    });

    return categories;
  }
}

class NumberRangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  NumberRangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else {
      final intValue = int.tryParse(newValue.text);
      if (intValue != null && intValue >= min && intValue <= max) {
        return newValue;
      }
    }
    return oldValue;
  }
}
