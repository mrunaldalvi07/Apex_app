import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../screens/attendance_management_screen.dart';
import '../screens/classroom_management_screen.dart';
import '../screens/complaint_management_screen.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key, required String uid});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Widget dashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 55, color: color),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [

            dashboardCard(
                context,
                Icons.report_problem,
                "Complaint\nManagement",
                Colors.red,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ComplaintManagementScreen(),
                    ),
                  );
                },
              ),

            dashboardCard(
  context,
  Icons.fact_check,
  "Attendance\nIndicator",
  Colors.green,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AttendanceManagementScreen(),
      ),
    );
  },
),
            dashboardCard(
  context,
  Icons.meeting_room,
  "Classroom\nScheduler",
  Colors.orange,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClassroomManagementScreen(),
      ),
    );
  },
),

          
          ],
        ),
      ),
    );
  }
}