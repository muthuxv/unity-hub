import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:unity_hub/utils/random_server_avatar.dart';
import 'package:unity_hub/utils/media_uploader.dart';

class AddServerPage extends StatefulWidget {
  final Function(Map)? onServerAdded;
  const AddServerPage({super.key, this.onServerAdded});

  @override
  State<AddServerPage> createState() => _AddServerPageState();
}

class _AddServerPageState extends State<AddServerPage> {
  bool _isLoading = false;
  final TextEditingController _serverNameController = TextEditingController();
  String _visibility = 'private';
  bool _showTagsField = false;
  List<dynamic> _tags = [];
  List<dynamic> _selectedTags = [];

  void _toggleTagsField(bool value) {
    setState(() {
      _showTagsField = value;
      if (!_showTagsField) {
        _selectedTags = [];
      }
    });
  }

  Future<void> _fetchTags() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final response = await Dio().get(
      'http://10.0.2.2:8080/tags',
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
      setState(() {
        _tags = response.data;
      });
    } else {
      _showErrorSnackBar(response.data['message']);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  Future<void> _addServer() async {
    if (_serverNameController.text.isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context)!.server_name_required_error);
      return;
    }

    if (_visibility == 'public' && _selectedTags.isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context)!.public_server_tags_required_error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final avatarGenerator = ServerAvatarGenerator(filename: 'lib/images/unity_white.png');
    final mediaUploader = await MediaUploader(filePath: (await avatarGenerator.generate())).upload();

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final tagIds = _selectedTags.map((tag) => tag['ID']).toList();
    final tagObjects = tagIds.map((tagId) => {'id': tagId}).toList();

    final data = {
      'name': _serverNameController.text,
      'visibility': _visibility,
      'tags': tagObjects,
      'MediaID': mediaUploader['id'],
    };

    final response = await Dio().post(
      'http://10.0.2.2:8080/servers/create',
      data: data,
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

    if (response.statusCode == 201) {
      Navigator.pop(context);
      final newServer = response.data['data'];
      widget.onServerAdded?.call(newServer);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.server_created_title),
          content: Text(AppLocalizations.of(context)!.server_created_message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel_button),
            ),
          ],
        ),
      );
    } else {
      _showErrorSnackBar(AppLocalizations.of(context)!.server_creation_error);
    }

    setState(() {
      _isLoading = false;
    });
  }

  final TextEditingController _linkController = TextEditingController();

  void _showInvitationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.enter_invitation_link_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.invitation_link_label,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.invitation_link_label;
                  }
                  return null;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.cancel_button),
                  ),
                  TextButton(
                    onPressed: () {
                      _joinServer(_linkController.text);
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.join_button),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _joinServer(String link) async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await Dio().post(
        link,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.joined_server_success_message),
          ),
        );
      } else {
        final errorMessage = response.data['error'] ?? AppLocalizations.of(context)!.join_server_error_message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.join_server_error_message),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: true, // Ensure the keyboard doesn't hide input
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4776e6), Color(0xff8e54e9)],
                stops: [0, 1],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.create_server,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Image.asset(
                          'lib/images/unitylog.png',
                          width: 100,
                          color: Colors.white,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            AppLocalizations.of(context)!.give_name_and_visibility,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Radio(
                                    fillColor: MaterialStateProperty.all(Colors.white),
                                    value: 'public',
                                    groupValue: _visibility,
                                    onChanged: (value) {
                                      setState(() {
                                        _visibility = 'public';
                                        _toggleTagsField(true);
                                      });
                                    },
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.create_public_server,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Radio(
                                    fillColor: MaterialStateProperty.all(Colors.white),
                                    value: 'private',
                                    groupValue: _visibility,
                                    onChanged: (value) {
                                      setState(() {
                                        _visibility = 'private';
                                        _toggleTagsField(false);
                                      });
                                    },
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.create_private_server,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _serverNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.server_name_label,
                            labelStyle: const TextStyle(color: Colors.white),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _showTagsField
                            ? Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.tags_label),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: MultiSelectDialogField(
                                        items: _tags
                                            .map((tag) => MultiSelectItem(tag, tag['Name']))
                                            .toList(),
                                        initialValue: _selectedTags,
                                        onConfirm: (selected) {
                                          setState(() {
                                            _selectedTags = selected;
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(AppLocalizations.of(context)!.cancel_button),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  AppLocalizations.of(context)!.tags_label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        )
                            : _visibility == 'public'
                            ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            AppLocalizations.of(context)!.tags_required_public,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _addServer,
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        const EdgeInsets.all(16),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.create_server_button),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.already_have_invitation_code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _showInvitationDialog(context);
                    },
                    child: Text(AppLocalizations.of(context)!.join_server_button),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
