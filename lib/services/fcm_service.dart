import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();

      await _saveToken(token);

      // Save a new token automatically if Firebase refreshes it.
      messaging.onTokenRefresh.listen((newToken) async {
        await _saveToken(newToken);
      });
    } catch (e) {
      // FCM must never prevent the user from logging in.
      print("FCM initialization error: $e");
    }
  }

  Future<void> _saveToken(String? token) async {
    try {
      if (token == null || token.isEmpty) return;

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(
        {
          "fcmToken": token,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // Do not block login if FCM token saving fails.
      print("FCM token save error: $e");
    }
  }
}