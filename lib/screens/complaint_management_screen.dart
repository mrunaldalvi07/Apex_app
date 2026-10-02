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
                  subtitle: 'Review, update, and resolve cases.',
                  gradient: ComplaintPalette.primaryGradient,
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
                  gradient: const LinearGradient(
                    colors: [ComplaintPalette.teal, ComplaintPalette.cyan],
                  ),
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
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 78,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(subtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
