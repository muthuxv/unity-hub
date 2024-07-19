import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VoiceRoom extends StatefulWidget {
  final String channelId;
  final String channelName;
  const VoiceRoom({super.key, required this.channelId, required this.channelName});

  @override
  State<VoiceRoom> createState() => _VoiceRoomState();
}

class _VoiceRoomState extends State<VoiceRoom> {

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}