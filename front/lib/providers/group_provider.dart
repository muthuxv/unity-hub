import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
          '$apiPath/groups/users/$userId',
          options: Options(
              headers:
              {'Authorization' : 'Bearer $token'}
          ));
      if (response.statusCode == 200) {
        List<dynamic>? data = response.data;

        // Check if the data is null or not a list
        if (data == null) {
          _groups = [];
        } else {
          // Sort the data by 'updated_at' in descending order
          data.sort((a, b) => DateTime.parse(b['UpdatedAt']).compareTo(DateTime.parse(a['UpdatedAt'])));

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
              ownerId: item['OwnerID'] ?? ''
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

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().post('$apiPath/groups/private/$userId1',
        data: {'userID': userId2},
        options: Options(
            headers:
            {'Authorization': 'Bearer $token'}
        )
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      fetchGroups();
    }
  }

  Future<void> createGroup(List<String> memberIds, String groupId) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final response = await Dio().post('$apiPath/groups/public/$userId',
        data: {'group_id': groupId, 'member_ids': memberIds},
        options: Options(
            headers:
            {'Authorization': 'Bearer $token'}
        )
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      fetchGroups();
    }
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    final dio = Dio();

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    final url = '$apiPath/groups/$groupId/members/$userId';
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await dio.delete(
          url,
          options: Options(
              headers:
              {'Authorization': 'Bearer $token'}
          )
      );

      if (response.statusCode == 204) {
        groups.removeWhere((group) => group.id == groupId);
        notifyListeners();
      } else {
        throw Exception('Failed to leave group');
      }
    } catch (error) {
      throw Exception('Failed to leave group: $error');
    }
  }
}
