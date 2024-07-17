import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:unity_hub/utils/random_server_avatar.dart';
import 'package:unity_hub/utils/media_uploader.dart';

class AddServerPage extends StatefulWidget {
  final Function(Map)? onServerAdded;
  const AddServerPage({Key? key, this.onServerAdded}) : super(key: key);

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

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().get(
      '$apiPath/tags',
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
      _showErrorSnackBar(response.data['error']);
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

  Future<void> _createTag(String tagName) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final data = {'name': tagName};

    final response = await Dio().post(
      '$apiPath/tags',
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
      final newTag = response.data;

      setState(() {
        _tags.add(newTag);

        List<dynamic> updatedSelectedTags = List.from(_selectedTags);
        updatedSelectedTags.add(newTag);
        _selectedTags = updatedSelectedTags;
      });
    } else {
      _showErrorSnackBar(response.data['error']);
    }
  }

  void _showCreateTagDialog(BuildContext context) {
    String newTagName = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.create_new_tag),
          content: TextField(
            onChanged: (value) {
              newTagName = value;
            },
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enter_tag_name,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                if (newTagName.isNotEmpty) {
                  _createTag(newTagName);
                  Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.of(context)!.confirmButton),
            ),
          ],
        );
      },
    );
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

    final tagIds = _selectedTags.map((tag) => tag['ID']).toList();
    final tagObjects = tagIds.map((tagId) => {'id': tagId}).toList();

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final data = {
      'name': _serverNameController.text,
      'visibility': _visibility,
      'tags': tagObjects,
      'MediaID': mediaUploader['id'],
    };

    final response = await Dio().post(
      '$apiPath/servers/create',
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
              child: Text(AppLocalizations.of(context)!.ok_button),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: true,
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
                        if (_showTagsField)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showCreateTagDialog(context);
                                },
                                child: Text(AppLocalizations.of(context)!.create_new_tag),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: MultiSelectDialogField(
                                  items: _tags.map((tag) => MultiSelectItem(tag, tag['Name'])).toList(),
                                  title: Text(
                                    AppLocalizations.of(context)!.select_tags,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  selectedColor: Colors.blue,
                                  initialValue: _selectedTags,
                                  onConfirm: (values) {
                                    _selectedTags = values;
                                  },
                                  buttonText: Text(
                                    AppLocalizations.of(context)!.select_tags,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  buttonIcon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _addServer,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(AppLocalizations.of(context)!.create_server_button),
                        ),
                      ],
                    ),
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
