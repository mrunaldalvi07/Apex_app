import 'package:flutter/material.dart';

import '../models/attendance_summary_model.dart';
import '../widgets/attendance_ui.dart';
import '../services/attendance_summary_service.dart';

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
  final AttendanceSummaryService _summaryService = AttendanceSummaryService();

  bool loading = true;

  List<AttendanceSummaryModel> summary = [];

  int totalStudents = 0;
  int regularStudents = 0;
  int detainedStudents = 0;

  double averageAttendance = 0;

  static const List<String> months = [
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

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  Future<List<AttendanceSummaryModel>> _getSummary() {
    return _summaryService.getAttendanceSummary(
      branch: widget.branch,
      year: widget.year,
      course: widget.course,
      month: widget.month,
    );
  }

  Future<void> loadSummary() async {
    setState(() => loading = true);

    try {
      summary = await _getSummary();

      totalStudents = summary.length;

      final activeStudents = summary
          .where((student) => student.totalClasses > 0)
          .toList();

      regularStudents = activeStudents
          .where((student) => student.attendancePercentage >= 75)
          .length;

      detainedStudents = activeStudents
          .where((student) => student.attendancePercentage < 75)
          .length;

      averageAttendance = activeStudents.isEmpty
          ? 0
          : activeStudents
                  .map((student) => student.attendancePercentage)
                  .reduce((a, b) => a + b) /
              activeStudents.length;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor:
            AttendanceUI.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AttendanceUI.primaryBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AttendanceUI.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
            AttendanceUI.backButton(context),
        title: Text(
          'Attendance Summary',
          style: AttendanceUI.title,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loadSummary,
            icon: const Icon(
              Icons.refresh,
              color: AttendanceUI.darkNavy,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _summaryHeader(),

            const SizedBox(height: 15),

            Row(
              children: [
                _stat(
                  'Students',
                  '$totalStudents',
                  Icons.groups,
                  AttendanceUI.primaryBlue,
                ),
                const SizedBox(width: 8),
                _stat(
                  'Regular',
                  '$regularStudents',
                  Icons.check_circle,
                  AttendanceUI.green,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                _stat(
                  'Detained',
                  '$detainedStudents',
                  Icons.warning_amber,
                  AttendanceUI.orange,
                ),
                const SizedBox(width: 8),
                _stat(
                  'Average',
                  '${averageAttendance.toStringAsFixed(1)}%',
                  Icons.analytics,
                  AttendanceUI.cyan,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Student Attendance',
              style: AttendanceUI.sectionTitle,
            ),

            const SizedBox(height: 10),

            if (summary.isEmpty)
              Container(
                padding:
                    const EdgeInsets.all(30),
                decoration:
                    AttendanceUI.cardDecoration(),
                child: const Center(
                  child: Text(
                    'No attendance data available.',
                  ),
                ),
              )
            else
              ...summary.asMap().entries.map(
                (entry) {
                  return _studentCard(
                    entry.key + 1,
                    entry.value,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AttendanceUI.darkNavy,
            AttendanceUI.primaryNavy,
          ],
        ),
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Overview',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.course} • ${widget.branch} • ${widget.year} Year',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            '${averageAttendance.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Average Attendance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration:
            AttendanceUI.cardDecoration(),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 23,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color:
                          AttendanceUI.darkNavy,
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color:
                          AttendanceUI.textGrey,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentCard(
    int index,
    AttendanceSummaryModel student,
  ) {
    final detained =
        student.attendancePercentage < 75;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration:
          AttendanceUI.cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor:
                AttendanceUI.primaryBlue
                    .withValues(alpha: .10),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: AttendanceUI.primaryBlue,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: const TextStyle(
                    color:
                        AttendanceUI.darkNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Roll No. ${student.rollNo}',
                  style: AttendanceUI.body,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '${student.attendancePercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: detained
                      ? AttendanceUI.red
                      : AttendanceUI.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detained
                    ? 'Detained'
                    : 'Regular',
                style: TextStyle(
                  color: detained
                      ? AttendanceUI.red
                      : AttendanceUI.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}