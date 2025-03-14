import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:unity_hub/pages/security/auth_page.dart';

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
  const CommunityHubPage({Key? key});

  @override
  _CommunityHubPageState createState() => _CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> {
  late Future<List<Server>> futureServers;
  TextEditingController searchController = TextEditingController();
  List<Server> allServers = [];
  List<Server> displayedServers = [];
  List<Tag> availableTags = [];
  String selectedTag = "";
  String filteredTagName = ""; // Nouvelle variable pour le tag filtré

  @override
  void initState() {
    super.initState();
    futureServers = fetchServers();
  }

  Future<List<Server>> fetchServers() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
      final userId = decodedToken['jti'];

      await dotenv.load();
      final apiPath = dotenv.env['API_PATH']!;

      final response = await Dio().get(
        '$apiPath/servers/public/available/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        List jsonResponse = response.data['data'];
        List<Server> servers = jsonResponse.map((server) => Server.fromJson(server)).toList();

        Set<String> tagSet = Set();
        servers.forEach((server) {
          server.tags.forEach((tag) {
            tagSet.add(tag.name);
          });
        });

        availableTags = tagSet.map((tagName) => Tag(id: '', name: tagName)).toList();

        setState(() {
          allServers = servers;
          displayedServers = servers;
        });
        return servers;
      } else {
        throw Exception('Failed to load servers');
      }
    } catch (e) {
      throw Exception('Failed to load servers: $e');
    }
  }

  void filterServersByTag(String tag) {
    setState(() {
      selectedTag = tag;
      if (tag.isEmpty || tag.toLowerCase() == "tous") {
        displayedServers = allServers;
          filteredTagName = ""; // Réinitialiser le filtre
      } else {
        displayedServers = allServers
            .where((server) =>
            server.tags.any((serverTag) =>
            serverTag.name.toLowerCase() == tag.toLowerCase()))
            .toList();
        filteredTagName = tag; // Mettre à jour le tag filtré
      }
    });
  }

  void searchServers(String searchTerm) {
    if (searchTerm.isEmpty) {
      setState(() {
        displayedServers = allServers;
      });
      return;
    }

    setState(() {
      displayedServers = allServers
          .where((server) =>
          server.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }

  Future<void> _joinServer(String serverId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      await dotenv.load();
      final apiPath = dotenv.env['API_PATH']!;

      final response = await Dio().post(
        '$apiPath/servers/$serverId/join',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          allServers.removeWhere((server) => server.id == serverId);
          displayedServers.removeWhere((server) => server.id == serverId);
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.success),
              content: Text(AppLocalizations.of(context)!.serverJoinedSuccessfully),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthPage()));
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.error),
              content: Text(AppLocalizations.of(context)!.failedJoinServer),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.error),
            content: Text('${AppLocalizations.of(context)!.failedJoinServer}: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showJoinConfirmationDialog(Server server) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.joinServerConfirmation),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _joinServer(server.id);
              },
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info, size: 80, color: Colors.grey),
                        Text(
                          AppLocalizations.of(context)!.no_public_servers,
                          style: const TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ],
                    );
                  } else {
                    List<Server> servers =
                    displayedServers.isNotEmpty ? displayedServers : snapshot.data!;

                    if (selectedTag.isNotEmpty && selectedTag.toLowerCase() != "tous") {
                      servers = servers
                          .where((server) =>
                          server.tags.any((serverTag) => serverTag.name.toLowerCase() == selectedTag.toLowerCase()))
                          .toList();
                    }

                    Map<String, List<Server>> serversByTag = {};
                    for (var server in servers) {
                      for (var tag in server.tags) {
                        if (filteredTagName.isNotEmpty) {
                          if (!serversByTag.containsKey(tag.name)) {
                            serversByTag[tag.name] = [];
                          }
                          serversByTag[tag.name]!.add(server);
                          break;
                        } else {
                          if (!serversByTag.containsKey(tag.name)) {
                            serversByTag[tag.name] = [];
                          }
                          serversByTag[tag.name]!.add(server);
                        }
                      }
                    }

                    return ListView(
                      children: serversByTag.entries.map((entry) {
                        String tagName = entry.key;
                        List<Server> servers = entry.value;

                        return CategorySection(
                          tagName: tagName,
                          servers: servers,
                          onJoinServer: _showJoinConfirmationDialog,
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
          ),
          SearchBar(
            onSearch: searchServers,
            searchController: searchController,
            onFilterTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(AppLocalizations.of(context)!.filterByTag),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.all),
                            onTap: () {
                              filterServersByTag(AppLocalizations.of(context)!.all);
                              Navigator.of(context).pop();
                            },
                          ),
                          ...availableTags.map((tag) {
                            return ListTile(
                              title: Text(tag.name),
                              onTap: () {
                                filterServersByTag(tag.name);
                                Navigator.of(context).pop();
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  final String tagName;
  final List<Server> servers;
  final Function(Server) onJoinServer;

  const CategorySection({
    Key? key,
    required this.tagName,
    required this.servers,
    required this.onJoinServer,
  });

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
                    0.0,
                    0.0,
                    200.0,
                    70.0,
                  ),
                ),
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
                    onJoinServer(server);
                  },
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.purpleAccent, Colors.deepPurple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            '${dotenv.env['API_PATH']}/uploads/${server.media.fileName}?rand=${DateTime.now().millisecondsSinceEpoch}',
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                server.tags.map((tag) => tag.name).join(', '),
                                style: const TextStyle(color: Colors.white),
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
  final VoidCallback onFilterTap;

  const SearchBar({
    Key? key,
    required this.onSearch,
    required this.searchController,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  hintText: AppLocalizations.of(context)!.search_server,
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: onFilterTap,
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CommunityHubPage(),
  ));
}
