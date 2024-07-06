import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServerMembersList extends StatefulWidget {
  final int serverId;

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
          return ListTile(
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
          );
        },
      ),
    );
  }
}