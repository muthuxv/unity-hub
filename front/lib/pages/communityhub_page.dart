import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Server {
  final String id;
  final String name;
  final String visibility;
  final Media media;
  final List<Tag> tags;

  Server({
    required this.id,
    required this.name,
    required this.visibility,
    required this.media,
    required this.tags,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    var tagsList = json['Tags'] as List;
    List<Tag> tags = tagsList.map((i) => Tag.fromJson(i)).toList();
    Media media = Media.fromJson(json['Media']);

    return Server(
      id: json['ID'],
      name: json['Name'],
      visibility: json['Visibility'],
      media: media,
      tags: tags,
    );
  }
}

class Tag {
  final String id;
  final String name;

  Tag({
    required this.id,
    required this.name,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['ID'],
      name: json['Name'],
    );
  }
}

class Media {
  final String id;
  final String fileName;
  final String mimeType;

  Media({
    required this.id,
    required this.fileName,
    required this.mimeType,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['ID'],
      fileName: json['FileName'],
      mimeType: json['MimeType'],
    );
  }
}

class CommunityHubPage extends StatefulWidget {
  const CommunityHubPage({super.key});

  @override
  _CommunityHubPageState createState() => _CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> {
  late Future<List<Server>> futureServers;
  TextEditingController searchController = TextEditingController();
  List<Server> displayedServers = [];

  @override
  void initState() {
    super.initState();
    futureServers = fetchServers();
  }

  Future<List<Server>> fetchServers() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/servers'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      List<Server> servers =
      jsonResponse.map((server) => Server.fromJson(server)).toList();
      return servers;
    } else {
      throw Exception('Failed to load servers');
    }
  }

  Future<void> searchServers(String searchTerm) async {
    if (searchTerm.isEmpty) {
      setState(() {
        displayedServers = [];
      });
      return;
    }

    print(searchTerm);
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/servers/search?name=$searchTerm'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      List<Server> searchedServers =
      jsonResponse.map((server) => Server.fromJson(server)).toList();
      setState(() {
        displayedServers = searchedServers;
      });
    } else {
      setState(() {
        displayedServers = [];
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Aucun serveur trouvé'),
            content: Text('Il n\'y a pas de serveur portant ce nom.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Hub', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[300],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: FutureBuilder<List<Server>>(
                future: futureServers,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<Server> servers = displayedServers.isNotEmpty ? displayedServers : snapshot.data!;
                    Map<String, List<Server>> serversByTag = {};

                    for (var server in servers) {
                      for (var tag in server.tags) {
                        if (!serversByTag.containsKey(tag.name)) {
                          serversByTag[tag.name] = [];
                        }
                        serversByTag[tag.name]!.add(server);
                      }
                    }

                    return ListView(
                      children: serversByTag.entries.map((entry) {
                        String tagName = entry.key;
                        List<Server> servers = entry.value;

                        return CategorySection(tagName: tagName, servers: servers);
                      }).toList(),
                    );
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }

                  return CircularProgressIndicator();
                },
              ),
            ),
          ),
          SearchBar(
            onSearch: searchServers,
            searchController: searchController,
          ),
        ],
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  final String tagName;
  final List<Server> servers;

  const CategorySection({Key? key, required this.tagName, required this.servers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            tagName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: <Color>[
                    Colors.blue,
                    Colors.purple,
                    Colors.pink,
                  ],
                ).createShader(
                    const Rect.fromLTWH(
                        0.0, 0.0, 200.0, 70.0)),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: servers.map((server) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    // Gérer le clic sur le serveur
                  },
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.purpleAccent, Colors.deepPurple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            'http://10.0.2.2:8080/uploads/${server.media.fileName}?rand=${DateTime.now().millisecondsSinceEpoch}',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                server.name,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              SizedBox(height: 4),
                              Text(
                                server.tags.map((tag) => tag.name).join(', '),
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final TextEditingController searchController;

  const SearchBar({Key? key, required this.onSearch, required this.searchController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  onSearch(value);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un serveur',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Icon(Icons.filter_list, color: Colors.white),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CommunityHubPage(),
  ));
}
