import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:unity_hub/pages/reports/reports_page.dart';
import 'package:unity_hub/pages/roles/role_page.dart';
import 'package:unity_hub/pages/server_logs_page.dart';
import 'package:unity_hub/pages/server_ban_members_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'server_update_tags_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'security/auth_page.dart';

Future<String?> getCurrentUserId() async {
  try {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token != null) {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final currentUserId = decodedToken['jti'];
      return currentUserId;
    } else {
      print('Token not found');
      return null;
    }
  } catch (e) {
    print('Error decoding token: $e');
    return null;
  }
}

class ServerSettingsPage extends StatefulWidget {
  final String serverId;
  final String serverName;
  String serverAvatar;
  final String serverVisibility;
  final String servercreatorUserId;
  ServerSettingsPage({
    super.key,
    required this.serverId,
    required this.serverName,
    required this.serverAvatar,
    required this.serverVisibility,
    required this.servercreatorUserId,
  });

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    getCurrentUserId().then((userId) {
      setState(() {
        currentUserId = userId;
      });
    });
  }

  bool get showForCreator {
    return currentUserId == widget.servercreatorUserId;
  }

  void _showInvitationDialog(BuildContext context, String serverId) {
    final url = 'https://unityhub.fr/servers/$serverId/join';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.invitation_link),
          content: Text(url),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.link_copied),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.copy_link),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
  }

  void _deleteServer(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.delete_server),
          content: Text(AppLocalizations.of(context)!.delete_server_confirmation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            if (showForCreator)
              TextButton(
                onPressed: () async {
                  try {
                    final storage = FlutterSecureStorage();
                    final token = await storage.read(key: 'token');

                    final response = await Dio().delete(
                      'https://unityhub.fr/servers/${widget.serverId}',
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
                      Navigator.pop(context); // Ferme la boîte de dialogue
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthPage()));
                    } else if (response.statusCode == 403) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!.error),
                            content: Text(AppLocalizations.of(context)!.onlyServerCreatorCanDeleteServer),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(AppLocalizations.of(context)!.ok),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!.error),
                            content: Text(AppLocalizations.of(context)!.server_deletion_error),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(AppLocalizations.of(context)!.ok),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } catch (e) {
                    print('Error: $e');
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(AppLocalizations.of(context)!.error),
                          content: Text(AppLocalizations.of(context)!.server_deletion_error),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.ok),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.delete),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          leading: IconButton(
            iconSize: 30,
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pop(
                context,
                {
                  'avatar': widget.serverAvatar,
                },
              );
            },
          ),
          title: Text(
            AppLocalizations.of(context)!.server_settings,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff4776e6), Color(0xff8e54e9)],
              stops: [0, 1],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Container(
            margin: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: showForCreator ? () async {
                          final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final formData = FormData.fromMap({
                              'file': await MultipartFile.fromFile(
                                image.path,
                                contentType: MediaType('image', image.path.split('.').last),
                              ),
                            });

                            try {
                              const storage = FlutterSecureStorage();
                              final token = await storage.read(key: 'token');

                              final response = await Dio().post(
                                'https://unityhub.fr/upload',
                                data: formData,
                                options: Options(
                                  headers: {
                                    'Authorization': 'Bearer $token',
                                  },
                                ),
                              );
                              if (response.statusCode == 200) {
                                print('Uploaded: ${response.data['id']}');
                                final serverUpdateResponse = await Dio().put(
                                  'https://unityhub.fr/servers/${widget.serverId}',
                                  data: {
                                    'MediaID': response.data['id'],
                                  },
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
                                if (serverUpdateResponse.statusCode == 200) {
                                  setState(() {
                                    widget.serverAvatar = response.data['path'].split('upload/').last;
                                  });
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(AppLocalizations.of(context)!.error),
                                        content: Text(AppLocalizations.of(context)!.avatar_update_error),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(AppLocalizations.of(context)!.ok),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(AppLocalizations.of(context)!.error),
                                      content: Text(AppLocalizations.of(context)!.avatar_update_error),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(AppLocalizations.of(context)!.ok),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            } catch (e) {
                              print('Error: $e');
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.error),
                                    content: Text(AppLocalizations.of(context)!.avatar_update_error),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(AppLocalizations.of(context)!.ok),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          }
                        } : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundImage: Image.network(
                                'https://unityhub.fr/uploads/${widget.serverAvatar}?rand=${DateTime.now().millisecondsSinceEpoch}',
                                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                  return Image.asset('assets/images/air-force.png');
                                },
                              ).image,
                            ),
                            if (showForCreator)
                              Positioned(
                                bottom: 1,
                                right: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 3,
                                        color: Colors.white,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(
                                          50,
                                        ),
                                      ),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          offset: const Offset(2, 4),
                                          color: Colors.black.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 3,
                                        ),
                                      ]),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(Icons.add_a_photo, color: Colors.black),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.serverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w100,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                        title: Text(
                          AppLocalizations.of(context)!.roles,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RolePage(serverId: widget.serverId, servercreatorUserId: widget.servercreatorUserId),
                            ),
                          );
                        },
                      ),
                      if (showForCreator)
                        ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServerLogsPage(serverId: widget.serverId),
                              ),
                            );
                          },
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          leading: const Icon(Icons.description_outlined, color: Colors.white),
                          title: Text(
                            AppLocalizations.of(context)!.server_logs,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ListTile(
                        onTap: () {
                          _showInvitationDialog(context, widget.serverId);
                        },
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        leading: const Icon(Icons.email_outlined, color: Colors.white),
                        title: Text(
                          AppLocalizations.of(context)!.invitations,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (showForCreator)
                        ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServerBanMembersPage(serverId: widget.serverId),
                              ),
                            );
                          },
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          leading: const Icon(Icons.block, color: Colors.white),
                          title: Text(
                            AppLocalizations.of(context)!.bans,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportsPage(serverID: widget.serverId),
                              ),
                            );
                          },
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          leading: const Icon(Icons.warning, color: Colors.white),
                          title: Text(
                            AppLocalizations.of(context)!.reports,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (widget.serverVisibility == 'public')
                        ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServerUpdateTagsPage(serverId: widget.serverId, servercreatorUserId: widget.servercreatorUserId),
                              ),
                            );
                          },
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          leading: const Icon(Icons.label, color: Colors.white),
                          title: Text(
                            AppLocalizations.of(context)!.tags,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (showForCreator)
                  GestureDetector(
                    onTap: () {
                      _deleteServer(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        title: Text(
                          AppLocalizations.of(context)!.delete_server,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
