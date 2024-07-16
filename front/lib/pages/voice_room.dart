import 'dart:convert';
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
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  List<RTCIceCandidate> _remoteCandidates = [];
  List<MediaStream> _remoteStreams = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      var result = await Permission.microphone.request();
      if (result.isGranted) {
        _initialize();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le microphone est nécessaire pour les salons vocaux.')),
        );
      }
    } else {
      _initialize();
    }
  }

  void _initialize() {
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
      _createOffer();
    });
  }

  @override
  void dispose() {
    _peerConnection?.close();
    _localStream?.dispose();
    for (var stream in _remoteStreams) {
      stream.dispose();
    }
    super.dispose();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (candidate) {
      if (candidate != null) {
        _sendCandidate(candidate);
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteStreams.add(event.streams[0]);
        });
      }
    };

    _localStream = await _getUserMedia();
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    return pc;
  }

  Future<MediaStream> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };
    try {
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      print('Microphone stream initialized');
      return stream;
    } catch (e) {
      print('Error accessing microphone: $e');
      throw e;
    }
  }

  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    final response = await Dio().post(
      'https://unityhub.fr/webrtc/sdp',
      data: {
        'sdp': offer.sdp,
        'type': offer.type,
        'channel_id': widget.channelId,
      },
    );

    final answer = jsonDecode(response.data);
    print(answer);

    await _peerConnection!.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));

    // Gérer les candidats ICE de la télécommande
    for (var candidate in _remoteCandidates) {
      await _peerConnection!.addCandidate(candidate);
    }
    _remoteCandidates.clear();
  }

  void _sendCandidate(RTCIceCandidate candidate) {
    Dio().post(
      'https://unityhub.fr/webrtc/ice',
      data: {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'channel_id': widget.channelId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
      ),
      body: Center(
        child: Text('Salon vocal en cours...'),
      ),
    );
  }
}