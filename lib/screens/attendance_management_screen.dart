import 'package:flutter/material.dart';

import 'faculty_live_attendance_screen.dart';
import 'attendance_report_screen.dart';
import 'detention_list_screen.dart';

class AttendanceManagementScreen extends StatelessWidget {
  const AttendanceManagementScreen({
    super.key,
  });

  // ============================================================
  // APEX COLOUR SCHEME
  // ============================================================

  static const Color primaryNavy =
      Color(0xFF073B6F);

  static const Color darkNavy =
      Color(0xFF052B52);

  static const Color primaryBlue =
      Color(0xFF0B6EAA);

  static const Color cyan =
      Color(0xFF18A8C8);

  static const Color successGreen =
      Color(0xFF159957);

  static const Color warningOrange =
      Color(0xFFF39A23);

  static const Color background =
      Color(0xFFF5F8FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: darkNavy,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Attendance Management',
          style: TextStyle(
            color: darkNavy,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              // ==================================================
              // HEADER CARD
              // ==================================================

              _buildHeaderCard(),

              const SizedBox(height: 18),

              // ==================================================
              // ATTENDANCE ACTIONS
              // ==================================================

              const Text(
                'Attendance Actions',
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // START ATTENDANCE SESSION
              // ==================================================

              _buildActionCard(
                context: context,

                icon:
                    Icons.play_circle_fill_rounded,

                title:
                    'Start Attendance Session',

                subtitle:
                    'Start a new live attendance session.',

                iconColor:
                    successGreen,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const FacultyLiveAttendanceScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // ATTENDANCE REPORTS
              // ==================================================

              _buildActionCard(
                context: context,

                icon:
                    Icons.assessment_rounded,

                title:
                    'Attendance Reports',

                subtitle:
                    'Generate, download and export attendance sheets.',

                iconColor:
                    primaryBlue,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AttendanceReportScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // DETENTION MANAGEMENT
              // ==================================================

              _buildActionCard(
                context: context,

                icon:
                    Icons.warning_amber_rounded,

                title:
                    'Detention Management',

                subtitle:
                    'Generate and manage the detention list.',

                iconColor:
                    warningOrange,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const DetentionListScreen(
                        branch: '',
                        year: '',
                        course: '',
                        month: '',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // FOOTER
              // ==================================================

              Center(
                child: Text(
                  'APEX • Attendance Management',
                  style: TextStyle(
                    color:
                        darkNavy.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER CARD
  // ============================================================

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            primaryNavy,
            primaryBlue,
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color:
                Color(0x22073B6F),

            blurRadius: 14,

            offset:
                Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        children: [
          // ====================================================
          // ICON
          // ====================================================

          Container(
            height: 56,
            width: 56,

            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withOpacity(0.15),

              borderRadius:
                  BorderRadius.circular(15),
            ),

            child: const Icon(
              Icons.fact_check_rounded,

              color:
                  Colors.white,

              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          // ====================================================
          // TEXT
          // ====================================================

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Attendance Management',

                  style: TextStyle(
                    color:
                        Colors.white,

                    fontSize: 19,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Manage attendance sessions, reports and detention.',

                  style: TextStyle(
                    color:
                        Colors.white70,

                    fontSize: 12,

                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(17),

        child: Container(
          padding:
              const EdgeInsets.all(16),

          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(17),

            border:
                Border.all(
              color:
                  const Color(0xFFE1E8F0),
            ),

            boxShadow:
                const [
              BoxShadow(
                color:
                    Color(0x0D000000),

                blurRadius:
                    9,

                offset:
                    Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            children: [
              // ================================================
              // ACTION ICON
              // ================================================

              Container(
                height: 50,
                width: 50,

                decoration:
                    BoxDecoration(
                  color:
                      iconColor
                          .withOpacity(0.10),

                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: Icon(
                  icon,

                  color:
                      iconColor,

                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              // ================================================
              // ACTION TEXT
              // ================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style:
                          const TextStyle(
                        color:
                            darkNavy,

                        fontSize:
                            14.5,

                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,

                      style:
                          const TextStyle(
                        color:
                            Colors.black54,

                        fontSize:
                            11.5,

                        height:
                            1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ================================================
              // ARROW
              // ================================================

              Container(
                height: 32,
                width: 32,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFF1F6FA),

                  borderRadius:
                      BorderRadius.circular(9),
                ),

                child: const Icon(
                  Icons
                      .arrow_forward_ios_rounded,

                  color:
                      primaryNavy,

                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}