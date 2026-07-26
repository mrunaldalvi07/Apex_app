import 'package:flutter/material.dart';

import '../services/attendance_export_service.dart';
import 'attendance_summary_screen.dart';
import 'detention_list_screen.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends State<AttendanceReportScreen> {
  String selectedBranch = "IT";
  String selectedYear = "1";
  String selectedMonth = "January";

  bool loading = false;

  final TextEditingController courseController =
      TextEditingController();

  final List<String> branches = [
    "IT",
    "CM",
  ];

  final List<String> years = [
    "1",
    "2",
    "3",
  ];

  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  Future<void> generateSheet() async {
    try {
      final course =
          courseController.text.trim().toUpperCase();

      if (course.isEmpty) {
        throw Exception("Enter Course Name");
      }

      setState(() {
        loading = true;
      });

      await AttendanceExportService()
          .exportAttendanceSheet(
        branch: selectedBranch,
        year: selectedYear,
        course: course,
        month: selectedMonth,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Attendance Excel Generated",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget buildButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    courseController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Reports"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedBranch,
              decoration: const InputDecoration(
                labelText: "Branch",
                border: OutlineInputBorder(),
              ),
              items: branches
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedBranch = value!;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedYear,
              decoration: const InputDecoration(
                labelText: "Year",
                border: OutlineInputBorder(),
              ),
              items: years
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text("$e Year"),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value!;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: courseController,
              textCapitalization:
                  TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Course",
                hintText: "JAVA, DBMS, PYTHON",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedMonth,
              decoration: const InputDecoration(
                labelText: "Month",
                border: OutlineInputBorder(),
              ),
              items: months
                  .map(
                    (month) => DropdownMenuItem(
                      value: month,
                      child: Text(month),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            buildButton(
              icon: Icons.table_chart,
              text: "Monthly Attendance Sheet",
              onPressed: loading ? () {} : generateSheet,
            ),

            const SizedBox(height: 12),

            buildButton(
              icon: Icons.analytics,
              text: "Attendance Summary",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceSummaryScreen(
                      branch: selectedBranch,
                      year: selectedYear,
                      course: courseController.text
                          .trim()
                          .toUpperCase(),
                      month: selectedMonth,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            buildButton(
              icon: Icons.warning_amber,
              text: "Detention List",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetentionListScreen(
                      branch: selectedBranch,
                      year: selectedYear,
                      course: courseController.text
                          .trim()
                          .toUpperCase(),
                      month: selectedMonth,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            buildButton(
              icon: Icons.notifications_active,
              text: "Notify Detained Students",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Open Detention List and tap Notify",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            buildButton(
              icon: Icons.download,
              text: loading
                  ? "Generating..."
                  : "Export Excel",
              onPressed: loading ? () {} : generateSheet,
            ),

            const SizedBox(height: 12),

            buildButton(
              icon: Icons.picture_as_pdf,
              text: "Export PDF",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "PDF Export will be added next",
                    ),
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