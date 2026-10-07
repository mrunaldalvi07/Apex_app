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
  static const Color background = Colors.white;

  // Prevent multiple clicks while reservation is processing
  static bool _isReserving = false;

  Future<void> _startTemporaryReservation(
    BuildContext context,
    String documentId,
    String roomNo,
  ) async {
    // Ignore double-clicks / repeated clicks
    if (_isReserving) return;

    _isReserving = true;

    final classroomRef = FirebaseFirestore.instance
        .collection('classrooms')
        .doc(documentId);

    try {
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final snapshot = await transaction.get(classroomRef);

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

      if (!context.mounted) {
        _isReserving = false;
        return;
      }

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

      if (!context.mounted) {
        _isReserving = false;
        return;
      }

      final snapshot = await classroomRef.get();

      if (snapshot.exists) {
        final data =
            snapshot.data() as Map<String, dynamic>;

        final status =
            data['status']?.toString().toUpperCase() ?? "";

        // If user left without completing booking,
        // release temporary reservation.
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
      if (!context.mounted) {
        _isReserving = false;
        return;
      }

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
    } finally {
      _isReserving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // SECURITY CHECK
    // ==========================================================

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
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE1E5EA),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Access Denied",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Students are not allowed to book classrooms.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
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

    // ==========================================================
    // BOOK CLASSROOM SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          "Book Classroom",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
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
          // ======================================================
          // ERROR
          // ======================================================

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

          // ======================================================
          // LOADING
          // ======================================================

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

          // ======================================================
          // EMPTY STATE
          // ======================================================

          if (classrooms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE1E5EA),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        size: 48,
                        color: primaryNavy,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "No Free Classrooms",
                        style: TextStyle(
                          fontSize: 19,
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
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ======================================================
          // MAIN CONTENT
          // ======================================================

          return Column(
            children: [
              // ==================================================
              // COMPACT HEADER
              // ==================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  10,
                ),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
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
                        BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color:
                            darkNavy.withOpacity(0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // HEADER ICON
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.book_online_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 15),

                      // HEADER TEXT
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Book a Classroom",
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${classrooms.length} classroom(s) available",
                              style: TextStyle(
                                color: Colors.white
                                    .withOpacity(0.88),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // CLASSROOM LIST
              // ==================================================

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    2,
                    20,
                    20,
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

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(20),
                          onTap: () {
                            _startTemporaryReservation(
                              context,
                              classrooms[index].id,
                              roomNo,
                            );
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    const Color(0xFFE1E5EA),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05),
                                  blurRadius: 7,
                                  offset:
                                      const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // ==================================
                                // ROOM ICON
                                // ==================================

                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration:
                                      BoxDecoration(
                                    gradient:
                                        const LinearGradient(
                                      colors: [
                                        darkNavy,
                                        primaryNavy,
                                      ],
                                      begin:
                                          Alignment.centerLeft,
                                      end:
                                          Alignment.centerRight,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      16,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.class_rounded,
                                    color: Colors.white,
                                    size: 27,
                                  ),
                                ),

                                const SizedBox(width: 15),

                                // ==================================
                                // ROOM DETAILS
                                // ==================================

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        "ROOM $roomNo",
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            const TextStyle(
                                          fontSize: 16,
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
                                            width: 8,
                                            height: 8,
                                            decoration:
                                                const BoxDecoration(
                                              color:
                                                  Colors.green,
                                              shape: BoxShape
                                                  .circle,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 6,
                                          ),

                                          const Expanded(
                                            child: Text(
                                              "Available for booking",
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  TextStyle(
                                                color: Colors
                                                    .green,
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // ==================================
                                // ARROW
                                // ==================================

                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration:
                                      BoxDecoration(
                                    color: primaryNavy
                                        .withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .chevron_right_rounded,
                                    color: primaryNavy,
                                    size: 25,
                                  ),
                                ),
                              ],
                            ),
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