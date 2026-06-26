import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';



class FacultyLiveAttendanceScreen extends StatefulWidget {
  const FacultyLiveAttendanceScreen({super.key});

  @override
  State<FacultyLiveAttendanceScreen> createState() =>
      _FacultyLiveAttendanceScreenState();
}

class _FacultyLiveAttendanceScreenState
    extends State<FacultyLiveAttendanceScreen> {
  final TextEditingController courseController = TextEditingController();

  bool isLoading = false;

  String selectedYear = '1';
  String selectedBranch = 'IT';

  final List<String> years = ['1', '2', '3'];
  final List<String> branches = ['IT', 'CM'];

  /// ---------------- LOCATION ----------------
  Future<Position> getFacultyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = 
       await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied");
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// ---------------- START SESSION ----------------
  Future<void> startLiveAttendance() async {
    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      if (courseController.text.trim().isEmpty) {
        throw Exception("Enter course name");
      }

     final courseName =
    courseController.text.trim().toUpperCase();

final existing = await FirebaseFirestore.instance
    .collection('live_sessions')
    .where('status', isEqualTo: 'live')
    .where('branch', isEqualTo: selectedBranch)
    .where('year', isEqualTo: selectedYear)
    .where('course', isEqualTo: courseName)
    .get();

if (existing.docs.isNotEmpty) {
  throw Exception(
    "This course session is already running",
  );
}

      final position = await getFacultyLocation();
final studentsSnapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('role', isEqualTo: 'student')
    .where('branch', isEqualTo: selectedBranch)
    .where('year', isEqualTo: selectedYear)
    .get();

final totalStudents = studentsSnapshot.docs.length;

      await FirebaseFirestore.instance.collection('live_sessions').add({
        'course': courseName,
        'year': selectedYear,
        'branch': selectedBranch,
        'totalStudents':totalStudents,
        'facultyId': user.uid,
        'facultyEmail': user.email ?? '',
        'facultyLat': position.latitude,
        'facultyLng': position.longitude,
        'radius': 500,
        'status': 'live',
        'createdAt': FieldValue.serverTimestamp(),
        'endedAt': null,
      });

      courseController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Live session started")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ---------------- END SESSION ----------------
  Future<void> endSession(String sessionId) async {
  try {

    final sessionDoc = await FirebaseFirestore.instance
        .collection('live_sessions')
        .doc(sessionId)
        .get();

    final branch = sessionDoc['branch'];
    final year = sessionDoc['year'];

    final students = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .get();

    final presentDocs = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(sessionId)
        .collection('students')
        .get();

    final presentIds = presentDocs.docs
        .map((e) => e.id)
        .toSet();

    final batch =
        FirebaseFirestore.instance.batch();

    for (final student in students.docs) {

      if (!presentIds.contains(student.id)) {

        batch.set(
          FirebaseFirestore.instance
              .collection('attendance')
              .doc(sessionId)
              .collection('students')
              .doc(student.id),
            {
  'studentId': student.id,
  'name': student['name'],
  'rollNo': student['rollNo'],
  'branch': student['branch'],
  'year': student['year'],
  'status': 'Absent',
  'markedAt': FieldValue.serverTimestamp(),
          },
        );
      }
    }

    await batch.commit();

    await FirebaseFirestore.instance
        .collection('live_sessions')
        .doc(sessionId)
        .update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session ended"),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  @override
  void dispose() {
    courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Live Attendance")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: "Course Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField(
              initialValue: selectedYear,
              items: years
                  .map((y) => DropdownMenuItem(value: y, child: Text("$y Year")))
                  .toList(),
              onChanged: (v) => setState(() => selectedYear = v!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField(
              initialValue: selectedBranch,
              items: branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => selectedBranch = v!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : startLiveAttendance,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("START SESSION"),
            ),
            
           const Divider(height: 40),

            const Text(
              "Active Sessions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('live_sessions')
                  .where('facultyId', isEqualTo: uid)
                  .where('status', isEqualTo: 'live')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Text("No active session");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];

                    return StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('attendance')
      .doc(doc.id)
      .collection('students')
      .where('status', isEqualTo: 'Present')
      .snapshots(),
  builder: (context, attendanceSnapshot) {

    int presentCount = 0;

    if (attendanceSnapshot.hasData) {
      presentCount = attendanceSnapshot.data!.docs.length;
    }

    return Card(
      child: ListTile(
        title: Text(doc['course']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${doc['year']} Year - ${doc['branch']}"),
            Text(
              "Present Students : $presentCount",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            Text(
              "Total Students:${doc.data().toString().contains('totalStudents')?doc['totalStudents']:0}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),      
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.stop_circle,
            color: Colors.red,
          ),
          onPressed: () => endSession(doc.id),
        ),
      ),
    );
  },
);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}