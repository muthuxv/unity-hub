import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unity_hub/pages/roles/role_page.dart';
import 'package:unity_hub/pages/server_logs_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'server_update_tags_page.dart';

class ServerSettingsPage extends StatefulWidget {
  final int serverId;
  final String serverName;
  String serverAvatar;
  final String serverVisibility;
  ServerSettingsPage({super.key, required this.serverId, required this.serverName, required this.serverAvatar, required this.serverVisibility});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {

  void _showInvitationDialog(BuildContext context, int serverId) {
    final url = 'http://10.0.2.2:8080/servers/$serverId/join';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lien d\'invitation'),
          content: Text(url),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lien copié dans le presse-papiers'),
                  ),
                );
              },
              child: const Text('Copier le lien'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
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
          title: const Text('Paramètres du serveur',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
              )
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
                        onTap: () async {
                          final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final formData = FormData.fromMap({
                              'file': await MultipartFile.fromFile(
                                image.path,
                                contentType: MediaType('image', image.path.split('.').last),
                              ),
                            });

                            try {
                              final storage = FlutterSecureStorage();
                              final token = await storage.read(key: 'token');

                              final response = await Dio().post(
                                'http://10.0.2.2:8080/upload',
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
                                  'http://10.0.2.2:8080/servers/${widget.serverId}',
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
                                        title: const Text('Erreur'),
                                        content: const Text('Une erreur s\'est produite lors de la mise à jour de l\'avatar.'),
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
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Erreur'),
                                      content: const Text('Une erreur s\'est produite lors de la mise à jour de l\'avatar.'),
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
                            } catch (e) {
                              print('Error: $e');
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Erreur'),
                                    content: const Text('Une erreur s\'est produite lors de la mise à jour de l\'avatar.'),
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
                          }
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundImage: Image.network(
                                'http://10.0.2.2:8080/uploads/${widget.serverAvatar}?rand=${DateTime.now().millisecondsSinceEpoch}',
                                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                  return Image.asset('assets/images/air-force.png');
                                },
                              ).image,
                            ),
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                        leading: Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                        title: Text(
                          'Rôles',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RolePage(serverId: widget.serverId),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServerLogsPage(serverId: widget.serverId),
                            ),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                        leading: Icon(Icons.description_outlined, color: Colors.white),
                        title: Text(
                          'Logs du serveur',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        onTap: () {
                          _showInvitationDialog(context, widget.serverId);
                        },
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                        leading: Icon(Icons.email_outlined, color: Colors.white),
                        title: Text(
                          'Invitations',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                        leading: Icon(Icons.block, color: Colors.white),
                        title: Text(
                          'Bannissements',
                          style: TextStyle(
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
                              builder: (context) => ServerUpdateTagsPage(serverId: widget.serverId),
                            ),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                        leading: Icon(Icons.label, color: Colors.white),
                        title: Text(
                          'Tags',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Supprimer le serveur'),
                          content: const Text('Êtes-vous sûr de vouloir supprimer ce serveur ?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  final storage = FlutterSecureStorage();
                                  final token = await storage.read(key: 'token');

                                  final response = await Dio().delete(
                                      'http://10.0.2.2:8080/servers/${widget.serverId}',
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
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Erreur'),
                                          content: const Text('Une erreur s\'est produite lors de la suppression du serveur.'),
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
                                } catch (e) {
                                  print('Error: $e');
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Erreur'),
                                        content: const Text('Une erreur s\'est produite lors de la suppression du serveur.'),
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
                              },
                              child: const Text('Supprimer'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.redAccent),
                      title: Text(
                        'Supprimer le serveur',
                        style: TextStyle(
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
