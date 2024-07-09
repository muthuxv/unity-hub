import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/services.dart';

class ServerMembersList extends StatefulWidget {
  final String serverId;

  const ServerMembersList({Key? key, required this.serverId}) : super(key: key);

  @override
  State<ServerMembersList> createState() => _ServerMembersListState();
}

class _ServerMembersListState extends State<ServerMembersList> {
  bool _isLoading = false;
  List _serverMembers = [];

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchServerMembers();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchServerMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.get('http://10.0.2.2:8080/servers/${widget.serverId}/members');

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
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final currentUserId = decodedToken['jti'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        bool isCurrentUser = member['ID'] == currentUserId;

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
                child: Text(
                  member['Pseudo'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      if (!isCurrentUser)
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: Text(AppLocalizations.of(context)!.banMember),
                          onTap: () {
                            Navigator.pop(context);
                            _showBanConfirmationDialog(member);
                          },
                        ),
                      if (isCurrentUser)
                        ListTile(
                          title: const Text('Vous êtes l\'utilisateur courant'),
                          onTap: () {
                            Navigator.pop(context);
                            _showSuccessDialog('Vous êtes l\'utilisateur courant');
                          },
                        ),
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

  void _banMember(Map member, String reason, int duration) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      _showErrorDialog('User token not found');
      return;
    }

    final Dio dio = Dio();

    try {
      final response = await dio.post(
        'http://10.0.2.2:8080/servers/${widget.serverId}/ban/users/${member['ID']}',
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
              child: Text('OK'),
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
          return GestureDetector(
            onTap: () {
              _showBottomModal(member);
            },
            child: ListTile(
              title: Text(member['Pseudo']),
              leading: CircleAvatar(
                child: member['Profile'] != null && member['Profile'].contains('<svg')
                    ? SvgPicture.string(
                  member['Profile'],
                  height: 40,
                  width: 40,
                )
                    : CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(member['Profile']),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
