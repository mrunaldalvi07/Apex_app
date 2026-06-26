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
  State<BookingFormScreen> createState() =>
      _BookingFormScreenState();
}

class _BookingFormScreenState
    extends State<BookingFormScreen> {
  final TextEditingController courseController =
      TextEditingController();

  final TextEditingController facultyController =
      TextEditingController();

  final TextEditingController timeSlotController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Classroom"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Room Number: ${widget.roomNo}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: "Course Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: facultyController,
              decoration: const InputDecoration(
                labelText: "Faculty Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: timeSlotController,
              decoration: const InputDecoration(
                labelText: "Time Slot",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (courseController.text.isEmpty ||
                      facultyController.text.isEmpty ||
                      timeSlotController.text.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content:
                            Text("Please fill all fields"),
                      ),
                    );

                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('classrooms')
                      .doc(widget.documentId)
                      .update({
                    'course': courseController.text,
                    'facultyName':
                        facultyController.text,
                    'timeSlot':
                        timeSlotController.text,
                    'status': 'BOOKED',
                  });

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Classroom Booked Successfully",
                      ),
                    ),
                  );

                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  "BOOK CLASSROOM",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}