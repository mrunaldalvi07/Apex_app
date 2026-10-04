import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_screen.dart';
import '../screens/student_complaint_screen.dart';
import '../screens/student_live_attendance.dart';
import '../screens/view_classroom_screen.dart';
import '../screens/student_notice_screen.dart';
import '../widgets/dashboard_module_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required String uid});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return GridView(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isDesktop ? 250 : 320,
              mainAxisExtent: isDesktop ? 155 : 175,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            children: [
              DashboardModuleCard(
                icon: Icons.fact_check,
                title: 'Attendance\nIndicator',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentLiveAttendanceScreen(),
                    ),
                  );
                },
              ),
              DashboardModuleCard(
                icon: Icons.meeting_room,
                title: 'Classroom\nScheduler',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClassroomScreen(),
                    ),
                  );
                },
              ),
              DashboardModuleCard(
                icon: Icons.report_problem,
                title: 'Complaint\nManagement',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentComplaintScreen(),
                    ),
                  );
                },
              ),
              DashboardModuleCard(
                icon: Icons.campaign,
                title: 'Notice\nManagement',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentNoticeScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
