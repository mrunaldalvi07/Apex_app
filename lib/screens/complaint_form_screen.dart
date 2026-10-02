import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import '../theme/complaint_theme.dart';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  String selectedCategory = 'Infrastructure';
  String selectedType = 'Individual';

  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

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
          title: const Text('Register Complaint'),
          centerTitle: true,
        ),
        body: Container(
          decoration:
              const BoxDecoration(gradient: ComplaintPalette.pageGradient),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell us what needs attention',
                  style: TextStyle(
                    color: ComplaintPalette.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const SizedBox(height: 24),
                const Text(
                  'Category',
                  style: TextStyle(
                    color: ComplaintPalette.darkNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Infrastructure',
                      child: Text('Infrastructure'),
                    ),
                    DropdownMenuItem(
                        value: 'Academic', child: Text('Academic')),
                    DropdownMenuItem(value: 'Hostel', child: Text('Hostel')),
                    DropdownMenuItem(value: 'Canteen', child: Text('Canteen')),
                    DropdownMenuItem(
                        value: 'Transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Complaint Type',
                  style: TextStyle(
                    color: ComplaintPalette.darkNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Individual',
                      child: Text('Individual'),
                    ),
                    DropdownMenuItem(value: 'Group', child: Text('Group')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Complaint Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Complaint Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Submit Complaint',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            String title = titleController.text.trim();

                            String description =
                                descriptionController.text.trim();

                            if (title.isEmpty || description.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please fill all fields')),
                              );
                              return;
                            }
                            setState(() => _isSubmitting = true);

                            final complaint = Complaint(
                              complaintId:
                                  ComplaintService().createComplaintId(),
                              title: title,
                              description: description,
                              category: selectedCategory,
                              complaintType: selectedType,
                              status: 'Pending',
                              createdAt: DateTime.now(),
                              userId: '',
                              facultyRemark: '',
                            );

                            try {
                              await ComplaintService().addComplaint(complaint);
                              titleController.clear();
                              descriptionController.clear();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Complaint submitted successfully.'),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Unable to submit: $error')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
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
