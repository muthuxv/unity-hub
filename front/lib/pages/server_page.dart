import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
//import 'package:unity_hub/components/members_panel.dart';
import 'package:unity_hub/components/channels_panel.dart';


class ServerPage extends StatefulWidget {
  const ServerPage({Key? key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  bool _isLoading = false;
  List _servers = [];
  Map _selectedServer = {};

  void _getUserServers() async {
    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    final response = await Dio().get(
      'http://10.0.2.2:8080/servers/users/$userId',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        _servers = response.data['data'];
        _selectedServer = _servers.isNotEmpty ? _servers[0] : {};
        _isLoading = false;
      });
      print('Servers: $_servers');
    } else {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.data['message']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserServers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/wall1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 70.0),
            child: _servers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Aucun serveur trouvé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed: () {
                      print('Add server');
                    },
                    child: const Text('Rejoindre un serveur'),
                  ),
                ],
              ),
            )
                : Column(
              children: [
                Row(
                  children: [
                      Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: GestureDetector(
                        onTap: () {
                          print('Add server');
                        },
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 4,
                              style: BorderStyle.solid,
                              color: Colors.pink
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              print('Add server');
                            },
                            child: const Icon(
                              Icons.add,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _servers.length,
                          itemBuilder: (context, index) {
                              String filename =
                              _servers[index]['Media']
                              ['FileName'];
                              String imageUrl =
                                  'http://10.0.2.2:8080/uploads/$filename';

                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: GestureDetector(
                                  onTap: () {
                                    print(_servers[index]);
                                    setState(() {
                                      _selectedServer =
                                      _servers[index];
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.blue,
                                          Colors.purple,
                                          Colors.pink,
                                        ],
                                      ),
                                      color: _selectedServer['ID'] ==
                                          _servers[index]['ID']
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          imageUrl),
                                      radius: 50,
                                    ),
                                  ),
                                ),
                              );
                            },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10.0),
                                  child: Text(
                                    _selectedServer['Name'] != null
                                        ? (_selectedServer['Name'].length > 50
                                        ? _selectedServer['Name'].substring(0, 30) + '...' // Trim the name if it's longer than 20 characters
                                        : _selectedServer['Name'])
                                        : 'No server selected',
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      //gradient text
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
                                    softWrap: true,
                                  ),

                                ),
                              ),
                              const SizedBox(width: 10.0),
                              GestureDetector(
                                onTap: () {
                                  print('Invite');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(10.0),
                                    border: Border.all(
                                      width: 2.0,
                                      color:
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: Theme.of(context)
                                            .primaryColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Invite des amis',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          //channels panel
                          ChannelsPanel(
                            serverId: _selectedServer['ID'],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
