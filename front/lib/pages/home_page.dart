import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:unity_hub/pages/intro_page.dart';
import 'package:unity_hub/pages/group_page.dart';
import 'package:unity_hub/pages/notification_page.dart';
import 'package:unity_hub/pages/profile_page.dart';
import 'package:unity_hub/pages/communityhub_page.dart';
import 'package:dio/dio.dart';
import '../components/bottom_navbar.dart';
import '../providers/group_provider.dart';
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
  int _notificationCount = 0;

  Future<List<Map<String, dynamic>>> fetchFeatureStatuses() async {
    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get('$apiPath/features');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;

        List<Map<String, dynamic>> filteredFeatures = [];
        data.forEach((feature) {
          String featureName = feature['Name'];
          bool isEnabled = feature['Status'] == 'true';

          if (featureName == 'Serveurs') {
            filteredFeatures.add({'name': featureName, 'enabled': isEnabled});
          } else if (featureName == 'Messages') {
            filteredFeatures.add({'name': featureName, 'enabled': isEnabled});
          } else if (featureName == 'Notifications') {
            filteredFeatures.add({'name': featureName, 'enabled': isEnabled});
          } else if (featureName == 'Profil') {
            filteredFeatures.add({'name': featureName, 'enabled': isEnabled});
          }
        });

        return filteredFeatures;
      } else {
        print('Failed to load feature statuses');
        return [];
      }
    } catch (e) {
      print('Error fetching feature statuses: $e');
      return [];
    }
  }

  void navigateBottomNavBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _fetchNotifications(); // Fetch notifications on tab change
  }

  final List<Widget> _pages = [
    const ServerPage(),
    GroupPage(),
    const NotificationPage(),
    const ProfilePage(),
  ];

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

  Future<void> _fetchNotifications() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final responseInvitations = await Dio().get(
        '$apiPath/invitations/user/$userId',
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

      final responseFriendRequests = await Dio().get(
        '$apiPath/friends/pending/$userId',
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

      if (responseInvitations.statusCode == 200 && responseFriendRequests.statusCode == 200) {
        setState(() {
          _notificationCount = responseInvitations.data.length + responseFriendRequests.data.length;
        });
      } else {
        print('Failed to fetch notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
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
    Provider.of<GroupProvider>(context, listen: false).fetchGroups();
    _fetchNotifications(); // Fetch notifications on init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: MyBottomNavBar(
        onTabChange: (value) => navigateBottomNavBar(value),
        notificationCount: _notificationCount, // Pass notification count
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Icon(Icons.menu, color: Colors.deepPurple, size: 30.0),
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
              List<Map<String, dynamic>> features = snapshot.data!;
              bool serversEnabled = features.any((feature) => feature['name'] == 'Serveurs' && feature['enabled']);
              bool messagesEnabled = features.any((feature) => feature['name'] == 'Messages' && feature['enabled']);
              bool notificationsEnabled = features.any((feature) => feature['name'] == 'Notifications' && feature['enabled']);
              bool profileEnabled = features.any((feature) => feature['name'] == 'Profil' && feature['enabled']);

              Widget pageToDisplay;

              switch (_selectedIndex) {
                case 0:
                  pageToDisplay = serversEnabled ? const ServerPage() : const MaintenancePage();
                  break;
                case 1:
                  pageToDisplay = messagesEnabled ? const GroupPage() : const MaintenancePage();
                  break;
                case 2:
                  pageToDisplay = notificationsEnabled ? const NotificationPage() : const MaintenancePage();
                  break;
                case 3:
                  pageToDisplay = profileEnabled ? const ProfilePage() : const MaintenancePage();
                  break;
                default:
                  pageToDisplay = const ServerPage();
              }

              return pageToDisplay;
            }
          },
        ),
      ),
    );
  }
}