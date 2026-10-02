import 'package:flutter/material.dart';

import 'book_classroom_screen.dart';
import 'view_classroom_screen.dart';
import 'release_classroom_screen.dart';

class ClassroomManagementScreen extends StatelessWidget {
  const ClassroomManagementScreen({super.key});

  // APEX Classroom UI Colors
  static const Color darkNavy = Color(0xFF163B73);
  static const Color primaryNavy = Color(0xFF2F6DB2);
  static const Color background = Color(0xFFF5F0EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          "Classroom Scheduler",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // --------------------------------------------------
            // BOOK CLASSROOM
            // --------------------------------------------------

            _classroomButton(
              context: context,
              icon: Icons.book_online,
              title: "Book Classroom",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const BookClassroomScreen(
                      role: '',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // VIEW CLASSROOMS
            // --------------------------------------------------

            _classroomButton(
              context: context,
              icon: Icons.visibility,
              title: "View Classrooms",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClassroomScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // RELEASE CLASSROOM
            // --------------------------------------------------

            _classroomButton(
              context: context,
              icon: Icons.logout,
              title: "Release Classroom",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ReleaseClassroomScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // COMMON CLASSROOM BUTTON
  // ------------------------------------------------------------

  Widget _classroomButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,

      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              darkNavy,
              primaryNavy,
            ],
          ),

          borderRadius: BorderRadius.circular(12),

          boxShadow: [
            BoxShadow(
              color: darkNavy.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: ElevatedButton.icon(
          onPressed: onPressed,

          icon: Icon(
            icon,
            color: Colors.white,
          ),

          label: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,

            shadowColor: Colors.transparent,

            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}