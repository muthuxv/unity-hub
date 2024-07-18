import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unity_hub/pages/voice_room.dart';
import '../pages/channel_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:unity_hub/utils/input_formatter.dart';

class ChannelsPanel extends StatefulWidget {
  final String serverId;
  static final GlobalKey<_ChannelsPanelState> globalKey = GlobalKey<_ChannelsPanelState>();
  final Function(String) getPermissionPower;

  const ChannelsPanel({super.key, required this.serverId, required this.getPermissionPower});

  @override
  State<ChannelsPanel> createState() => _ChannelsPanelState();
}

class _ChannelsPanelState extends State<ChannelsPanel> {
  bool _isLoading = false;
  List<dynamic> _textChannels = [];
  List<dynamic> _vocalChannels = [];
  final Map<String, int> _permissions = {};

  Future<void> _fetchChannels() async {
    setState(() {
      _isLoading = true;
    });

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await Dio().get('$apiPath/servers/${widget.serverId}/channels',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ));

      if (response.statusCode == 200) {
        setState(() {
          _textChannels = response.data['text'];
          _vocalChannels = response.data['vocal'];
        });
      }
    } catch (error) {
      print('Error fetching channels: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateChannel(String channelId, String channelName) async {
    if (channelName.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.channel_creation_error_title),
            content: Text(AppLocalizations.of(context)!.channel_creation_error_message),
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
      return;
    }
    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      await Dio().put(
        '$apiPath/channels/$channelId',
        data: {
          'name': channelName,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      _fetchChannels();
    } catch (error) {
      print('Error updating channel: $error');
    }
  }

  Future<void> _updateChannelPermissions(String channelId, Map<String, int> permissions) async {
    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      await Dio().put(
        '$apiPath/channels/$channelId/permissions',
        data: permissions,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          }
        ),
      );
    } catch (error) {
      print('Error updating channel permissions: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchChannels();
  }

  @override
  void didUpdateWidget(ChannelsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverId != widget.serverId) {
      _fetchChannels();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.text_channels_section),
        for (final channel in _textChannels)
          GestureDetector(
            child: ListTile(
              trailing: const Icon(Icons.arrow_forward_ios),
              title: Text(channel['Name']),
              onTap: () {
                _checkAndNavigate(channel['ID'], channel['Name']);
              },
              onLongPress: () {
                _checkAndShowEditDialog(channel['ID'], channel['Name'], showPermissionDeniedDialog: false);
              },
            ),
          ),
        Text(AppLocalizations.of(context)!.voice_channels_section),
        for (final channel in _vocalChannels)
          ListTile(
            title: Text(channel['Name']),
            onTap: () {
              _checkAndNavigate(channel['ID'], channel['Name'], isVocal: true);
            },
            onLongPress: () {
              _checkAndShowEditDialog(channel['ID'], channel['Name'], showPermissionDeniedDialog: false);
            },
          ),
      ],
    );
  }

  Future<void> _checkAndNavigate(String channelId, String channelName, {bool isVocal = false}) async {
    await _fetchChannelPermissions(channelId);
    if (widget.getPermissionPower('accessChannel') >= _permissions['accessChannel']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isVocal
              ? VoiceRoom(
            channelId: channelId,
            channelName: channelName,
          )
              : ChannelPage(
            channelId: channelId,
            channelName: channelName,
            serverId: widget.serverId,
            canSendMessage: widget.getPermissionPower('sendMessage') >= _permissions['sendMessage'],
          ),
        ),
      );
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _checkAndShowEditDialog(String channelId, String channelName, {bool showPermissionDeniedDialog = true}) async {
    await _fetchChannelPermissions(channelId);
    if (widget.getPermissionPower('editChannel') >= _permissions['editChannel']) {
      _showEditDialog(channelId, channelName);
    } else if (showPermissionDeniedDialog) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Accès refusé"),
          content: Text("Vous n'avez pas la permission d'accéder à ce salon."),
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

  void _showEditDialog(String channelId, String channelName) {
    TextEditingController channelNameController = TextEditingController(text: channelName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.edit_channel_title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: channelNameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.edit_channel_name_label,
                  ),
                ),
                const SizedBox(height: 8),
                _channelPermissions(channelId),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final response = await Dio().delete(
                    '${dotenv.env['API_PATH']}/channels/$channelId',
                  );

                  if (response.statusCode == 204) {
                    Navigator.pop(context);
                    _fetchChannels();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(AppLocalizations.of(context)!.delete_channel_error_title),
                          content: Text(AppLocalizations.of(context)!.delete_channel_error_message),
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
                } catch (error) {
                  print('Error deleting channel: $error');
                }
              },
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _updateChannel(channelId, channelNameController.text);
                _updateChannelPermissions(channelId, _permissions);
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }


  Widget _channelPermissions(String channelId) {
    return FutureBuilder(
      future: _fetchChannelPermissions(channelId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(
            child: Text('Aucune permission trouvée'),
          );
        }

        final permissions = snapshot.data as List;

        return Column(
          children: [
            for (final permission in permissions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(permission['label']),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: TextEditingController(text: permission['power'].toString()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        NumberRangeTextInputFormatter(min: 0, max: 99),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _permissions[permission['label']] = int.parse(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Future<List> _fetchChannelPermissions(String channelId) async {
    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await Dio().get('$apiPath/channels/$channelId/permissions',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ));

      if (response.statusCode == 200) {
        final permissions = response.data as List;
        setState(() {
          for (final permission in permissions) {
            _permissions[permission['label']] = permission['power'];
          }
        });
        return permissions;
      } else {
        throw Exception('Failed to load permissions');
      }
    } catch (error) {
      print('Error fetching channel permissions: $error');
      throw error;
    }
  }

  void onChannelAdded(Response<dynamic> response) {
    setState(() {
      if (response.data['Type'] == 'text') {
        _textChannels.add(response.data);
      } else {
        _vocalChannels.add(response.data);
      }
    });
  }
}
