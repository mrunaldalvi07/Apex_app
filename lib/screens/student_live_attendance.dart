import 'package:apex_app/screens/student_notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/notification_service.dart';

class StudentLiveAttendanceScreen extends StatefulWidget {
  const StudentLiveAttendanceScreen({super.key});

  @override
  State<StudentLiveAttendanceScreen> createState() =>
      _StudentLiveAttendanceScreenState();
}

class _StudentLiveAttendanceScreenState
    extends State<StudentLiveAttendanceScreen> {
  String? branch;
  String? year;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

      setState(() {
        branch = doc['branch'];
        year = doc['year'];
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
          "Location Services Disabled");
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
          "Location Permission Denied");
    }

    return await Geolocator.getCurrentPosition(
       locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
),    );
  }

  Future<void> markAttendance(
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final user =
          FirebaseAuth.instance.currentUser!;

      final alreadyMarked =
          await FirebaseFirestore.instance
              .collection('attendance')
              .doc(sessionId)
              .collection('students')
              .doc(uid)
              .get();

      if (alreadyMarked.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Attendance Already Marked",
            ),
          ),
        );
        return;
      }

      Position studentPosition =
          await getCurrentLocation();

      double distance =
          Geolocator.distanceBetween(
        sessionData['facultyLat'],
        sessionData['facultyLng'],
        studentPosition.latitude,
        studentPosition.longitude,
      );

      String status =
          distance <= 6
              ? "Present"
              : "Absent";

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

      final userData =
          userDoc.data() ?? {};

      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(sessionId)
          .collection('students')
          .doc(uid)
          .set({
        'studentId': uid,

        'rollNo':
            userData['rollNo'] ?? '',

        'name':
            userData['name'] ?? '',

        'email':
            user.email ?? '',

        'branch':
            userData['branch'] ?? '',

        'year':
            userData['year'] ?? '',

        'status': status,

        'distance': distance,

        'studentLat':
            studentPosition.latitude,

        'studentLng':
            studentPosition.longitude,

        'markedAt':
            Timestamp.now(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Attendance Marked : $status",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
     appBar: AppBar(
  title: const Text("Live Attendance"),
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const StudentNotificationScreen(),
          ),
        );
      },
    ),
  ],
),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('live_sessions')
            .where(
              'branch',
              isEqualTo: branch,
            )
            .where(
              'year',
              isEqualTo: year,
            )
            .where(
              'status',
              isEqualTo: 'live',
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Live Session Available",
              ),
            );
          }

          return ListView.builder(
            itemCount:
                snapshot.data!.docs.length,
            itemBuilder:
                (context, index) {
              final session =
                  snapshot.data!.docs[index];

              final data =
                  session.data()
                      as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.all(10),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                          15),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        data['course'],
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 10),

                      Text(
                        "Branch : ${data['branch']}",
                      ),

                      Text(
                        "Year : ${data['year']}",
                      ),

                      const SizedBox(
                          height: 15),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton(
                          onPressed: () {
                            markAttendance(
                              session.id,
                              data,
                            );
                          },
                          child:
                              const Text(
                            "MARK PRESENT",
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
  icon: const Icon(Icons.notifications),
  label: const Text("Notifications"),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const StudentNotificationScreen(),
      ),
    );
  },
),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}