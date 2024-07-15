import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServerBanMembersPage extends StatefulWidget {
  final String serverId;

  const ServerBanMembersPage({super.key, required this.serverId});

  @override
  _ServerBanMembersPageState createState() => _ServerBanMembersPageState();
}

class _ServerBanMembersPageState extends State<ServerBanMembersPage> {
  bool _isLoading = false;
  List _bannedMembers = [];

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchBannedMembers();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchBannedMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.get('http://10.0.2.2:8080/servers/${widget.serverId}/bans');

      if (response.statusCode == 200) {
        setState(() {
          _bannedMembers = response.data;
        });
      } else {
        _showErrorDialog('An error occurred while fetching banned members.');
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
          title: const Text('Error'),
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

  void _showConfirmationDialog(String userID) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.unbanMemberConfirmation),
          content: Text(AppLocalizations.of(context)!.unbanMemberConfirmationMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unbanMember(userID);
              },
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unbanMember(String userID) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      _showErrorDialog('User token not found');
      return;
    }

    try {
      final response = await _dio.delete(
          'http://10.0.2.2:8080/servers/${widget.serverId}/unban/users/$userID',
          options: Options(headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          })
      );

      if (response.statusCode == 200) {
        _showSuccessDialog(AppLocalizations.of(context)!.memberUnbanned);
        _fetchBannedMembers();
      } else {
        _showErrorDialog('Failed to unban member');
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

  String _formatDate(String dateStr) {
    final DateTime date = DateTime.parse(dateStr);
    return DateFormat.yMMMMd('fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bannedMembers),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _bannedMembers.isEmpty
          ? Center(
        child: Text(
          AppLocalizations.of(context)!.noBannedMembers,
          style: const TextStyle(fontSize: 18),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _bannedMembers.length,
          itemBuilder: (context, index) {
            final ban = _bannedMembers[index];
            final user = ban['User'];
            return GestureDetector(
              onTap: () {
                _showConfirmationDialog(user['ID']);
              },
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: user['Profile'] != null && user['Profile'].contains('<svg')
                            ? SvgPicture.string(
                          user['Profile'],
                          height: 50,
                          width: 50,
                        )
                            : CircleAvatar(
                          radius: 30,
                          backgroundImage: user['Profile'] != ""
                              ? NetworkImage(user['Profile'])
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['Pseudo'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppLocalizations.of(context)!.reason}: ${ban['Reason']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalizations.of(context)!.duration}: ${_formatDate(ban['Duration'])}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}