import 'package:flutter/material.dart';
import '../services/attendance_export_service.dart';

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

  final TextEditingController courseController =
      TextEditingController();

  bool loading = false;

  final List<String> branches = [
    "IT",
    "CM",
  ];

  final List<String> years = [
    "1",
    "2",
    "3",
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
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Attendance Sheet Generated",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
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
        title: const Text(
          "Attendance Reports",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedBranch,
              decoration:
                  const InputDecoration(
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
              initialValue: selectedYear,
              decoration:
                  const InputDecoration(
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
              decoration:
                  const InputDecoration(
                labelText: "Course",
                hintText:
                    "JAVA, DBMS, PYTHON",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.download,
                      ),
                label: Text(
                  loading
                      ? "Generating..."
                      : "Generate Excel Sheet",
                ),
                onPressed:
                    loading ? null : generateSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}