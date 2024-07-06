import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:unity_hub/components/channels_panel.dart';
import 'package:unity_hub/pages/add_server_page.dart';
import 'package:unity_hub/pages/server_members_list.dart';
import 'package:unity_hub/pages/server_settings_page.dart';
import 'package:unity_hub/pages/add_channel_page.dart';
import 'package:unity_hub/pages/invitations/send_invitation_page.dart';
import 'package:unity_hub/utils/websocket_service.dart';

class ServerPage extends StatefulWidget {
  final int serverId;
  const ServerPage({super.key, this.serverId = 0});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  bool _isLoading = false;
  List _servers = [];
  Map _selectedServer = {};
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _getUserServers();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  Future<void> _getUserServers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      final decodedToken = JwtDecoder.decode(token!);
      final userId = decodedToken['jti'];

      final response = await Dio().get(
        'http://10.0.2.2:8080/servers/users/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _servers = response.data['data'];
          if (widget.serverId != 0) {
            _selectedServer = _servers.firstWhere((server) => server['ID'] == widget.serverId, orElse: () => {});
          } else if (_servers.isNotEmpty) {
            _selectedServer = _servers[0];
          }
          if (_selectedServer.isNotEmpty) {
            _connectWebSocket(_selectedServer['ID']);
          }
        });
      } else {
        _showErrorDialog(response.data['message']);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _connectWebSocket(int serverId) {
    _webSocketService.disconnect();
    _webSocketService.connect('ws://10.0.2.2:8080/ws/servers/$serverId');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
              colors: List<Color>.generate(4, (_) => Colors.black.withOpacity(0.5)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 70.0),
            child: _servers.isEmpty
                ? _buildEmptyServerView()
                : _buildServerView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyServerView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Pour commencer, rejoins un serveur ou crée le tien!',
              style: TextStyle(color: Colors.white, fontSize: 20.0),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
          const SizedBox(height: 10.0),
          ElevatedButton(
            onPressed: () => _navigateToAddServerPage(),
            child: const Text('Ajouter un serveur'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerView(BuildContext context) {
    return Column(
      children: [
        _buildServerHeader(),
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildServerDetails(context),
                    const SizedBox(height: 10.0),
                    _buildActions(context),
                    const SizedBox(height: 10.0),
                    ChannelsPanel(
                      key: ChannelsPanel.globalKey,
                      serverId: _selectedServer['ID'],
                      webSocketService: _webSocketService,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildServerHeader() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: GestureDetector(
            onTap: () => _navigateToAddServerPage(),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 4, style: BorderStyle.solid, color: Colors.pink),
              ),
              child: const Icon(Icons.add, size: 50, color: Colors.white),
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
                String filename = _servers[index]['Media']['FileName'];
                String imageUrl =
                    'http://10.0.2.2:8080/uploads/$filename?rand=${DateTime.now().millisecondsSinceEpoch}';

                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedServer = _servers[index];
                      });
                      _connectWebSocket(_servers[index]['ID']);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple, Colors.pink],
                        ),
                        color: _selectedServer['ID'] == _servers[index]['ID']
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(imageUrl),
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
    );
  }

  Widget _buildServerDetails(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            _selectedServer['Name'] != null
                ? (_selectedServer['Name'].length > 50
                ? _selectedServer['Name'] + '...'
                : _selectedServer['Name'])
                : 'No server selected',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: <Color>[Colors.blue, Colors.purple, Colors.pink],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
            ),
            softWrap: true,
          ),
        ),
        IconButton(
          onPressed: () => _showServerOptionsModal(context),
          icon: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: <Color>[Colors.blue, Colors.purple, Colors.pink],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: const Icon(Icons.arrow_forward_ios_outlined, size: 25.0),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _navigateToAddChannelPage(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            child: Row(
              children: [
                Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
                const SizedBox(width: 5),
                Text(
                  'Ajouter un channel',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _navigateToSendInvitationPage(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(width: 2.0, color: Theme.of(context).primaryColor),
            ),
            child: Row(
              children: [
                Icon(Icons.supervised_user_circle_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 5),
                Text(
                  'Invite des amis',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToAddServerPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServerPage(onServerAdded: _onServerAdded),
      ),
    );

    if (result != null) {
      setState(() {
        _servers.add(result);
        _selectedServer = result;
        _connectWebSocket(result['ID']);
      });
    }
  }

  Future<void> _navigateToAddChannelPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChannelPage(
          serverId: _selectedServer['ID'],
          webSocketService: _webSocketService,
        ),
      ),
    );

    if (result != null) {
      print("Channel added: $result");
      _webSocketService.send({
        'type': 'new_channel',
        'channel': result.data,
      });
      ChannelsPanel.globalKey.currentState?.onChannelAdded(result);
    }
  }

  Future<void> _navigateToSendInvitationPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendInvitationPage(
          serverId: _selectedServer['ID'],
        ),
      ),
    );
  }

  void _showServerOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      'http://10.0.2.2:8080/uploads/${_selectedServer['Media']['FileName']}?rand=${DateTime.now().millisecondsSinceEpoch}',
                    ),
                  ),
                  title: Text(
                    _selectedServer['Name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: <Color>[Colors.blue, Colors.purple, Colors.pink],
                        ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                    ),
                  ),
                ),
                const Divider(thickness: 1.0, indent: 100.0, endIndent: 100.0),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text(
                    'Paramètres du serveur',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServerSettingsPage(
                          serverId: _selectedServer['ID'],
                          serverName: _selectedServer['Name'],
                          serverAvatar: _selectedServer['Media']['FileName'],
                          serverVisibility: _selectedServer['Visibility'],
                        ),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _selectedServer['Media']['FileName'] = result['avatar'];
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text(
                    'Liste des membres',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServerMembersList(
                          serverId: _selectedServer['ID'],
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.exit_to_app,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Quitter le serveur',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  onTap: () {
                    print('Leave server');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onServerAdded(Map newServer) {
    setState(() {
      _servers.add(newServer);
      _selectedServer = newServer;
      _connectWebSocket(newServer['ID']);
    });
  }
}