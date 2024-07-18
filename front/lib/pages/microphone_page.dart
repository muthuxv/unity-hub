import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioFeedbackPage extends StatefulWidget {
  const AudioFeedbackPage({super.key});

  @override
  _AudioFeedbackPageState createState() => _AudioFeedbackPageState();
}

class _AudioFeedbackPageState extends State<AudioFeedbackPage> {
  FlutterSoundPlayer? _player;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Directory tempDir = Directory.systemTemp;
  String tempPath = '';

  @override
  void initState() {
    super.initState();
    _player = FlutterSoundPlayer();
    _recorder = FlutterSoundRecorder();
    _initialize();
  }

  Future<void> _initialize() async {
    await Permission.microphone.request();

    try {
      await _recorder!.openRecorder();
      await _player!.openPlayer();
    } catch (e) {
      print('Error initializing recorder/player: $e');
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      try {
        await _recorder!.stopRecorder();
        setState(() {
          _isRecording = false;
        });
      } catch (e) {
        print('Error stopping recorder: $e');
      }
    } else {
      try {
        await _recorder!.startRecorder(
          codec: Codec.pcm16WAV,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 64000,
        );
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        print('Error starting recorder: $e');
      }
    }
  }

  @override
  void dispose() {
    _closeAudioResources();
    super.dispose();
  }

  Future<void> _closeAudioResources() async {
    try {
      if (_player != null) {
        await _player!.closePlayer();
      }
      if (_recorder != null) {
        await _recorder!.closeRecorder();
      }
    } catch (e) {
      print('Error closing audio resources: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Microphone App'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _toggleRecording,
          child: Text(_isRecording ? 'Arrêter' : 'Démarrer'),
        ),
      ),
    );
  }
}
