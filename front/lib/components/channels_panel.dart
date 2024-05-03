import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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

  Future<void> _connectToChannel(String channelId) async {
    try {
      final response = await Dio().get(
          'http://10.0.2.2:8080/channels/$channelId/connect');
      print('Response: $response');
      final offer = response.data['offer'];
      print('Offer: $offer');

      final session = await createPeerConnection({
        'iceServers': [
          {'url': 'stun:stun.l.google.com:19302'},
        ]
      }, {});

      session.onIceCandidate = (candidate) {
        print('Ice candidate: $candidate');
      };
      session.onIceConnectionState = (state) {
        print('Ice connection state: $state');
      };

      // Set the local description first
      await session.setRemoteDescription(RTCSessionDescription(offer, 'offer'));

      final answer = await session.createAnswer({});
      await session.setLocalDescription(answer);

      final Map<String, dynamic> data = {
        'answer': answer.sdp,
      };

      print('Data: $data');

      final response2 = await Dio().post(
        'http://10.0.2.2:8080/channels/$channelId/answer',
        data: data,
      );

      print('Response 2: $response2');
    } catch (error) {
      print('Error connecting to channel: $error');
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
              const Text('# Salons-textuels'),
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
                        ),
                      ),
                    ),
                  ),
                ),
              const Text('# Salons-vocaux'),
              for (final channel in _vocalChannels)
                ListTile(
                  title: Text(channel['Name']),
                  onTap: () => _connectToChannel(channel['ID'].toString()),
                ),
            ],
          );
  }
}
