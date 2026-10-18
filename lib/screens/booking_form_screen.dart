import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingFormScreen extends StatefulWidget {
  final String roomNo;
  final String documentId;

  const BookingFormScreen({
    super.key,
    required this.roomNo,
    required this.documentId,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final TextEditingController courseController = TextEditingController();
  final TextEditingController facultyController = TextEditingController();
  final TextEditingController timeSlotController = TextEditingController();

  Timer? _expiryTimer;
  bool _isProcessing = false;
  bool _isLeaving = false;

  // APEX Classroom UI Colors
  static const Color darkNavy = Color(0xFF163B73);
  static const Color primaryNavy = Color(0xFF2F6DB2);
  static const Color background = Colors.white;

  @override
  void initState() {
    super.initState();
    _startExpiryCheck();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    courseController.dispose();
    facultyController.dispose();
    timeSlotController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // EXPIRY CHECK
  // ------------------------------------------------------------

  void _startExpiryCheck() {
    _checkReservationExpiry();

    _expiryTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) async {
        await _checkReservationExpiry();
      },
    );
  }

  Future<bool> _checkReservationExpiry() async {
    try {
      final classroomRef = FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.documentId);

      final snapshot = await classroomRef.get();

      if (!snapshot.exists) {
        return true;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      final status = data['status']?.toString().toUpperCase() ?? '';

      final expiresAt = data['reservationExpiresAt'];

      if (status != 'TEMPORARILY RESERVED') {
        return status == 'FREE';
      }

      if (expiresAt is Timestamp) {
        final expiryTime = expiresAt.toDate();

        if (DateTime.now().isAfter(expiryTime)) {
          await classroomRef.update({
            'status': 'FREE',
            'course': '',
            'facultyName': '',
            'timeSlot': '',
            'reservationExpiresAt': FieldValue.delete(),
          });

          if (mounted) {
            _showExpiredDialog();
          }

          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // EXPIRY DIALOG
  // ------------------------------------------------------------

  void _showExpiredDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          title: const Text(
            'Reservation Expired',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'The temporary reservation for this classroom '
            'has expired. The classroom is now available again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: darkNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BACK BUTTON
  // ------------------------------------------------------------

  Future<void> _handleBack() async {
    if (_isLeaving) return;

    _isLeaving = true;

    try {
      final classroomRef = FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.documentId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(classroomRef);

          if (!snapshot.exists) return;

          final data = snapshot.data() as Map<String, dynamic>;

          final status =
              data['status']?.toString().toUpperCase() ?? '';

          // Only release temporary reservation.
          // Never release an already BOOKED classroom.
          if (status == 'TEMPORARILY RESERVED') {
            transaction.update(classroomRef, {
              'status': 'FREE',
              'course': '',
              'facultyName': '',
              'timeSlot': '',
              'reservationExpiresAt': FieldValue.delete(),
            });
          }
        },
      );
    } catch (e) {
      // Best-effort cleanup.
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ------------------------------------------------------------
  // CANCEL RESERVATION
  // ------------------------------------------------------------

  Future<void> _cancelReservation() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final classroomRef = FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.documentId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(classroomRef);

          if (!snapshot.exists) return;

          final data = snapshot.data() as Map<String, dynamic>;

          final status =
              data['status']?.toString().toUpperCase() ?? '';

          if (status == 'TEMPORARILY RESERVED') {
            transaction.update(classroomRef, {
              'status': 'FREE',
              'course': '',
              'facultyName': '',
              'timeSlot': '',
              'reservationExpiresAt': FieldValue.delete(),
            });
          }
        },
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Temporary reservation cancelled.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to cancel reservation.',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // CONFIRM BOOKING
  // ------------------------------------------------------------

  Future<void> _confirmBooking() async {
    if (_isProcessing) return;

    if (courseController.text.trim().isEmpty ||
        facultyController.text.trim().isEmpty ||
        timeSlotController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all fields.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final classroomRef = FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.documentId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(classroomRef);

          if (!snapshot.exists) {
            throw Exception('Classroom not found.');
          }

          final data = snapshot.data() as Map<String, dynamic>;

          final status =
              data['status']?.toString().toUpperCase() ?? '';

          if (status != 'TEMPORARILY RESERVED') {
            throw Exception(
              'This classroom is no longer reserved for you.',
            );
          }

          final expiresAt = data['reservationExpiresAt'];

          if (expiresAt is Timestamp) {
            final expiryTime = expiresAt.toDate();

            if (DateTime.now().isAfter(expiryTime)) {
              transaction.update(classroomRef, {
                'status': 'FREE',
                'course': '',
                'facultyName': '',
                'timeSlot': '',
                'reservationExpiresAt': FieldValue.delete(),
              });

              throw Exception(
                'The temporary reservation has expired.',
              );
            }
          }

          transaction.update(classroomRef, {
            'course': courseController.text.trim(),
            'facultyName': facultyController.text.trim(),
            'timeSlot': timeSlotController.text.trim(),
            'status': 'BOOKED',
            'reservationExpiresAt': FieldValue.delete(),
          });
        },
      );

      if (!mounted) return;

      _showBookingSuccessDialog();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      String message = 'Unable to complete booking.';

      if (e.toString().contains('no longer reserved')) {
        message = 'This classroom is no longer reserved for you.';
      } else if (e.toString().contains('expired')) {
        message = 'The temporary reservation has expired.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SUCCESS MESSAGE
  // ------------------------------------------------------------

  void _showBookingSuccessDialog() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Classroom booked successfully.',
        ),
        duration: Duration(seconds: 5),
      ),
    );

    Navigator.pop(context);
  }

  // ------------------------------------------------------------
  // BUILD UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isLeaving && !_isProcessing) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: background,

        // --------------------------------------------------------
        // APP BAR
        // --------------------------------------------------------

        appBar: AppBar(
          title: const Text(
            'Book Classroom',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: darkNavy,
          elevation: 0,
          centerTitle: true,
        ),

        // --------------------------------------------------------
        // BODY
        // --------------------------------------------------------

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: SingleChildScrollView(
            child: Column(
              children: [

                // --------------------------------------------------
                // ROOM HEADER
                // --------------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        darkNavy,
                        primaryNavy,
                      ],
                    ),

                    borderRadius: BorderRadius.circular(17),
                  ),

                  child: Column(
                    children: [

                      const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 30,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'ROOM ${widget.roomNo}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Orange temporary status
                      const Text(
                        'TEMPORARILY RESERVED',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Complete the booking within 5 minutes.',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------
                // COURSE NAME
                // --------------------------------------------------

                TextField(
                  controller: courseController,

                  decoration: InputDecoration(
                    labelText: 'Course Name',

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: primaryNavy,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // --------------------------------------------------
                // FACULTY NAME
                // --------------------------------------------------

                TextField(
                  controller: facultyController,

                  decoration: InputDecoration(
                    labelText: 'Faculty Name',

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: primaryNavy,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // --------------------------------------------------
                // TIME SLOT
                // --------------------------------------------------

                TextField(
                  controller: timeSlotController,

                  decoration: InputDecoration(
                    labelText: 'Time Slot',

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: primaryNavy,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // --------------------------------------------------
                // CONFIRM BOOKING
                // --------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkNavy,
                      foregroundColor: Colors.white,

                      disabledBackgroundColor:
                          primaryNavy,

                      disabledForegroundColor:
                          Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle,
                          ),

                    label: Text(
                      _isProcessing
                          ? 'PROCESSING...'
                          : 'CONFIRM BOOKING',
                    ),

                    onPressed: _isProcessing
                        ? null
                        : _confirmBooking,
                  ),
                ),

                const SizedBox(height: 12),

                // --------------------------------------------------
                // CANCEL RESERVATION
                // --------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,

                      disabledForegroundColor:
                          Colors.red.shade200,

                      side: const BorderSide(
                        color: Colors.red,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    icon: const Icon(
                      Icons.cancel,
                    ),

                    label: const Text(
                      'CANCEL RESERVATION',
                    ),

                    onPressed: _isProcessing
                        ? null
                        : _cancelReservation,
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}