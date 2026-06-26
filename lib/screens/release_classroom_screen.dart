
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReleaseClassroomScreen extends StatelessWidget {
  const ReleaseClassroomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Release Classroom"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classrooms')
            .where('status', isEqualTo: 'BOOKED')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading classrooms"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final classrooms = snapshot.data!.docs;

          if (classrooms.isEmpty) {
            return const Center(
              child: Text("No booked classrooms available"),
            );
          }

          return ListView.builder(
            itemCount: classrooms.length,
            itemBuilder: (context, index) {
              final classroom =
                  classrooms[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "ROOM ${classroom['roomNo']}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text("Course: ${classroom['course'] ?? ''}"),

                      const SizedBox(height: 5),

                      Text("Faculty: ${classroom['facultyName'] ?? ''}"),

                      const SizedBox(height: 5),

                      Text("Time Slot: ${classroom['timeSlot'] ?? ''}"),

                      const SizedBox(height: 5),

                      const Text(
                        "Status: BOOKED",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.all(15),
                          ),
                          onPressed: () async {

                            bool? confirm = await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Confirm Release"),
                                  content: Text(
                                    "Are you sure?\n\nROOM ${classroom['roomNo']} will be released.",
                                  ),
                                  actions: [

                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Text("CANCEL"),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text("RELEASE"),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {

                              await FirebaseFirestore.instance
                                  .collection('classrooms')
                                  .doc(classrooms[index].id)
                                  .update({
                                'status': 'FREE',
                                'course': '',
                                'facultyName': '',
                                'timeSlot': '',
                              });

                              if (context.mounted) {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Success"),
                                      content: Text(
                                        "ROOM ${classroom['roomNo']} has been released successfully.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: const Text(
                            "RELEASE CLASSROOM",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
