import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_form_screen.dart';

class BookClassroomScreen extends StatelessWidget {
  final String role;

  const BookClassroomScreen({
    super.key,
    required this.role,
  });

  // Temporary reservation duration
  static const Duration reservationDuration =
      Duration(minutes: 5);

  // Classroom UI Colors
  static const Color darkNavy = Color(0xFF163B73);
  static const Color primaryNavy = Color(0xFF2F6DB2);
  static const Color background = Color(0xFFF5F0EB);

  Future<void> _startTemporaryReservation(
    BuildContext context,
    String documentId,
    String roomNo,
  ) async {
    final classroomRef = FirebaseFirestore.instance
        .collection('classrooms')
        .doc(documentId);

    try {
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final snapshot =
            await transaction.get(classroomRef);

        if (!snapshot.exists) {
          throw Exception("Classroom not found");
        }

        final data =
            snapshot.data() as Map<String, dynamic>;

        final status =
            data['status']?.toString().toUpperCase() ?? "";

        // Check current status before reserving
        if (status != "FREE") {
          throw Exception(
            "This classroom is no longer available.",
          );
        }

        final expiresAt = Timestamp.fromDate(
          DateTime.now().add(reservationDuration),
        );

        transaction.update(classroomRef, {
          'status': 'TEMPORARILY RESERVED',
          'reservationExpiresAt': expiresAt,
        });
      });

      if (!context.mounted) return;

      // Open booking form after temporary reservation
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingFormScreen(
            roomNo: roomNo,
            documentId: documentId,
          ),
        ),
      );

      if (!context.mounted) return;

      final snapshot = await classroomRef.get();

      if (snapshot.exists) {
        final data =
            snapshot.data() as Map<String, dynamic>;

        final status =
            data['status']?.toString().toUpperCase() ?? "";

        if (status == "TEMPORARILY RESERVED") {
          await classroomRef.update({
            'status': 'FREE',
            'course': '',
            'facultyName': '',
            'timeSlot': '',
            'reservationExpiresAt':
                FieldValue.delete(),
          });
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains(
                  "no longer available",
                )
                ? "This classroom is no longer available."
                : "Unable to reserve the classroom.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Security Check
    if (role == "student") {
      return Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          title: const Text(
            "Access Denied",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: darkNavy,
          elevation: 0,
        ),

        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 55,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Access Denied",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkNavy,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Students are not allowed to book classrooms.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          "Book Classroom",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classrooms')
            .where(
              'status',
              isEqualTo: 'FREE',
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading classrooms",
                style: TextStyle(
                  color: darkNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryNavy,
              ),
            );
          }

          final classrooms =
              snapshot.data?.docs ?? [];

          if (classrooms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(17),
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        size: 55,
                        color: primaryNavy,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "No Free Classrooms",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkNavy,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "No free classrooms are currently available for booking.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [

              // -----------------------------
              // BLUE GRADIENT HEADER
              // -----------------------------

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  6,
                ),

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        darkNavy,
                        primaryNavy,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(17),
                  ),

                  child: Row(
                    children: [

                      Container(
                        padding:
                            const EdgeInsets.all(10),

                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        child: const Icon(
                          Icons.book_online,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Book a Classroom",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "${classrooms.length} classroom(s) available",
                              style: TextStyle(
                                color: Colors.white
                                    .withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -----------------------------
              // CLASSROOM LIST
              // -----------------------------

              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.only(
                    top: 4,
                    bottom: 12,
                  ),

                  itemCount: classrooms.length,

                  itemBuilder: (context, index) {
                    final classroom =
                        classrooms[index].data()
                            as Map<String, dynamic>;

                    final roomNo =
                        classroom['roomNo']
                                ?.toString() ??
                            "";

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      elevation: 2,

                      color: Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17),
                      ),

                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(17),

                        onTap: () {
                          _startTemporaryReservation(
                            context,
                            classrooms[index].id,
                            roomNo,
                          );
                        },

                        child: Padding(
                          padding:
                              const EdgeInsets.all(14),

                          child: Row(
                            children: [

                              // ROOM ICON
                              Container(
                                width: 58,
                                height: 58,

                                decoration:
                                    BoxDecoration(
                                  gradient:
                                      const LinearGradient(
                                    colors: [
                                      darkNavy,
                                      primaryNavy,
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(14),
                                ),

                                child: const Icon(
                                  Icons.class_,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),

                              const SizedBox(width: 14),

                              // ROOM DETAILS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Text(
                                      "ROOM $roomNo",
                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.bold,
                                        color: darkNavy,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Row(
                                      children: [
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration:
                                              const BoxDecoration(
                                            color:
                                                Colors.green,
                                            shape:
                                                BoxShape
                                                    .circle,
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 7,
                                        ),

                                        const Text(
                                          "Available for booking",
                                          style: TextStyle(
                                            color:
                                                Colors.green,
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ARROW
                              Container(
                                padding:
                                    const EdgeInsets.all(
                                  9,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: primaryNavy
                                      .withOpacity(0.10),
                                  borderRadius:
                                      BorderRadius
                                          .circular(10),
                                ),

                                child: const Icon(
                                  Icons
                                      .arrow_forward_ios,
                                  color: primaryNavy,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}