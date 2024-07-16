import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

class MicrophoneFeedbackPage extends StatefulWidget {
  const MicrophoneFeedbackPage({Key? key}) : super(key: key);

  @override
  _MicrophoneFeedbackPageState createState() => _MicrophoneFeedbackPageState();
}

class _MicrophoneFeedbackPageState extends State<MicrophoneFeedbackPage> {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
    await _player.openPlayer();
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
    await _recorder.stopRecorder();
    await _player.startPlayer(
      fromURI: 'feedback.aac',
      codec: Codec.aacADTS,
    );
    setState(() {
      _isRecording = false;
    });
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Microphone Feedback'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Feedback' : 'Start Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
