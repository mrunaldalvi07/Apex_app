import 'package:flutter/material.dart';
import 'view_classroom_screen.dart';
import 'book_classroom_screen.dart';
import 'release_classroom_screen.dart';

class FacultyScreen extends StatelessWidget {
  const FacultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // View Classroom
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: const Icon(
                  Icons.visibility,
                  size: 40,
                  color: Colors.blue,
                ),
                title: const Text(
                  "View Classroom",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "View available and booked classrooms",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClassroomScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Book Classroom
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: const Icon(
                  Icons.book_online,
                  size: 40,
                  color: Colors.green,
                ),
                title: const Text(
                  "Book Classroom",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Reserve a classroom",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookClassroomScreen(role: '',),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Release Classroom
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: const Icon(
                  Icons.lock_open,
                  size: 40,
                  color: Colors.red,
                ),
                title: const Text(
                  "Release Classroom",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Release booked classrooms",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReleaseClassroomScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}