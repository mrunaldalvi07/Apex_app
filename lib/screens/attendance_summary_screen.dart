import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/attendance_summary_model.dart';
import '../../services/attendance_export_service.dart';

extension AttendanceExportServiceSummary on AttendanceExportService {
  Future<List<AttendanceSummaryModel>> getAttendanceSummary({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {
    final students = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .get();

    final sessions = await firestore
        .collection('live_sessions')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .where('course', isEqualTo: course)
        .where('status', isEqualTo: 'ended')
        .get();

    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> sessionDocs = [];

    for (final session in sessions.docs) {
      final Timestamp? timestamp =
          session.data()['createdAt'] as Timestamp?;

      if (timestamp == null) continue;

      final sessionMonth = monthNames[timestamp.toDate().month];
      if (sessionMonth == month) {
        sessionDocs.add(session);
      }
    }

    sessionDocs.sort((a, b) {
      final Timestamp ta = a['createdAt'];
      final Timestamp tb = b['createdAt'];
      return ta.toDate().compareTo(tb.toDate());
    });

    final studentDocs = students.docs.toList();

    studentDocs.sort((a, b) {
      final rollA = (a['rollNo'] ?? '').toString();
      final rollB = (b['rollNo'] ?? '').toString();
      return rollA.compareTo(rollB);
    });

    final List<AttendanceSummaryModel> summaryList = [];

    for (final student in studentDocs) {
      final studentData = student.data();

      int present = 0;
      int absent = 0;

      for (final session in sessionDocs) {
        final attendanceDoc = await firestore
            .collection('attendance')
            .doc(session.id)
            .collection('students')
            .doc(student.id)
            .get();

        if (attendanceDoc.exists &&
            attendanceDoc.data()?['status'] == 'Present') {
          present++;
        } else {
          absent++;
        }
      }

      final int totalClasses = sessionDocs.length;
      final double attendancePercentage =
          totalClasses > 0 ? (present / totalClasses) * 100 : 0.0;

      summaryList.add(
        AttendanceSummaryModel(
          studentId: student.id,
          rollNo: (studentData['rollNo'] ?? '').toString(),
          studentName: (studentData['name'] ?? '').toString(),
          present: present,
          absent: absent,
          totalClasses: totalClasses,
          attendancePercentage: attendancePercentage,
          status: attendancePercentage >= 75 ? 'Regular' : 'Detained',
        ),
      );
    }

    return summaryList;
  }
}

class AttendanceSummaryScreen extends StatefulWidget {
  final String branch;
  final String year;
  final String course;
  final String month;

  const AttendanceSummaryScreen({
    super.key,
    required this.branch,
    required this.year,
    required this.course,
    required this.month,
  });

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState
    extends State<AttendanceSummaryScreen> {
  bool loading = true;

  List<AttendanceSummaryModel> summary = [];

  int totalStudents = 0;
  int regularStudents = 0;
  int detainedStudents = 0;

  double averageAttendance = 0;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  Future<void> loadSummary() async {
    setState(() {
      loading = true;
    });

    try {
      summary = await AttendanceExportService()
          .getAttendanceSummary(
        branch: widget.branch,
        year: widget.year,
        course: widget.course,
        month: widget.month,
      );

      totalStudents = summary.length;

      regularStudents = summary
          .where((e) => !e.detained)
          .length;

      detainedStudents = summary
          .where((e) => e.detained)
          .length;

      if (summary.isNotEmpty) {
        averageAttendance = summary
                .map((e) => e.attendancePercentage)
                .reduce((a, b) => a + b) /
            summary.length;
      } else {
        averageAttendance = 0;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Widget buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance Summary",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              children: [

                buildInfoCard(
                  "Students",
                  totalStudents.toString(),
                  Icons.people,
                  Colors.blue,
                ),

                const SizedBox(width: 10),

                buildInfoCard(
                  "Regular",
                  regularStudents.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [

                buildInfoCard(
                  "Detained",
                  detainedStudents.toString(),
                  Icons.warning,
                  Colors.red,
                ),

                const SizedBox(width: 10),

                buildInfoCard(
                  "Average %",
                  averageAttendance
                      .toStringAsFixed(1),
                  Icons.analytics,
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 20),
            Expanded(
  child: summary.isEmpty
      ? const Center(
          child: Text(
            "No Attendance Data Available",
            style: TextStyle(fontSize: 16),
          ),
        )
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(
                Colors.blue.shade100,
              ),
              columns: const [
                DataColumn(
                  label: Text("Roll No"),
                ),
                DataColumn(
                  label: Text("Name"),
                ),
                DataColumn(
                  numeric: true,
                  label: Text("Present"),
                ),
                DataColumn(
                  numeric: true,
                  label: Text("Absent"),
                ),
                DataColumn(
                  numeric: true,
                  label: Text("%"),
                ),
                DataColumn(
                  label: Text("Status"),
                ),
              ],
              rows: summary.map((student) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(student.rollNo),
                    ),
                    DataCell(
                      Text(student.studentName),
                    ),
                    DataCell(
                      Text(student.present.toString()),
                    ),
                    DataCell(
                      Text(student.absent.toString()),
                    ),
                    DataCell(
                      Text(
                        "${student.attendancePercentage.toStringAsFixed(1)}%",
                      ),
                    ),
                    DataCell(
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: student.detained
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          student.detained
                              ? "Detained"
                              : "Regular",
                          style: TextStyle(
                            color: student.detained
                                ? Colors.red
                                : Colors.green,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
),
          ],
        ),
      ),
    );
  }
}