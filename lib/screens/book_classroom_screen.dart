import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_form_screen.dart';

class BookClassroomScreen extends StatelessWidget {
  final String role;

  const BookClassroomScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {

    // Security Check
    if (role == "student") {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Access Denied"),
        ),
        body: const Center(
          child: Text(
            "Students are not allowed to book classrooms.",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Classroom"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classrooms')
            .where('status', isEqualTo: 'FREE')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading classrooms"),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final classrooms = snapshot.data!.docs;

          if (classrooms.isEmpty) {
            return const Center(
              child: Text(
                "No free classrooms available",
              ),
            );
          }

          return ListView.builder(
            itemCount: classrooms.length,
            itemBuilder: (context, index) {
              final classroom =
                  classrooms[index].data()
                      as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(
                    Icons.class_,
                    color: Colors.green,
                  ),
                  title: Text(
                    "ROOM ${classroom['roomNo']}",
                  ),
                  subtitle: const Text(
                    "Available for booking",
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingFormScreen(
                          roomNo:
                              classroom['roomNo'],
                          documentId:
                              classrooms[index].id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}