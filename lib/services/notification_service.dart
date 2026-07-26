import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> sendAttendanceWarning({
    required String studentId,
    required String course,
    required double percentage,
  }) async {

    final faculty =
        FirebaseAuth.instance.currentUser;

    await firestore.collection('notifications').add({

      'studentId': studentId,

      'title': 'Attendance Warning',

      'message':
          'Your attendance in $course is ${percentage.toStringAsFixed(1)}%. Minimum required attendance is 75%.',

      'type': 'attendance',

      'percentage': percentage,

      'course': course,

      'facultyId': faculty?.uid,

      'read': false,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }
}