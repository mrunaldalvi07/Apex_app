import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import '../theme/complaint_theme.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final Complaint complaint;
  final bool isFaculty;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaint,
    required this.isFaculty,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late TextEditingController remarkController;
  late String selectedStatus;
  late String originalRemark;
  late String originalStatus;
  bool hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    remarkController = TextEditingController(
      text: widget.complaint.facultyRemark,
    );
    originalRemark = widget.complaint.facultyRemark;
    selectedStatus = widget.complaint.status;
    originalStatus = widget.complaint.status;

    remarkController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    setState(() {
      hasUnsavedChanges = remarkController.text != originalRemark ||
          selectedStatus != originalStatus;
    });
  }

  Future<bool> _onWillPop() async {
    if (!hasUnsavedChanges) {
      return true;
    }

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                'You have unsaved changes. Do you want to save them before leaving?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Discard'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(false);
                    await _saveChanges();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _saveChanges() async {
    try {
      if (remarkController.text != originalRemark) {
        await ComplaintService().updateFacultyRemark(
          widget.complaint.complaintId,
          remarkController.text.trim(),
        );
      }

      if (selectedStatus != originalStatus) {
        await ComplaintService().updateComplaintStatus(
          widget.complaint.complaintId,
          selectedStatus,
        );
      }

      if (mounted) {
        setState(() {
          originalRemark = remarkController.text;
          originalStatus = selectedStatus;
          hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
      }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      },
      child: Theme(
        data: ComplaintPalette.theme(context),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: ComplaintPalette.white,
            flexibleSpace: const DecoratedBox(
              decoration:
                  BoxDecoration(gradient: ComplaintPalette.primaryGradient),
            ),
            title: const Text('Complaint Details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: Container(
            decoration:
                const BoxDecoration(gradient: ComplaintPalette.pageGradient),
            child: SingleChildScrollView(
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
                        color: ComplaintPalette.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor:
                        ComplaintPalette.statusColor(complaint.status),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: ComplaintPalette.skyBlue),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complaint Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Text('Complaint ID: ${complaint.complaintId}'),
                          const SizedBox(height: 10),
                          Text('Category: ${complaint.category}'),
                          const SizedBox(height: 10),
                          Text('Complaint Type: ${complaint.complaintType}'),
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: ComplaintPalette.skyBlue),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: ComplaintPalette.skyBlue),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.isFaculty) ...[
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: ComplaintPalette.skyBlue),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Faculty/Admin Update (Optional)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: remarkController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Write your update here...',
                                hintText: 'Provide feedback or status update',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              onChanged: (_) => _checkForChanges(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: ComplaintPalette.skyBlue),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Update Complaint Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              initialValue: selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
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
                              onChanged: (value) {
                                setState(() {
                                  selectedStatus = value!;
                                  _checkForChanges();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: hasUnsavedChanges ? _saveChanges : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text(
                          'Delete Complaint',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B3A3A),
                          foregroundColor: ComplaintPalette.white,
                        ),
                        onPressed: () async {
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Delete Complaint'),
                                content: const Text(
                                  'Are you sure you want to delete this complaint?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            await ComplaintService().deleteComplaint(
                              complaint.complaintId,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
