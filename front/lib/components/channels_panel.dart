import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unity_hub/pages/voice_room.dart';
import '../pages/channel_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChannelsPanel extends StatefulWidget {
  final String serverId;
  static final GlobalKey<_ChannelsPanelState> globalKey = GlobalKey<_ChannelsPanelState>();

  const ChannelsPanel({super.key, required this.serverId});

  @override
  State<ChannelsPanel> createState() => _ChannelsPanelState();
}

class _ChannelsPanelState extends State<ChannelsPanel> {
  bool _isLoading = false;
  List<dynamic> _textChannels = [];
  List<dynamic> _vocalChannels = [];

  Future<void> _fetchChannels() async {
    setState(() {
      _isLoading = true;
    });

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get('$apiPath/servers/${widget.serverId}/channels');

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

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      await Dio().put(
        '$apiPath/channels/$channelId',
        data: {
          'name': channelName,
        },
      );
    } catch (error) {
      print('Error updating channel: $error');
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.text_channels_section),
        for (final channel in _textChannels)
          GestureDetector(
            child: ListTile(
              trailing: const Icon(Icons.arrow_forward_ios),
              title: Text(channel['Name']),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChannelPage(
                    channelId: channel['ID'],
                    channelName: channel['Name'],
                    serverId: widget.serverId,
                  ),
                ),
              ),
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    TextEditingController channelNameController =
                    TextEditingController(text: channel['Name']);

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
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            try {
                              final response = await Dio().delete(
                                '${dotenv.env['API_PATH']}/channels/${channel['ID']}',
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
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            _updateChannel(
                              channel['ID'].toString(),
                              channelNameController.text,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        Text(AppLocalizations.of(context)!.voice_channels_section),
        for (final channel in _vocalChannels)
          ListTile(
            title: Text(channel['Name']),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoiceRoom(
                  channelId: channel['ID'],
                  channelName: channel['Name'],
                ),
              ),
            ),
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) {
                  TextEditingController channelNameController =
                  TextEditingController(text: channel['Name']);

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
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          try {
                            final response = await Dio().delete(
                              '${dotenv.env['API_PATH']}/channels/${channel['ID']}',
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
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          _updateChannel(
                            channel['ID'].toString(),
                            channelNameController.text,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
      ],
    );
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
