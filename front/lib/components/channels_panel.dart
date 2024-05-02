import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../pages/channel_page.dart';

class ChannelsPanel extends StatefulWidget {
  final int serverId;
  const ChannelsPanel({super.key, required this.serverId});

  @override
  State<ChannelsPanel> createState() => _ChannelsPanelState();
}

class _ChannelsPanelState extends State<ChannelsPanel> {
  bool _isLoading = false;
  List<dynamic> _textChannels = [];
  List<dynamic> _vocalChannels = [];

  // Fetch channels knowing that my server returns a list of channels by vocal and text
  Future<void> _fetchChannels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Dio().get('http://10.0.2.2:8080/servers/${widget.serverId}/channels');
      print('Response: $response');
      setState(() {
        _textChannels = response.data['text'];
        _vocalChannels = response.data['vocal'];
      });
      print('Text channels fetched: $_textChannels');
      print('Vocal channels fetched: $_vocalChannels');
    } catch (error) {
      print('Error fetching channels: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text Channels'),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _textChannels.length,
                  itemBuilder: (context, index) {
                    final channel = _textChannels[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChannelPage(channelId: channel['ID']),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(channel['Name']),
                      ),
                    );
                  },
                ),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0), // Adjust the top and bottom padding as needed
                  child: Text('Vocal Channels'),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _vocalChannels.length,
                  itemBuilder: (context, index) {
                    final channel = _vocalChannels[index];
                    return ListTile(
                      title: Text(channel['Name']),
                    );
                  },
                ),
              ],
            ),
          ],
        );
  }
}
