import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {

  final FirebaseMessaging messaging =
      FirebaseMessaging.instance;

  Future<void> initialize() async {

    await messaging.requestPermission();

    final token =
        await messaging.getToken();

    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid != null && token != null) {

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        "fcmToken": token,
      });
    }
  }
}