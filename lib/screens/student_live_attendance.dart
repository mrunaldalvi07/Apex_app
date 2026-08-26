import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/attendance_constants.dart';
import 'student_notification_screen.dart';

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

  final Set<String> marking = {};

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Not logged in.');
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data == null) {
        throw Exception('Student profile not found.');
      }

      if (!mounted) return;

      setState(() {
        branch = (data['branch'] ?? '').toString().toUpperCase();
        year = (data['year'] ?? '').toString();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<Position> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<void> markAttendance(
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (marking.contains(sessionId)) return;

    setState(() => marking.add(sessionId));

    try {
      final attendanceRef = FirebaseFirestore.instance
          .collection('attendance')
          .doc(sessionId)
          .collection('students')
          .doc(user.uid);

      final existing = await attendanceRef.get();

      if (existing.exists) {
        throw Exception(
          'Attendance has already been marked.',
        );
      }

      final position = await getCurrentLocation();

      final facultyLat =
          (sessionData['facultyLat'] as num?)?.toDouble();

      final facultyLng =
          (sessionData['facultyLng'] as num?)?.toDouble();

      final radius =
          ((sessionData['radius'] as num?)?.toDouble() ?? 500)
              .clamp(1, 5000);

      if (facultyLat == null || facultyLng == null) {
        throw Exception(
          'Session location is unavailable.',
        );
      }

      final distance = Geolocator.distanceBetween(
        facultyLat,
        facultyLng,
        position.latitude,
        position.longitude,
      );

      if (distance > radius) {
        await attendanceRef.set({
          'studentId': user.uid,
          'status': 'Absent',
          'distance': distance,
          'markedAt': FieldValue.serverTimestamp(),
        });

        throw Exception(
          'You are ${distance.toStringAsFixed(0)} m away. '
          'You must be within ${radius.toStringAsFixed(0)} m.',
        );
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      await attendanceRef.set({
        'studentId': user.uid,
        'rollNo': userData['rollNo'] ?? '',
        'name': userData['name'] ?? '',
        'email': user.email ?? '',
        'branch': userData['branch'] ?? '',
        'year': userData['year'] ?? '',
        'status': 'Present',
        'distance': distance,
        'studentLat': position.latitude,
        'studentLng': position.longitude,
        'markedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Attendance marked successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
    } finally {
      if (mounted) {
        setState(() => marking.remove(sessionId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AttendanceConstants.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AttendanceConstants.primaryBlue,
          ),
        ),
      );
    }

    if (branch == null ||
        year == null ||
        branch!.isEmpty ||
        year!.isEmpty) {
      return Scaffold(
        backgroundColor: AttendanceConstants.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AttendanceConstants.darkNavy,
          elevation: 0,
          title: const Text(
            'Live Attendance',
            style: TextStyle(
              color: AttendanceConstants.darkNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Student branch/year is not configured.',
            style: TextStyle(
              color: AttendanceConstants.textGrey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AttendanceConstants.background,

      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AttendanceConstants.darkNavy,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
            color: AttendanceConstants.darkNavy,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Live Attendance',
          style: TextStyle(
            color: AttendanceConstants.darkNavy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where(
                  'studentId',
                  isEqualTo:
                      FirebaseAuth.instance.currentUser?.uid,
                )
                .snapshots(),
            builder: (context, snapshot) {
              final unread = snapshot.data?.docs
                      .where(
                        (doc) =>
                            doc.data()['read'] != true,
                      )
                      .length ??
                  0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: AttendanceConstants.darkNavy,
                    ),
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

                  if (unread > 0)
                    Positioned(
                      right: 7,
                      top: 6,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AttendanceConstants.red,
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      // ------------------------------------------------------------
      // BODY
      // ------------------------------------------------------------
      body: Column(
        children: [
          _studentHeader(),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load live sessions:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color:
                              AttendanceConstants.textGrey,
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color:
                          AttendanceConstants.primaryBlue,
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return _noSessionCard();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    24,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final session = docs[index];
                    final data = session.data();

                    final isMarking =
                        marking.contains(session.id);

                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 13),
                      child: _liveSessionCard(
                        session.id,
                        data,
                        isMarking,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STUDENT HEADER
  // ------------------------------------------------------------

  Widget _studentHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        15,
      ),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AttendanceConstants.darkNavy,
            AttendanceConstants.primaryNavy,
          ],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$year Year • $branch',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Sessions available for your class',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LIVE SESSION CARD
  // ------------------------------------------------------------

  Widget _liveSessionCard(
    String sessionId,
    Map<String, dynamic> data,
    bool isMarking,
  ) {
    final course =
        (data['course'] ?? 'COURSE')
            .toString()
            .toUpperCase();

    final radius = data['radius'] ?? 500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AttendanceConstants.primaryBlue
                      .withValues(alpha: .10),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    course.substring(
                      0,
                      course.length > 4
                          ? 4
                          : course.length,
                    ),
                    style: const TextStyle(
                      color:
                          AttendanceConstants.primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      course,
                      style: const TextStyle(
                        color:
                            AttendanceConstants.darkNavy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['year'] ?? year} Year • '
                      '${data['branch'] ?? branch}',
                      style: const TextStyle(
                        color:
                            AttendanceConstants.textGrey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AttendanceConstants.successGreen
                      .withValues(alpha: .10),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color:
                          AttendanceConstants.successGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color:
                            AttendanceConstants.successGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F9FC),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color:
                      AttendanceConstants.primaryBlue,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You must be within $radius m '
                    'of the faculty location.',
                    style: const TextStyle(
                      color:
                          AttendanceConstants.textGrey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isMarking
                  ? null
                  : () => markAttendance(
                        sessionId,
                        data,
                      ),
              icon: isMarking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline,
                    ),
              label: Text(
                isMarking
                    ? 'CHECKING LOCATION...'
                    : 'MARK PRESENT',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AttendanceConstants.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AttendanceConstants.primaryBlue
                        .withValues(alpha: .55),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // NO SESSION
  // ------------------------------------------------------------

  Widget _noSessionCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE1EAF2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AttendanceConstants.primaryBlue
                      .withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available,
                  size: 32,
                  color:
                      AttendanceConstants.primaryBlue,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'No Live Session Available',
                style: TextStyle(
                  color:
                      AttendanceConstants.darkNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your faculty has not started an attendance session yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      AttendanceConstants.textGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}