import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dashboards/student_dashboard.dart';
import '../dashboards/faculty_dashboard.dart';
import '../dashboards/cr_dashboard.dart';
import '../dashboards/admin_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not found")),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>;

        final role = data['role'];

        switch (role) {
          case 'student':
            return const StudentDashboard(uid: '',);

          case 'faculty':
            return const FacultyDashboard(uid: '',);

          case 'cr':
            return const CrDashboard();

          case 'admin':
            return const AdminDashboard();

          default:
            return const Scaffold(
              body: Center(
                child: Text("Invalid Role"),
              ),
            );
        }
      },
    );
  }
}