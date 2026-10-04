import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/complaint_list_screen.dart';
import '../screens/attendance_management_screen.dart';
import '../screens/classroom_management_screen.dart';
import '../screens/cr_notice_screen.dart';
import '../widgets/dashboard_module_card.dart';

class CrDashboard extends StatelessWidget {
  const CrDashboard({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // AuthWrapper reacts to sign-out and displays LoginScreen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CR Dashboard"),
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
                    builder: (_) => const AttendanceManagementScreen(),
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
                    builder: (_) => const ClassroomManagementScreen(),
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
                    builder: (_) => const ComplaintListScreen(
                      showOnlyMyComplaints: false,
                      isFaculty: false,
                    ),
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
                  MaterialPageRoute(builder: (_) => const CRNoticeScreen()),
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
