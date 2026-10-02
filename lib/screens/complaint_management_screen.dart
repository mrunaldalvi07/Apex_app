import 'package:flutter/material.dart';

import 'analytics_screen.dart';
import 'complaint_list_screen.dart';
import '../theme/complaint_theme.dart';

class ComplaintManagementScreen extends StatelessWidget {
  const ComplaintManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ComplaintPalette.theme(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ComplaintPalette.white,
          flexibleSpace: const DecoratedBox(
            decoration:
                BoxDecoration(gradient: ComplaintPalette.primaryGradient),
          ),
          title: const Text("Complaint Management"),
        ),
        body: Container(
          decoration:
              const BoxDecoration(gradient: ComplaintPalette.pageGradient),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _actionButton(
                  icon: Icons.assignment_outlined,
                  title: 'View Complaints',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComplaintListScreen(
                          showOnlyMyComplaints: false,
                          isFaculty: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _actionButton(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ComplaintPalette.attendanceActionGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22073B6F),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
