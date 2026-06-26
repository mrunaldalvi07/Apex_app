import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final Complaint complaint;
  final bool isFaculty;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaint,
    required this.isFaculty,
  });

  @override
  State<ComplaintDetailsScreen> createState() =>
      _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState
    extends State<ComplaintDetailsScreen> {
  late TextEditingController remarkController;

  @override
  void initState() {
    super.initState();
    remarkController = TextEditingController(
      text: widget.complaint.facultyRemark,
    );
  }

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
  void dispose() {
    remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

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

            const SizedBox(height: 20),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complaint Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    Text(
                      'Complaint ID: ${complaint.complaintId}',
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Category: ${complaint.category}',
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Complaint Type: ${complaint.complaintType}',
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Created At: '
                      '${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year} '
                      '${complaint.createdAt.hour}:${complaint.createdAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    Text(
                      complaint.description,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Faculty Update',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    Text(
                      complaint.facultyRemark.isEmpty
                          ? 'No updates available.'
                          : complaint.facultyRemark,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.isFaculty) ...[
              const SizedBox(height: 20),

              const Text(
                'Update Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: complaint.status,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Pending',
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: 'In Progress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: 'Resolved',
                    child: Text('Resolved'),
                  ),
                ],
                onChanged: (value) async {
                  await ComplaintService()
                      .updateComplaintStatus(
                    complaint.complaintId,
                    value!,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),

              const SizedBox(height: 20),

              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText:
                      'Faculty Update (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Update'),
                  onPressed: () async {
                    await ComplaintService()
                        .updateFacultyRemark(
                      complaint.complaintId,
                      remarkController.text.trim(),
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Faculty update saved',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text(
                    'Delete Complaint',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    bool? confirm =
                        await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text(
                            'Delete Complaint',
                          ),
                          content: const Text(
                            'Are you sure you want to delete this complaint?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  false,
                                );
                              },
                              child: const Text(
                                'Cancel',
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  true,
                                );
                              },
                              child: const Text(
                                'Delete',
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await ComplaintService()
                          .deleteComplaint(
                        complaint.complaintId,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}