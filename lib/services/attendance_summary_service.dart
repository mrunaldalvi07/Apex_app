import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_summary_model.dart';

class AttendanceSummaryService {
  AttendanceSummaryService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  static const List<String> months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  DateTime? _dateOf(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _isPresent(dynamic value) {
    if (value == true) return true;
    final status = value?.toString().trim().toLowerCase();
    return status == 'present' || status == 'p' || status == 'true';
  }

  int _compareRoll(String a, String b) {
    final na = int.tryParse(a.trim());
    final nb = int.tryParse(b.trim());
    if (na != null && nb != null) return na.compareTo(nb);
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  Future<List<AttendanceSummaryModel>> getAttendanceSummary({
    required String branch,
    required String year,
    required String course,
    required String month,
    double threshold = 75,
  }) async {
    if (branch.trim().isEmpty || year.trim().isEmpty ||
        course.trim().isEmpty || !months.contains(month)) {
      throw ArgumentError('Select a valid branch, year, course and month.');
    }
    if (threshold < 0 || threshold > 100) {
      throw ArgumentError.value(threshold, 'threshold', 'Must be between 0 and 100.');
    }

    final cleanBranch = branch.trim().toUpperCase();
    final cleanYear = year.trim().replaceAll(RegExp(r'\s*Year$', caseSensitive: false), '');
    final cleanCourse = course.trim().toUpperCase();

    final studentSnapshot = await firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: cleanBranch)
        .where('year', isEqualTo: cleanYear)
        .get();

    final sessionSnapshot = await firestore.collection('live_sessions')
        .where('branch', isEqualTo: cleanBranch)
        .where('year', isEqualTo: cleanYear)
        .where('course', isEqualTo: cleanCourse)
        .where('status', isEqualTo: 'ended')
        .get();

    final monthNumber = months.indexOf(month) + 1;
    final sessions = sessionSnapshot.docs.where((doc) {
      final date = _dateOf(doc.data()['createdAt']);
      return date != null && date.month == monthNumber;
    }).toList()
      ..sort((a, b) => _dateOf(a.data()['createdAt'])!
          .compareTo(_dateOf(b.data()['createdAt'])!));

    // Fetch each completed session's attendance subcollection once.
    // Firestore errors are allowed to propagate; they must never become false absences.
    final attendanceBySession = <String, Map<String, dynamic>>{};
    for (final session in sessions) {
      final attendanceSnapshot = await firestore.collection('attendance')
          .doc(session.id).collection('students').get();
      attendanceBySession[session.id] = {
        for (final record in attendanceSnapshot.docs) record.id: record.data()['status'],
      };
    }

    final studentDocs = studentSnapshot.docs.toList()
      ..sort((a, b) => _compareRoll(
        (a.data()['rollNo'] ?? a.data()['rollNumber'] ?? '').toString(),
        (b.data()['rollNo'] ?? b.data()['rollNumber'] ?? '').toString(),
      ));

    return studentDocs.map((student) {
      var present = 0;
      for (final session in sessions) {
        if (_isPresent(attendanceBySession[session.id]?[student.id])) present++;
      }
      final total = sessions.length;
      final absent = total - present;
      final percentage = total == 0 ? 0.0 : present * 100 / total;
      final data = student.data();
      return AttendanceSummaryModel(
        studentId: student.id,
        rollNo: (data['rollNo'] ?? data['rollNumber'] ?? '').toString(),
        studentName: (data['name'] ?? data['displayName'] ?? data['fullName'] ?? '').toString(),
        present: present,
        absent: absent,
        totalClasses: total,
        attendancePercentage: percentage,
        status: total == 0 ? 'No Classes' : (percentage < threshold ? 'Detained' : 'Regular'),
      );
    }).toList();
  }
}
