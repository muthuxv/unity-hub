import 'package:flutter/material.dart';
import 'package:unity_hub/pages/intro_page.dart';
import 'package:unity_hub/pages/message_page.dart';
import 'package:unity_hub/pages/notification_page.dart';
import 'package:unity_hub/pages/profile_page.dart';
import 'package:unity_hub/pages/communityhub_page.dart';
import 'package:dio/dio.dart';
import '../components/bottom_navbar.dart';
import 'server_page.dart';
import 'security/auth_page.dart';
import 'package:unity_hub/utils/messaging_service.dart';
import 'package:unity_hub/pages/maintenance_page.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MessagingService messagingService = MessagingService();
  int _selectedIndex = 0;
  String email = '';

  Future<List<Map<String, dynamic>>> fetchFeatureStatuses() async {
    try {
      final response = await Dio().get('http://10.0.2.2:8080/features');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return List<Map<String, dynamic>>.from(data);
      } else {
        // Handle unexpected status codes or errors here
        print('Failed to load feature statuses');
        return [];
      }
    } catch (e) {
      // Handle Dio errors or network errors here
      print('Error fetching feature statuses: $e');
      return [];
    }
  }

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
      const CommunityHubPage(),
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
                DrawerHeader(child: Image.asset(
                  'lib/images/unitylog.png',
                  width: 100,
                ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 25.0, top: 25.0),
                  child: ListTile(
                    leading: const Icon(
                        Icons.home),
                    title: const Text("CommunityHub"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CommunityHubPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
              child: ListTile(
                leading: const Icon(
                    Icons.logout),
                title: Text(AppLocalizations.of(context)!.logout),
                onTap: () {
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchFeatureStatuses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No data available');
            } else {
              // Process feature statuses and decide which page to show
              bool serversEnabled = snapshot.data![0]['Status'] == 'true';
              bool communityHubEnabled = snapshot.data![1]['Status'] == 'true';
              bool notificationsEnabled = snapshot.data![2]['Status'] == 'true';
              bool profileEnabled = snapshot.data![3]['Status'] == 'true';

              Widget pageToDisplay;

              switch (_selectedIndex) {
                case 0:
                  pageToDisplay = serversEnabled ? ServerPage() : const MaintenancePage();
                  break;
                case 1:
                  pageToDisplay = communityHubEnabled ? const CommunityHubPage() : const MaintenancePage();
                  break;
                case 2:
                  pageToDisplay = notificationsEnabled ? const NotificationPage() : const MaintenancePage();
                  break;
                case 3:
                  pageToDisplay = profileEnabled ? const ProfilePage() : const MaintenancePage();
                  break;
                default:
                  pageToDisplay = ServerPage();
              }

              return pageToDisplay;
            }
          },
        ),
      ),
    );
  }
}