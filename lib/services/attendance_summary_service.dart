import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_summary_model.dart';

class AttendanceSummaryService {
  final FirebaseFirestore firestore;

  AttendanceSummaryService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  static const _months = [
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _sessions({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {
    final snapshot = await firestore
        .collection('live_sessions')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .where('course', isEqualTo: course.toUpperCase())
        .where('status', isEqualTo: 'ended')
        .get();

    final sessions = snapshot.docs.where((doc) {
      final value = doc.data()['createdAt'];
      if (value is! Timestamp) return false;
      return _months[value.toDate().month] == month;
    }).toList();

    sessions.sort((a, b) {
      final ta = a.data()['createdAt'] as Timestamp;
      final tb = b.data()['createdAt'] as Timestamp;
      return ta.compareTo(tb);
    });

    return sessions;
  }

  Future<List<AttendanceSummaryModel>> getAttendanceSummary({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {
    final studentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .get();

    final sessions = await _sessions(
      branch: branch,
      year: year,
      course: course,
      month: month,
    );

    // Read one attendance subcollection per session instead of one document
    // per student per session. This avoids the old N x M read explosion.
    final attendanceBySession = <String, Map<String, String>>{};

    for (final session in sessions) {
      final attendanceSnapshot = await firestore
          .collection('attendance')
          .doc(session.id)
          .collection('students')
          .get();

      attendanceBySession[session.id] = {
        for (final doc in attendanceSnapshot.docs)
          doc.id: (doc.data()['status'] ?? 'Absent').toString(),
      };
    }

    final students = studentsSnapshot.docs.toList();
    students.sort((a, b) {
      final ra = (a.data()['rollNo'] ?? '').toString();
      final rb = (b.data()['rollNo'] ?? '').toString();

      final na = int.tryParse(ra);
      final nb = int.tryParse(rb);
      if (na != null && nb != null) return na.compareTo(nb);
      return ra.compareTo(rb);
    });

    return [
      for (final student in students)
        _buildStudentSummary(
          student,
          sessions,
          attendanceBySession,
        ),
    ];
  }

  AttendanceSummaryModel _buildStudentSummary(
    QueryDocumentSnapshot<Map<String, dynamic>> student,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
    Map<String, Map<String, String>> attendanceBySession,
  ) {
    int present = 0;
    int absent = 0;

    for (final session in sessions) {
      final status = attendanceBySession[session.id]?[student.id];
      if (status == 'Present') {
        present++;
      } else {
        absent++;
      }
    }

    final total = sessions.length;
    final percentage = total == 0 ? 0.0 : (present / total) * 100;

    return AttendanceSummaryModel(
      studentId: student.id,
      rollNo: (student.data()['rollNo'] ?? '').toString(),
      studentName: (student.data()['name'] ?? '').toString(),
      present: present,
      absent: absent,
      totalClasses: total,
      attendancePercentage: percentage,
      status: percentage >= 75 ? 'Regular' : 'Detained',
    );
  }
}
