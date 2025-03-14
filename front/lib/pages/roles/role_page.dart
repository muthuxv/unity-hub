import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:unity_hub/pages/permissions_list.dart';
import 'role_form_page.dart';
import 'role_update_form_page.dart';

class RolePage extends StatefulWidget {
  final String serverId;
  final String servercreatorUserId;

  const RolePage({
    super.key,
    required this.serverId,
    required this.servercreatorUserId,
  });

  @override
  _RolePageState createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  List _roles = [];
  bool _isLoading = true;
  Map _connectedUser = {};
  String? token;
  bool isEnabled = false;

  @override
  void initState() {
    super.initState();
    _getRoles();
    _getUsers();
  }

  void _getRoles() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/roles/server/${widget.serverId}',
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedLoadRoles),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorFetchingRoles),
        ),
      );
    }
  }

  void _getUsers() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/users/$userId',
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
          isEnabled = _connectedUser['ID'] == widget.servercreatorUserId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedLoadUserData),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorFetchingUserData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.serverRoles,
          style: const TextStyle(color: Colors.white),
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
                final roleId = role['ID'];
                final roleLabel = role['Label'];
                final isBaseRole = roleLabel.toLowerCase() == 'membre';
                final isAdminRole = roleLabel.toLowerCase() == 'admin';

                return ListTile(
                  title: Text(roleLabel),
                  tileColor: Colors.purple.shade50,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      !isAdminRole && isEnabled ? IconButton(
                        icon: const Icon(Icons.admin_panel_settings),
                        onPressed: (
                            () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PermissionsPage(
                                roleId: roleId,
                              ),
                            ),
                          );
                          if (result != null && result) {
                            _getRoles();
                          }
                        }),
                      ) : const SizedBox(),
                      isEnabled && !isBaseRole && !isAdminRole ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoleUpdatePageForm(
                                roleId: roleId,
                                roleLabel: roleLabel,
                              ),
                            ),
                          );
                          if (result != null && result) {
                            _getRoles();
                          }
                        },
                      ) : const SizedBox(),
                      isEnabled && !isBaseRole && !isAdminRole ? IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final response = await Dio().delete(
                            '${dotenv.env['API_PATH']}/roles/$roleId',
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.failedDeleteRole,
                                ),
                              ),
                            );
                          }
                        },
                      ) : const SizedBox(),
                    ],
                  ),
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
              onPressed: isEnabled
                  ? () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RolePageForm(serverId: widget.serverId),
                  ),
                );
                if (result != null && result) {
                  _getRoles();
                }
              }
                  : null,
              child: Text(
                AppLocalizations.of(context)!.createRole,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}