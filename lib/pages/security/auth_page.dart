import 'package:flutter/material.dart';
import '../home_page.dart';
import '../intro_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<void> checkToken(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IntroPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: checkToken(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const HomePage();
          } else {
            return const IntroPage();
          }
        });
  }
}
