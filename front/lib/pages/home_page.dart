import 'package:flutter/material.dart';
import 'package:unity_hub/pages/intro_page.dart';
import 'package:unity_hub/pages/message_page.dart';
import 'package:unity_hub/pages/notification_page.dart';
import 'package:unity_hub/pages/profile_page.dart';
import 'package:unity_hub/pages/communityhub_page.dart';
import '../components/bottom_navbar.dart';
import 'server_page.dart';
import 'security/auth_page.dart';
import 'package:unity_hub/utils/messaging_service.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MessagingService messagingService = MessagingService();
  int _selectedIndex = 0;
  String email = '';

  void navigateBottomNavBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
  }

  late final List<Widget> _pages;

  Future<void> _checkToken() async {
    const storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');

    if (jwtToken == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IntroPage()),
      );
    } else if (jwtToken != null) {
      final bool isTokenExpired = JwtDecoder.isExpired(jwtToken);
      if (isTokenExpired) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroPage()),
        );
      } else {
        final decodedToken = JwtDecoder.decode(jwtToken);
        setState(() {
          email = decodedToken['sub'];
        });
      }
    }
  }

  void _logout() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkToken();
    messagingService.init(context);

    _pages = [
      const ServerPage(),
      const MessagePage(),
      const NotificationPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: MyBottomNavBar(
        onTabChange: (value) => navigateBottomNavBar(value),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Icon(Icons.menu, color: Colors.white, size: 30.0),
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                DrawerHeader(
                  child: Image.asset(
                    'lib/images/unitylog.png',
                    width: 100,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25.0, top: 25.0),
                  child: ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('CommunityHub'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CommunityHubPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Se déconnecter'),
                onTap: () {
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
    );
  }
}

