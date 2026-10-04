import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../screens/complaint_details_screen.dart';
import '../theme/complaint_theme.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final bool isFaculty;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.isFaculty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: ComplaintPalette.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ComplaintPalette.skyBlue),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailsScreen(
                complaint: complaint,
                isFaculty: isFaculty,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: ComplaintPalette.statusColor(complaint.status),
          child: const Icon(
            Icons.report_problem,
            color: ComplaintPalette.white,
          ),
        ),
        title: Text(
          complaint.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: ComplaintPalette.navy,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(complaint.description),
            const SizedBox(height: 6),
            Text(
              'ID: ${complaint.complaintId}',
            ),
            Text(
              'Category: ${complaint.category}',
            ),
            Text(
              'Type: ${complaint.complaintType}',
            ),
            const SizedBox(height: 10),
            Chip(
              label: Text(
                complaint.status,
                style: const TextStyle(
                  color: ComplaintPalette.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: ComplaintPalette.statusColor(complaint.status),
            ),
          ],
        ),
      ),
    );
  }
}
