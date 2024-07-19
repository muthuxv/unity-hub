import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddChannelPage extends StatefulWidget {
  final String serverId;
  const AddChannelPage({super.key, required this.serverId});

  @override
  State<AddChannelPage> createState() => _AddChannelPageState();
}

class _AddChannelPageState extends State<AddChannelPage> {
  final TextEditingController _channelNameController = TextEditingController();
  var _channelType = 'text';

  Future<void> _addChannel() async {
    if (_channelNameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.channel_name_error_title),
            content: Text(AppLocalizations.of(context)!.channel_name_error_message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.ok_button),
              ),
            ],
          );
        },
      );
      return;
    }

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().post('$apiPath/channels', data: {
      'name': _channelNameController.text,
      'type': _channelType,
      'serverId': widget.serverId,
      'permission': 'all',
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

    if (response.statusCode == 201) {
      Navigator.pop(context, response);
    } else {
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
                child: Text(AppLocalizations.of(context)!.ok_button),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          title: Text(
              AppLocalizations.of(context)!.add_channel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )
          ),
          iconTheme: const IconThemeData(color: Colors.white),
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
          child: Container(
            margin: const EdgeInsets.only(top: 75.0),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(
                  Icons.message_outlined,
                  color: Colors.white,
                  size: 100,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _channelNameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.channel_name_label,
                    labelStyle: const TextStyle(color: Colors.white),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
                Text(
                  AppLocalizations.of(context)!.channel_type_label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 16.0),
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
                            value: 'text',
                            groupValue: _channelType,
                            onChanged: (value) {
                              setState(() {
                                _channelType = 'text';
                              });
                            },
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.text_channel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.text_channel_description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
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
                            value: 'vocal',
                            groupValue: _channelType,
                            onChanged: (value) {
                              setState(() {
                                _channelType = 'vocal';
                              });
                            },
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.voice_channel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.voice_channel_description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _addChannel,
                  child: Text(AppLocalizations.of(context)!.add_channel_button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
