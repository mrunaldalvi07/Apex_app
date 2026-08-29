import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dashboards/student_dashboard.dart';
import '../dashboards/faculty_dashboard.dart';
import '../dashboards/cr_dashboard.dart';
import '../dashboards/admin_dashboard.dart';
import '../services/fcm_service.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userFuture = user == null
        ? Future.error(StateError('User not found'))
        : FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    // Notification setup may contact Firebase and show a permission prompt.
    // It must not delay opening the dashboard.
    unawaited(_initializeNotifications());
  }

  Future<void> _initializeNotifications() async {
    try {
      await FCMService().initialize();
    } catch (_) {
      // Notifications are optional; authentication must still complete.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error;
          final message =
              error is FirebaseException && error.code == 'permission-denied'
              ? 'Firestore permission denied. Check your security rules.'
              : 'Could not load the user profile. Check your internet connection.';
          return Scaffold(body: Center(child: Text(message)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('User profile not found in Firestore.')),
          );
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('User data not found')),
          );
        }

        final role = data['role'];

        switch (role) {
          case 'student':
            return const StudentDashboard(uid: '');

          case 'faculty':
            return const FacultyDashboard(uid: '');

          case 'cr':
            return const CrDashboard();

          case 'admin':
            return const AdminDashboard();

          default:
            return const Scaffold(body: Center(child: Text("Invalid Role")));
        }
      },
    );
  }
}
