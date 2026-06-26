import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../screens/complaint_details_screen.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final bool isFaculty;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.isFaculty,
  });

  Color getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;

      case 'In Progress':
        return Colors.blue;
        
      case 'Pending':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
          backgroundColor: getStatusColor(
            complaint.status,
          ),
          child: const Icon(
            Icons.report_problem,
            color: Colors.white,
          ),
        ),

        title: Text(
          complaint.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: getStatusColor(
                complaint.status,
              ),
            ),
          ],
        ),
      ),
    );
  }
}