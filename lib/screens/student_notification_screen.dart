import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';class StudentNotificationScreen extends StatelessWidget {
  const StudentNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("studentId", isEqualTo: uid)
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Notifications",
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {

              final data =
                  snapshot.data!.docs[index].data()
                      as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(

                  leading: CircleAvatar(
                    backgroundColor:
                        data["read"] == true
                            ? Colors.grey
                            : Colors.red,

                    child: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                  ),

                  title: Text(
                    data["title"],
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(data["message"]),

                      const SizedBox(height: 5),

                      Text(
                        "Course : ${data["course"]}",
                      ),

                      Text(
                        "Attendance : ${data["percentage"]} %",
                      ),
                    ],
                  ),

                  onTap: () {

                    snapshot.data!.docs[index]
                        .reference
                        .update({
                      "read": true,
                    });
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