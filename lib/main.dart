import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'auth/login_screen.dart';
import 'auth/role_router.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request Notification Permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Create Android Notification Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'attendance_channel',
    'Attendance Notifications',
    description: 'Attendance alerts and warnings',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize Local Notifications
  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {},
  );

  // Listen for foreground FCM messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (message.notification != null) {
      await flutterLocalNotificationsPlugin.show(
        id: 0,
        title: message.notification!.title ?? "Notification",
        body: message.notification!.body ?? "",
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'attendance_channel',
            'Attendance Notifications',
            channelDescription: 'Attendance alerts and warnings',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  runApp(const ApexApp());
}

class ApexApp extends StatelessWidget {
  const ApexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APEX',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const RoleRouter();
        }

        return const LoginScreen();
      },
    );
  }
}