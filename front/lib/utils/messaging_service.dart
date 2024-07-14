import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class MessagingService {
  static String? fcmToken;

  static final MessagingService _instance = MessagingService._internal();

  factory MessagingService() => _instance;

  MessagingService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init(BuildContext context) async {
    NotificationSettings settings;
    try {
      settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await const FlutterSecureStorage().write(
        key: 'notificationPermission',
        value: 'granted',
      );
    } else {
      await const FlutterSecureStorage().write(
        key: 'notificationPermission',
        value: 'denied',
      );
    }

    debugPrint('User granted notifications permission: ${settings.authorizationStatus}');

    try {
      fcmToken = await _fcm.getToken();
      log('fcmToken: $fcmToken');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return;
    }

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await Dio().put(
        'https://unityhub.fr/fcm-token',
        data: {
          'fcmToken': fcmToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint('FCM token stored in the server: ${response.statusCode}');
    } catch (e) {
      debugPrint('Failed to store FCM token in the server: $e');
    }

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      final userId = JwtDecoder.decode(token!)['jti'];
      final response = await Dio().get(
        'https://unityhub.fr/users/$userId/channels',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final channels = response.data as List<dynamic>;
        for (final channel in channels) {
          final channelId = channel['ID'];
          await _fcm.subscribeToTopic('channel-$channelId');
        }
      }
    } catch (e) {
      debugPrint('Failed to subscribe to channels: $e');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('onMessage: ${message.notification!.title.toString()}');
      final notification = message.notification;
      final android = message.notification!.android;

      if (notification != null && android != null) {
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        const initializationSettings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        );
        flutterLocalNotificationsPlugin.initialize(initializationSettings);

        const androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(''),
        );

        const platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
        flutterLocalNotificationsPlugin.show(
          0,
          notification.title,
          notification.body,
          platformChannelSpecifics,
        );
      }
    });

    // Handling a notification click event when the app is in the terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationClick(context, message);
      }
    });

    // Handling a notification click event when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: ${message.notification!.title.toString()}');
      _handleNotificationClick(context, message);
    });
  }

  Future generateAccessToken() async {

    const serviceAccountPath = 'service-account.json';

    final content = await rootBundle.loadString(serviceAccountPath);

    final credentials = ServiceAccountCredentials.fromJson(jsonDecode(content));

    final accessScopes = ["https://www.googleapis.com/auth/firebase.messaging"];

    final client = await clientViaServiceAccount(credentials, accessScopes);

    final accessToken = client.credentials.accessToken.data;

    return accessToken;
  }

  // Handling a notification click event by navigating to the specified screen
  void _handleNotificationClick(BuildContext context, RemoteMessage message) {
    final notificationData = message.data;

    if (notificationData.containsKey('screen')) {
      final screen = notificationData['screen'];
      Navigator.of(context).pushNamed(screen);
    }
  }
}

// Handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint('Handling a background message: ${message.notification!.title}');
}