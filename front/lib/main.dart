import 'package:flutter/material.dart';
import 'pages/security/auth_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

import 'package:unity_hub/theme.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    TextTheme myTextTheme = ThemeData.light().textTheme;
    MaterialTheme myTheme = MaterialTheme(myTextTheme);
    return MaterialApp(
      title: 'Unity Hub',
      theme: myTheme.lightMediumContrast(),
      home: const AuthPage(),
    );
  }
}