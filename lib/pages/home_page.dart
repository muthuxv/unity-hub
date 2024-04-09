import 'package:flutter/material.dart';
import 'package:unity_hub/pages/message_page.dart';
import 'package:unity_hub/pages/notification_page.dart';
import '../components/bottom_navbar.dart';
import 'server_page.dart';
import 'shop_page.dart';
import 'security/login_page.dart';
import 'security/auth_page.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String email = '';

  void navigateBottomNavBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
  }

  final List<Widget> _pages = [
    const ShopPage(),
    const ServerPage(),
    const MessagePage(),
    const NotificationPage(),
  ];


  Future<void> checkToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    } else {
      final bool isTokenExpired = JwtDecoder.isExpired(token);
      if (isTokenExpired) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      } else {
        final decodedToken = JwtDecoder.decode(token);
        setState(() {
          email = decodedToken['sub']; // Update email variable with decoded email
        });
      }
    }
  }


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[300],
      bottomNavigationBar: MyBottomNavBar(
        onTabChange: (value) => navigateBottomNavBar(value),
      ),
      appBar: AppBar(
        title: Text(email.isNotEmpty ? email : ''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Icon(Icons.menu),
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                DrawerHeader(child: Image.asset(
                  'lib/images/unitylog.png',
                  color: Colors.white,
                  width: 100,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25.0),
                child: ListTile(
                  leading: const Icon(
                      Icons.home,
                      color: Colors.white),
                  title: const Text(
                      'Home',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: const Icon(
                      Icons.info,
                      color: Colors.white),
                  title: const Text(
                      'About',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
              child: ListTile(
                leading: const Icon(
                    Icons.logout,
                    color: Colors.white),
                title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  const storage = FlutterSecureStorage();
                  storage.delete(key: 'token');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                  );
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

