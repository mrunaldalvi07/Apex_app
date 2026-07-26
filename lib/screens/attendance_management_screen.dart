import 'package:flutter/material.dart';

import 'attendance_report_screen.dart';
import 'faculty_live_attendance_screen.dart';

class AttendanceManagementScreen extends StatelessWidget {
  const AttendanceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Management"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_fill),
                label: const Text(
                  "Start Attendance Session",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const FacultyLiveAttendanceScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.analytics),
                label: const Text(
                  "Attendance Reports",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AttendanceReportScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}