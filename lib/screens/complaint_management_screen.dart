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
          backgroundColor: ComplaintPalette.white,
          foregroundColor: ComplaintPalette.darkNavy,
          title: const Text("Complaint Management"),
        ),
        body: ColoredBox(
          color: ComplaintPalette.background,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _actionButton(
                  icon: Icons.assignment_outlined,
                  title: 'View Complaints',
                  subtitle: 'Review, update, and resolve cases.',
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
                  subtitle: 'Monitor case volume and progress.',
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
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: ComplaintPalette.attendanceActionGradient,
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33073B6F),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 27),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
