import 'package:uuid/uuid.dart';

class Group {
  final String id;
  final String type;
  final String channelId;
  final String name;
  final String image;
  final List<dynamic> members;
  final String ownerId;

  Group({required this.id, required this.type, required this.channelId, required this.name, this.image = '', required this.members, this.ownerId = ''});
}

class User {
  final String id;
  final String name;
  final String image;

  User({required this.id, required this.name, this.image = ''});
}
