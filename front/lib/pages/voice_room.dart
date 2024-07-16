import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

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
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le microphone est nécessaire pour les salons vocaux.')),
        );
      }
    } else {
      _initialize();
    }
  }

  void _initialize() {
    _initializeRecorder().then((_) {
      _createPeerConnection().then((pc) {
        _peerConnection = pc;
        _createOffer();
      });
    });
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();
      await _player.openPlayer();
      _startRecording();
    } catch (err) {
      print('Error initializing recorder or player: $err');
    }
  }

  Future<void> _startRecording() async {
    try {
      await _recorder.startRecorder(
        toFile: 'feedback.aac',
        codec: Codec.aacADTS,
      );
      setState(() {
        _isRecording = true;
      });
    } catch (err) {
      print('Error starting recording: $err');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      await _player.startPlayer(
        fromURI: 'feedback.aac',
        codec: Codec.aacADTS,
      );
      setState(() {
        _isRecording = false;
      });
    } catch (err) {
      print('Error stopping recording or starting playback: $err');
    }
  }

  @override
  void dispose() {
    _stopRecordingAndClose().then((_) {
      _peerConnection?.close();
      _localStream?.dispose();
      super.dispose();
    });
  }

  Future<void> _stopRecordingAndClose() async {
    if (_isRecording) {
      await _stopRecording();
    }
    try {
      await _recorder.closeRecorder();
      await _player.closePlayer();
    } catch (err) {
      print('Error closing recorder or player: $err');
    }
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
      // Gérer les flux audio entrants
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

    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    final response = await Dio().post(
      'http://10.0.2.2:8080/webrtc/sdp',
      data: {
        'sdp': offer.sdp,
        'type': offer.type,
      },
    );

    final answer = jsonDecode(response.data);
    print(answer);

    await _peerConnection!.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));

    for (var candidate in _remoteCandidates) {
      await _peerConnection!.addCandidate(candidate);
    }
    _remoteCandidates.clear();
  }

  void _sendCandidate(RTCIceCandidate candidate) {
    Dio().post(
      'http://10.0.2.2:8080/webrtc/ice',
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
      body: Center(
        child: Text('Salon vocal en cours...'),
      ),
    );
  }
}
