import 'package:flutter/material.dart';

import 'book_classroom_screen.dart';
import 'view_classroom_screen.dart';
import 'release_classroom_screen.dart';

class ClassroomManagementScreen extends StatelessWidget {
  const ClassroomManagementScreen({super.key});

  // APEX UI Colors
  static const Color darkNavy = Color(0xFF163B73);
  static const Color primaryNavy = Color(0xFF2F6DB2);
  static const Color background = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        title: const Text(
          "Classroom Scheduler",
          style: TextStyle(
            color: darkNavy,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
        elevation: 0,
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ====================================================
              // TOP HEADER CARD
              // ====================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      darkNavy,
                      primaryNavy,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: darkNavy.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    // ------------------------------------------------
                    // HEADER ICON
                    // ------------------------------------------------
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.meeting_room_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ------------------------------------------------
                    // HEADER TEXT
                    // ------------------------------------------------
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Classroom Scheduler",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Manage classroom bookings and availability.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ====================================================
              // SECTION TITLE
              // ====================================================
              const Text(
                "Classroom Actions",
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // ====================================================
              // BOOK CLASSROOM
              // ====================================================
              _classroomActionCard(
                icon: Icons.book_online_rounded,
                title: "Book Classroom",
                description: "Reserve a classroom for your session.",
                iconBackground: const Color(0xFFE5F5EE),
                iconColor: const Color(0xFF159957),
                onPressed: () {
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

              // ====================================================
              // VIEW CLASSROOMS
              // ====================================================
              _classroomActionCard(
                icon: Icons.visibility_rounded,
                title: "View Classrooms",
                description: "Check classroom availability and status.",
                iconBackground: const Color(0xFFE5F0F8),
                iconColor: primaryNavy,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClassroomScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // ====================================================
              // RELEASE CLASSROOM
              // ====================================================
              _classroomActionCard(
                icon: Icons.logout_rounded,
                title: "Release Classroom",
                description: "Release a currently booked classroom.",
                iconBackground: const Color(0xFFFFF4E3),
                iconColor: const Color(0xFFE79A20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReleaseClassroomScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ====================================================
              // FOOTER
              // ====================================================
              const Center(
                child: Text(
                  "APEX • Classroom Management",
                  style: TextStyle(
                    color: Color(0xFF8EA0B5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // COMPACT CLASSROOM ACTION CARD
  // ==============================================================

  Widget _classroomActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE1E5EA),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [

              // ----------------------------------------------------
              // ICON BOX
              // ----------------------------------------------------
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 27,
                ),
              ),

              const SizedBox(width: 15),

              // ----------------------------------------------------
              // TITLE + DESCRIPTION
              // ----------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A8491),
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ----------------------------------------------------
              // ARROW BUTTON
              // ----------------------------------------------------
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: darkNavy,
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}