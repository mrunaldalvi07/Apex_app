import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

import 'firebase_options.dart';
import 'auth/login_screen.dart';
import 'auth/role_router.dart';

final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    fln.FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create Android Notification Channel
  const fln.AndroidNotificationChannel channel = fln.AndroidNotificationChannel(
    'attendance_channel',
    'Attendance Notifications',
    description: 'Attendance alerts and warnings',
    importance: fln.Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Initialize Local Notifications
  const fln.InitializationSettings initializationSettings =
      fln.InitializationSettings(
        android: fln.AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse:
        (fln.NotificationResponse notificationResponse) async {},
  );

  runApp(const ApexApp());
}

class ApexApp extends StatelessWidget {
  const ApexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APEX',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      scrollBehavior: const ApexScrollBehavior(),
      home: const AuthWrapper(),
      routes: {'/login': (context) => const LoginScreen()},
    );
  }
}

/// Shows a scrollbar whenever a list, grid, or form is scrolled. This gives
/// users a clear indication that more content is available below.
class ApexScrollBehavior extends MaterialScrollBehavior {
  const ApexScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return Scrollbar(controller: details.controller, child: child);
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
            body: Center(child: CircularProgressIndicator()),
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
