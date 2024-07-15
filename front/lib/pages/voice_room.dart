import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRoom extends StatefulWidget {
  final String channelId;
  final String channelName;

  const VoiceRoom({Key? key, required this.channelId, required this.channelName}) : super(key: key);

  @override
  _VoiceRoomState createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      if (await Permission.microphone.request().isGranted) {
        _initialize();
      } else {
        // Permission denied, show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le microphone est nécessaire pour les salons vocaux.')),
        );
      }
    } else {
      _initialize();
    }
  }

  void _initialize() {
    initRenderers();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
      _createOffer();
    });
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (candidate) {
      if (candidate != null) {
        _sendCandidate(candidate);
      }
    };

    pc.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
    };

    _localStream = await _getUserMedia();
    pc.addStream(_localStream!);

    return pc;
  }

  Future<MediaStream> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    final response = await Dio().post(
      'https://unityhub.fr/webrtc/sdp',
      data: {
        'sdp': offer.sdp,
        'type': offer.type,
      },
    );

    final answer = response.data;
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
  }

  void _sendCandidate(RTCIceCandidate candidate) {
    Dio().post(
      'https://unityhub.fr/webrtc/ice',
      data: {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
      ),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(_localRenderer),
          ),
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
        ],
      ),
    );
  }
}
