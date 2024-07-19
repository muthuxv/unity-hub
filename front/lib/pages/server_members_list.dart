import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServerMembersList extends StatefulWidget {
  final String serverId;
  final String serverCreatorId;
  final Function(String) getPermissionPower;
  final String userRole;

  const ServerMembersList({super.key, required this.serverId, required this.serverCreatorId, required this.getPermissionPower, required this.userRole});

  @override
  State<ServerMembersList> createState() => _ServerMembersListState();
}

class _ServerMembersListState extends State<ServerMembersList> {
  String currentUserId = '';
  bool _isLoading = false;
  List _serverMembers = [];

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
    _fetchServerMembers();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _initializeCurrentUser() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token != null) {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      setState(() {
        currentUserId = decodedToken['jti'];
      });
    }
  }

  Future<void> _fetchServerMembers() async {
    setState(() {
      _isLoading = true;
    });

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await _dio.get('$apiPath/servers/${widget.serverId}/members',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _serverMembers = response.data['data'];
        });
      } else {
        _showErrorDialog('An error occurred while fetching server members.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showBottomModal(Map member) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        bool isCurrentUser = member['id'] == currentUserId;
        bool isServerCreator = member['id'] == widget.serverCreatorId;
        bool isAdmin = member['role'] == 'admin';

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
                child: Row(
                  children: [
                    Text(
                      member['pseudo'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (isServerCreator)
                      const Icon(Icons.star, color: Colors.amber),
                    if (isCurrentUser)
                      const Text(" (moi)", style: TextStyle(color: Colors.grey)),
                    if (isAdmin)
                      const Icon(Icons.shield, color: Colors.blue),
                  ],
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
                      widget.getPermissionPower('banUser') > 0 && !isCurrentUser ?
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: Text(AppLocalizations.of(context)!.banMember),
                          onTap: () {
                            Navigator.pop(context);
                            _showBanConfirmationDialog(member);
                          },
                        ) : const SizedBox.shrink(),
                      widget.getPermissionPower('kickUser') > 0 && !isCurrentUser ?
                        ListTile(
                          leading: const Icon(Icons.remove_circle),
                          title: Text(AppLocalizations.of(context)!.kickMember),
                          onTap: () {
                            Navigator.pop(context);
                            _kickMember(member);
                          },
                        ) : const SizedBox.shrink(),
                      widget.userRole == 'admin' && !isServerCreator ?
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text("Modifier le rôle"),
                          onTap: () {
                            Navigator.pop(context);
                            _showUpdateMemberRoleDialog(member);
                          },
                        ) : const SizedBox.shrink(),
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

  void _showBanConfirmationDialog(Map member) {
    String banReason = '';
    String banDuration = '7';
    bool reasonEmpty = false;
    bool durationEmpty = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.banMemberConfirmation),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.warning, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.banMemberConfirmation,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.reason,
                      prefixIcon: const Icon(Icons.info_outline),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: reasonEmpty ? Colors.red : Colors.blue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: reasonEmpty ? Colors.red : Colors.grey),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        banReason = value;
                        reasonEmpty = value.isEmpty;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.duration,
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: durationEmpty ? Colors.red : Colors.blue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: durationEmpty ? Colors.red : Colors.grey),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: '7',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onChanged: (value) {
                      setState(() {
                        banDuration = value;
                        durationEmpty = value.isEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    if (banReason.isEmpty || banDuration.isEmpty) {
                      _showErrorDialog(AppLocalizations.of(context)!.fillAllFields);
                      setState(() {
                        reasonEmpty = banReason.isEmpty;
                        durationEmpty = banDuration.isEmpty;
                      });
                    } else {
                      Navigator.of(context).pop();
                      _banMember(member, banReason, int.tryParse(banDuration) ?? 7);
                    }
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
      },
    );
  }

  Future<void> _showUpdateMemberRoleDialog(Map member) async {
    // Get server roles
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final rolesResponse = await Dio().get(
        '$apiPath/roles/server/${widget.serverId}',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (rolesResponse.statusCode == 200) {
        final List roles = rolesResponse.data;
        await _showUserRoleDialog(member, roles, token!, apiPath);
      } else {
        _showErrorDialog("Failed to load roles.");
      }
    } catch (e) {
      _showErrorDialog('An error occurred while fetching roles: $e');
    }
  }

  Future<void> _showUserRoleDialog(Map member, List roles, String token, String apiPath) async {
    try {
      final userRoleResponse = await Dio().get(
        '$apiPath/user/${member['id']}/servers/${widget.serverId}/roles',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (userRoleResponse.statusCode == 200) {
        final userRole = userRoleResponse.data;
        String selectedRole = userRole['id'];

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.update, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Modification rôle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                      SizedBox(height: 16),
                      Text(
                        "Voulez-vous vraiment modifier le rôle de ${member['pseudo']} ?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        items: roles.map<DropdownMenuItem<String>>((role) {
                          return DropdownMenuItem<String>(
                            value: role['ID'],
                            child: Text(role['Label']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateMemberRole(member, selectedRole);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text("Oui"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text("Non"),
                    ),
                  ],
                );
              },
            );
          },
        );
      } else {
        _showErrorDialog("Failed to load user role.");
      }
    } catch (e) {
      _showErrorDialog('An error occurred while fetching user role: $e');
    }
  }


  void _updateMemberRole(Map member, String roleId) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().post(
        '$apiPath/server/${widget.serverId}/setRole/$roleId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          'user-id': member['id'],
        },
      );

      if (response.statusCode == 200) {
        _showSuccessDialog("Member role updated successfully");
        _fetchServerMembers();
      } else {
        _showErrorDialog("Failed to update member role");
      }
    } catch (e) {
      _showErrorDialog('An error occurred while updating member role: $e');
    }
  }

  void _banMember(Map member, String reason, int duration) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      _showErrorDialog('User token not found');
      return;
    }

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final Dio dio = Dio();

    try {
      final response = await dio.post(
        '$apiPath/servers/${widget.serverId}/ban/users/${member['id']}',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
        data: {
          'reason': reason,
          'duration': duration,
        },
      );

      if (response.statusCode == 200) {
        _showSuccessDialog(AppLocalizations.of(context)!.memberBannedSuccessfully);
        _fetchServerMembers();
      } else {
        _showErrorDialog(AppLocalizations.of(context)!.failedBanMember);
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _kickMember(Map member) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      _showErrorDialog('User token not found');
      return;
    }

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await _dio.delete(
        '$apiPath/servers/${widget.serverId}/kick/users/${member['id']}',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog(AppLocalizations.of(context)!.memberKickedSuccessfully);
        _fetchServerMembers();
      } else {
        _showErrorDialog(AppLocalizations.of(context)!.failedKickMember);
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.success),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.server_members),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: _serverMembers.length,
        itemBuilder: (context, index) {
          final member = _serverMembers[index];
          bool isServerCreator = member['id'] == widget.serverCreatorId;
          bool isCurrentUser = member['id'] == currentUserId;
          bool isAdmin = member['role'] == 'admin';
          return GestureDetector(
            onTap: () {
              if (!isServerCreator) {
                _showBottomModal(member);
              }
            },
            child: ListTile(
              title: Row(
                children: [
                  Text(member['pseudo']),
                  if (isServerCreator)
                    const Icon(Icons.star, color: Colors.amber),
                  if (isCurrentUser)
                    const Text(" (moi)", style: TextStyle(color: Colors.grey)),
                  if (isAdmin) const Icon(Icons.shield, color: Colors.blue),
                ],
              ),
              leading: CircleAvatar(
                child: member['profile'] != null && member['profile'].contains('<svg')
                    ? SvgPicture.string(
                  member['profile'],
                  height: 40,
                  width: 40,
                )
                    : CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(member['profile']),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
