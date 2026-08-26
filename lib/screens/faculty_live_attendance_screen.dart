import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/attendance_ui.dart';

class FacultyLiveAttendanceScreen extends StatefulWidget {
  const FacultyLiveAttendanceScreen({super.key});

  @override
  State<FacultyLiveAttendanceScreen> createState() =>
      _FacultyLiveAttendanceScreenState();
}

class _FacultyLiveAttendanceScreenState
    extends State<FacultyLiveAttendanceScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = false;

  String selectedYear = '1';
  String selectedBranch = 'IT';

  // COURSE DROPDOWN
  String selectedCourse = 'Object Oriented Programming';

  // ============================================================
  // DROPDOWN DATA
  // ============================================================

  final List<String> years = [
    '1',
    '2',
    '3',
  ];

  final List<String> branches = [
    'IT',
    'CM',
  ];

  final List<String> courses = [
    'Object Oriented Programming',
    'Database Management Systems',
    'Computer Networks',
    'Java Programming',
    'Python Programming',
  ];

  // ============================================================
  // GET FACULTY LOCATION
  // ============================================================

  Future<Position> getFacultyLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled.',
      );
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
        'Location permission permanently denied.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission denied.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ============================================================
  // START LIVE ATTENDANCE
  // ============================================================

  Future<void> startLiveAttendance() async {
    try {
      setState(() => isLoading = true);

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Not logged in.',
        );
      }

      final course =
          selectedCourse.toUpperCase();

      final existing =
          await FirebaseFirestore.instance
              .collection('live_sessions')
              .where(
                'status',
                isEqualTo: 'live',
              )
              .where(
                'branch',
                isEqualTo: selectedBranch,
              )
              .where(
                'year',
                isEqualTo: selectedYear,
              )
              .where(
                'course',
                isEqualTo: course,
              )
              .get();

      if (existing.docs.isNotEmpty) {
        throw Exception(
          'This course session is already running.',
        );
      }

      final position =
          await getFacultyLocation();

      final students =
          await FirebaseFirestore.instance
              .collection('users')
              .where(
                'role',
                isEqualTo: 'student',
              )
              .where(
                'branch',
                isEqualTo: selectedBranch,
              )
              .where(
                'year',
                isEqualTo: selectedYear,
              )
              .get();

      await FirebaseFirestore.instance
          .collection('live_sessions')
          .add({
        'course': course,
        'year': selectedYear,
        'branch': selectedBranch,
        'totalStudents':
            students.docs.length,
        'facultyId': user.uid,
        'facultyEmail':
            user.email ?? '',
        'facultyLat':
            position.latitude,
        'facultyLng':
            position.longitude,
        'radius': 500,
        'status': 'live',
        'createdAt':
            FieldValue.serverTimestamp(),
        'endedAt': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Live session started.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

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
    } finally {
      if (mounted) {
        setState(
          () => isLoading = false,
        );
      }
    }
  }

  // ============================================================
  // END SESSION
  // ============================================================

  Future<void> endSession(
    String sessionId,
  ) async {
    try {
      final firestore =
          FirebaseFirestore.instance;

      final session =
          await firestore
              .collection('live_sessions')
              .doc(sessionId)
              .get();

      if (!session.exists) {
        throw Exception(
          'Session not found.',
        );
      }

      final data =
          session.data()!;

      final students =
          await firestore
              .collection('users')
              .where(
                'role',
                isEqualTo: 'student',
              )
              .where(
                'branch',
                isEqualTo: data['branch'],
              )
              .where(
                'year',
                isEqualTo: data['year'],
              )
              .get();

      final presentDocs =
          await firestore
              .collection('attendance')
              .doc(sessionId)
              .collection('students')
              .get();

      final presentIds =
          presentDocs.docs
              .map((e) => e.id)
              .toSet();

      final batch =
          firestore.batch();

      for (final student
          in students.docs) {
        if (!presentIds
            .contains(student.id)) {
          final studentData =
              student.data();

          batch.set(
            firestore
                .collection('attendance')
                .doc(sessionId)
                .collection('students')
                .doc(student.id),
            {
              'studentId':
                  student.id,
              'name':
                  studentData['name'] ??
                      '',
              'rollNo':
                  studentData['rollNo'] ??
                      '',
              'branch':
                  studentData['branch'] ??
                      '',
              'year':
                  studentData['year'] ??
                      '',
              'status':
                  'Absent',
              'markedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      }

      await batch.commit();

      await firestore
          .collection('live_sessions')
          .doc(sessionId)
          .update({
        'status': 'ended',
        'endedAt':
            FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Session ended.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor:
          AttendanceUI.background,

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,

        leading:
            AttendanceUI.backButton(
          context,
        ),

        title: Text(
          'Live Attendance',
          style: AttendanceUI.title,
        ),

        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            _sessionReadyCard(),

            const SizedBox(height: 15),

            _fieldSection(),

            const SizedBox(height: 12),

            AttendanceUI.primaryButton(
              text: isLoading
                  ? 'STARTING...'
                  : 'START SESSION',
              icon: Icons.play_arrow,
              onPressed: isLoading
                  ? null
                  : startLiveAttendance,
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                Text(
                  'Active Sessions',
                  style:
                      AttendanceUI.sectionTitle,
                ),

                TextButton(
                  onPressed: () {},
                  child:
                      const Text(
                    'View All',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance
                      .collection(
                          'live_sessions')
                      .where(
                        'facultyId',
                        isEqualTo: uid,
                      )
                      .where(
                        'status',
                        isEqualTo: 'live',
                      )
                      .snapshots(),

              builder: (
                context,
                snapshot,
              ) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _emptyCard(
                    'Unable to load active sessions.',
                  );
                }

                final docs =
                    snapshot.data?.docs ??
                        [];

                if (docs.isEmpty) {
                  return _emptyCard(
                    'No active sessions.',
                  );
                }

                return Column(
                  children:
                      docs.map((doc) {
                    return Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),
                      child:
                          _liveSessionCard(
                        doc,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SESSION READY CARD
  // ============================================================

  Widget _sessionReadyCard() {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            const Color(0xFFEAF5FF),

        borderRadius:
            BorderRadius.circular(15),

        border: Border.all(
          color:
              const Color(0xFFD6EAF7),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.location_on,
              color:
                  AttendanceUI.primaryBlue,
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const Text(
                  'Session Ready',
                  style: TextStyle(
                    color:
                        AttendanceUI.darkNavy,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Ensure students are within the allowed area to mark attendance.',
                  style:
                      AttendanceUI.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIELD SECTION
  // ============================================================

  Widget _fieldSection() {
    return Column(
      children: [
        // COURSE DROPDOWN
        AttendanceUI.dropdown<String>(
          label: 'Course',
          value: selectedCourse,
          items: courses,
          icon: Icons.school,
          labelBuilder: (value) =>
              value,
          onChanged: (value) {
            if (value != null) {
              setState(
                () => selectedCourse =
                    value,
              );
            }
          },
        ),

        const SizedBox(height: 10),

        // YEAR DROPDOWN
        AttendanceUI.dropdown<String>(
          label: 'Year',
          value: selectedYear,
          items: years,
          icon:
              Icons.calendar_month,
          labelBuilder: (value) =>
              '$value Year',
          onChanged: (value) {
            if (value != null) {
              setState(
                () => selectedYear =
                    value,
              );
            }
          },
        ),

        const SizedBox(height: 10),

        // BRANCH DROPDOWN
        AttendanceUI.dropdown<String>(
          label: 'Branch',
          value: selectedBranch,
          items: branches,
          icon:
              Icons.account_balance,
          onChanged: (value) {
            if (value != null) {
              setState(
                () => selectedBranch =
                    value,
              );
            }
          },
        ),
      ],
    );
  }

  // ============================================================
  // LIVE SESSION CARD
  // ============================================================

  Widget _liveSessionCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final total =
        (data['totalStudents'] ?? 0)
            as num;

    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('attendance')
              .doc(doc.id)
              .collection('students')
              .where(
                'status',
                isEqualTo: 'Present',
              )
              .snapshots(),

      builder: (
        context,
        snapshot,
      ) {
        final present =
            snapshot.data?.docs.length ??
                0;

        final percentage =
            total == 0
                ? 0
                : present / total * 100;

        return Container(
          padding:
              const EdgeInsets.all(15),

          decoration:
              AttendanceUI
                  .cardDecoration(),

          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AttendanceUI
                            .primaryBlue
                            .withValues(
                      alpha: .10,
                    ),

                    child: Text(
                      (data['course'] ??
                              'OPS')
                          .toString()
                          .substring(
                            0,
                            ((data['course'] ??
                                        'OPS')
                                    .toString()
                                    .length >
                                4)
                                ? 4
                                : (data['course'] ??
                                        'OPS')
                                    .toString()
                                    .length,
                          ),

                      style:
                          const TextStyle(
                        color:
                            AttendanceUI
                                .primaryBlue,
                        fontWeight:
                            FontWeight
                                .w800,
                        fontSize: 10,
                      ),
                    ),
                  ),

                  const SizedBox(
                      width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          data['course']
                                  ?.toString() ??
                              'Course',

                          style:
                              const TextStyle(
                            color:
                                AttendanceUI
                                    .darkNavy,
                            fontWeight:
                                FontWeight
                                    .w700,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(
                            height: 3),

                        Text(
                          '${data['year']} Year • ${data['branch']}',
                          style:
                              AttendanceUI
                                  .body,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          AttendanceUI
                              .green
                              .withValues(
                        alpha: .10,
                      ),

                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),

                    child:
                        const Text(
                      'LIVE',
                      style:
                          TextStyle(
                        color:
                            AttendanceUI
                                .green,
                        fontWeight:
                            FontWeight
                                .w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                  height: 15),

              Row(
                children: [
                  _metric(
                    'Present',
                    '$present',
                    AttendanceUI.green,
                  ),

                  _metric(
                    'Total Students',
                    '${total.toInt()}',
                    AttendanceUI
                        .primaryBlue,
                  ),

                  _metric(
                    'Attendance',
                    '${percentage.toStringAsFixed(1)}%',
                    AttendanceUI.cyan,
                  ),
                ],
              ),

              const SizedBox(
                  height: 12),

              SizedBox(
                width:
                    double.infinity,
                height: 42,

                child:
                    OutlinedButton.icon(
                  onPressed: () =>
                      endSession(
                    doc.id,
                  ),

                  icon:
                      const Icon(
                    Icons.stop_circle,
                    color:
                        AttendanceUI.red,
                  ),

                  label:
                      const Text(
                    'END SESSION',
                    style:
                        TextStyle(
                      color:
                          AttendanceUI.red,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),

                  style: OutlinedButton
                      .styleFrom(
                    side:
                        const BorderSide(
                      color:
                          AttendanceUI
                              .red,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // METRIC
  // ============================================================

  Widget _metric(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            textAlign:
                TextAlign.center,

            style: const TextStyle(
              color:
                  AttendanceUI
                      .textGrey,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _emptyCard(
    String text,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(25),

      decoration:
          AttendanceUI
              .cardDecoration(),

      child: Center(
        child: Text(
          text,
          style:
              AttendanceUI.body,
        ),
      ),
    );
  }
}