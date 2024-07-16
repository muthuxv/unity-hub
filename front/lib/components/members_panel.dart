import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MembersPanel extends StatefulWidget {
  final int serverId;
  const MembersPanel({super.key, required this.serverId});

  @override
  State<MembersPanel> createState() => _MembersPanelState();
}

class _MembersPanelState extends State<MembersPanel> {
  bool _isLoading = false;
  List _members = [];


  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
    });

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get('$apiPath/servers/${widget.serverId}/members');
      print('Response: $response');
      setState(() {
        _members = response.data['data'];
      });
      print('Members fetched: $_members');
    } catch (error) {
      print('Error fetching members: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Expanded(
              child: SizedBox(
                height: 200.0,
                child: ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return ListTile(
                      title: Text(member['Pseudo']),
                      subtitle: Text(member['Email']),
                    );
                  },
                ),
              ),
            );
  }
}
