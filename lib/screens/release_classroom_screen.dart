import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReleaseClassroomScreen extends StatelessWidget {
  const ReleaseClassroomScreen({super.key});

  // Classroom module colors
  static const Color darkNavy = Color(0xFF163B73);
  static const Color primaryNavy = Color(0xFF2F6DB2);
  static const Color background = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: darkNavy,
        title: const Text(
          "Release Classroom",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkNavy,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classrooms')
            .where(
              'status',
              isEqualTo: 'BOOKED',
            )
            .snapshots(),
        builder: (context, snapshot) {
          // Error
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading classrooms",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryNavy,
              ),
            );
          }

          final classrooms = snapshot.data?.docs ?? [];

          // No booked classrooms
          if (classrooms.isEmpty) {
            return RefreshIndicator(
              color: primaryNavy,
              onRefresh: () async {
                await Future.delayed(
                  const Duration(milliseconds: 500),
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 70,
                    color: primaryNavy.withOpacity(0.45),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      "No booked classrooms available",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: darkNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      "All classrooms are currently free.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      darkNavy,
                      primaryNavy,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Release Classroom",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      "Release a booked classroom when the lecture or activity is completed.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Section title
              const Text(
                "Booked Classrooms",
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Classroom cards
              ...classrooms.map(
                (classroomDoc) {
                  final classroom =
                      classroomDoc.data() as Map<String, dynamic>;

                  final roomNo =
                      classroom['roomNo']?.toString() ?? '';

                  final course =
                      classroom['course']?.toString() ?? '';

                  final faculty =
                      classroom['facultyName']?.toString() ?? '';

                  final timeSlot =
                      classroom['timeSlot']?.toString() ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Room header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  darkNavy,
                                  primaryNavy,
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.meeting_room,
                                  color: Colors.white,
                                  size: 27,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "ROOM $roomNo",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "BOOKED",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Course
                          _infoRow(
                            icon: Icons.menu_book_outlined,
                            title: "Course",
                            value: course,
                          ),

                          const SizedBox(height: 13),

                          // Faculty
                          _infoRow(
                            icon: Icons.person_outline,
                            title: "Faculty",
                            value: faculty,
                          ),

                          const SizedBox(height: 13),

                          // Time slot
                          _infoRow(
                            icon: Icons.access_time,
                            title: "Time Slot",
                            value: timeSlot,
                          ),

                          const SizedBox(height: 18),

                          // Status
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.20),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Classroom is currently booked",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Release button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                              ),
                              icon: const Icon(
                                Icons.lock_open,
                              ),
                              label: const Text(
                                "RELEASE CLASSROOM",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                16),
                                      ),

                                      // FIXED DIALOG TITLE
                                      title: Row(
                                        children: [
                                          const Icon(
                                            Icons
                                                .warning_amber_rounded,
                                            color: Colors.red,
                                            size: 30,
                                          ),
                                          const SizedBox(width: 8),
                                          const Flexible(
                                            child: Text(
                                              "Confirm Release",
                                              style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 22,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      content: Text(
                                        "Are you sure?\n\n"
                                        "ROOM $roomNo will be released.",
                                      ),

                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              dialogContext,
                                              false,
                                            );
                                          },
                                          child: const Text(
                                            "CANCEL",
                                            style: TextStyle(
                                              color: darkNavy,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton
                                              .styleFrom(
                                            backgroundColor:
                                                Colors.red,
                                            foregroundColor:
                                                Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(
                                              dialogContext,
                                              true,
                                            );
                                          },
                                          child: const Text(
                                            "RELEASE",
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm != true) {
                                  return;
                                }

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('classrooms')
                                      .doc(classroomDoc.id)
                                      .update({
                                    'status': 'FREE',
                                    'course': '',
                                    'facultyName': '',
                                    'timeSlot': '',
                                    'reservationExpiresAt':
                                        FieldValue.delete(),
                                  });

                                  if (!context.mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Classroom released successfully.",
                                      ),
                                      duration:
                                          Duration(seconds: 5),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Unable to release classroom.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Information row
  static Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FB),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: primaryNavy,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? "Not available" : value,
                style: const TextStyle(
                  color: darkNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}