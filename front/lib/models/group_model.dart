import 'package:uuid/uuid.dart';

class Group {
  final String id;
  final String type;
  final String channelId;
  final String name;
  final String image;
  final List<dynamic> members;

  Group({required this.id, required this.type, required this.channelId, required this.name, this.image = '', required this.members});
}

class User {
  final String id;
  final String name;
  final String image;

  User({required this.id, required this.name, this.image = ''});
}
