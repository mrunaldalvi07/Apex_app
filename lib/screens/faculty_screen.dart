import 'package:flutter/material.dart';
import 'view_classroom_screen.dart';
import 'book_classroom_screen.dart';
import 'release_classroom_screen.dart';

class FacultyScreen extends StatelessWidget {
  const FacultyScreen({super.key});

  static const Color darkNavy = Color(0xFF163B73);
  static const Color primaryNavy = Color(0xFF2F6DB2);
  static const Color background = Color(0xFFF5F0EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          "Classroom Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // CLASSROOM MODULE HEADER
            Container(
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
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Classroom Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "View, book and release classrooms",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Classroom Actions",
              style: TextStyle(
                color: darkNavy,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // VIEW CLASSROOM
            _classroomCard(
              context,
              Icons.visibility,
              "View Classroom",
              "View available and booked classrooms",
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClassroomScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // BOOK CLASSROOM
            _classroomCard(
              context,
              Icons.book_online,
              "Book Classroom",
              "Reserve a classroom",
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookClassroomScreen(
                      role: '',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // RELEASE CLASSROOM
            _classroomCard(
              context,
              Icons.lock_open,
              "Release Classroom",
              "Release booked classrooms",
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReleaseClassroomScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _classroomCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [

              // ICON
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ARROW
              const Icon(
                Icons.arrow_forward_ios,
                color: darkNavy,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}