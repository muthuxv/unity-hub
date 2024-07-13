import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:unity_hub/models/group_model.dart';

class GroupProvider with ChangeNotifier {
  List<Group> _groups = [];

  List<Group> get groups => _groups;

  GroupProvider() {
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    try {
      final response = await Dio().get('http://10.0.2.2:8080/groups/users/$userId');
      if (response.statusCode == 200) {
        List<dynamic>? data = response.data;

        // Check if the data is null or not a list
        if (data == null) {
          _groups = [];
        } else {
          _groups = data.map((item) {
            String groupName;
            String groupImage;

            if (item['Type'] == 'dm') {
              final otherMember = item['Members'].firstWhere((element) => element['ID'] != userId);
              groupName = otherMember['Pseudo'];
              groupImage = otherMember['Profile'];
            } else {
              groupName = item['Channel']['Name'];
              groupImage = '';
            }
            return Group(
              id: item['ID'],
              type: item['Type'],
              channelId: item['ChannelID'],
              name: groupName,
              image: groupImage,
              members: (item['Members'] as List).map((member) {
                return User(
                  id: member['ID'],
                  name: member['Pseudo'],
                  image: member['Profile'],
                );
              }).toList(),
            );
          }).toList();
        }
        notifyListeners();
      } else {
        // Handle non-200 response status codes
        _groups = [];
        notifyListeners();
      }
    } catch (e) {
      // Handle any exceptions that occur during the HTTP request
      print('Error fetching groups: $e');
      _groups = [];
      notifyListeners();
    }
  }

  void reset() {
    _groups = [];
    notifyListeners();
  }

  Future<void> createDM(String userId2) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId1 = decodedToken['jti'];

    final response = await Dio().post('http://10.0.2.2:8080/groups/private/$userId1',
        data: {'userID': userId2});
    if (response.statusCode == 201 || response.statusCode == 200) {
      fetchGroups();
    }
  }

  Future<void> createGroup(List<String> memberIds, String groupId) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    final response = await Dio().post('http://10.0.2.2:8080/groups/public/$userId',
        data: {'group_id': groupId, 'member_ids': memberIds});
    if (response.statusCode == 200 || response.statusCode == 201) {
      fetchGroups();
    }
  }
}
