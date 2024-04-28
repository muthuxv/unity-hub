import 'package:flutter/material.dart';
import 'package:unity_hub/pages/intro_page.dart';
import 'package:unity_hub/pages/message_page.dart';
import 'package:unity_hub/pages/notification_page.dart';
import 'package:unity_hub/pages/friend_page.dart';
import '../components/bottom_navbar.dart';
import 'package:unity_hub/components/bottom_navbar.dart';
import 'server_page.dart';
import 'main_page.dart';
import 'security/auth_page.dart';

//import 'package:dio/dio.dart';

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
    const FriendPage(),
    const ServerPage(),
    const MessagePage(),
    const NotificationPage(),
  ];
/*
  Future<Map<String, dynamic>> _getUserData(String accessToken) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.github.com/user',
        options: Options(
          headers: {
            'Authorization': 'token $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // If user data is successfully retrieved, try to get email
        final emailResponse = await dio.get(
          'https://api.github.com/user/emails',
          options: Options(
            headers: {
              'Authorization': 'token $accessToken',
              'Accept': 'application/json',
            },
          ),
        );

        if (emailResponse.statusCode == 200) {
          // If email data is successfully retrieved, add it to user data
          final userData = response.data as Map<String, dynamic>;
          final emailData = emailResponse.data as List<dynamic>;
          if (emailData.isNotEmpty) {
            // Assuming the first email is the primary one
            userData['email'] = emailData.first['email'];
          }
          return userData;
        } else {
          throw Exception('Failed to retrieve email');
        }
      } else {
        throw Exception('Failed to retrieve user data');
      }
    } catch (e) {
      // Handle any errors that occur during the process
      print('Error: $e');
      rethrow; // Rethrow the error to be handled by the caller
    }
  }
*/
  Future<void> _checkToken() async {
    const storage = FlutterSecureStorage();
    final jwtToken = await storage.read(key: 'token');
    //final gitHubToken = await storage.read(key: 'gh_token');

    if (jwtToken == null) {
      // No tokens found, navigate to intro page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IntroPage()),
      );
    } else if (jwtToken != null) {
      // JWT token found, decode and verify if it's expired
      final bool isTokenExpired = JwtDecoder.isExpired(jwtToken);
      if (isTokenExpired) {
        // JWT token expired, navigate to intro page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroPage()),
        );
      } else {
        // JWT token valid, extract email and update state
        final decodedToken = JwtDecoder.decode(jwtToken);
        setState(() {
          email = decodedToken['sub']; // Update email variable with decoded email
        });
      }
    }
  }

  //logout
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
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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

