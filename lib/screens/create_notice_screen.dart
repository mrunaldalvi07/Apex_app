import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/notice.dart';
import '../services/notice_service.dart';

class CreateNoticeScreen extends StatefulWidget {
  final Notice? notice;

  const CreateNoticeScreen({super.key, this.notice});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool faculty = false;
  bool itStudents = false;
  bool cmStudents = false;

  bool isSaving = false;

  bool get isEditing => widget.notice != null;

  // Notice module's standard colour palette
  static const Color primaryBlue = Color(0xFF0C447B);
  static const Color headingColor = Color(0xFF0F2C59);
  static const Color mutedColor = Color(0xFF708090);
  static const Color borderColor = Color(0xFFE1E8F0);
  static const Color backgroundColor = Color(0xFFF4F7FC);

  @override
  void initState() {
    super.initState();

    final notice = widget.notice;

    if (notice != null) {
      _titleController.text = notice.title;
      _descriptionController.text = notice.description;

      final recipients =
          notice.recipients.map((value) => value.trim().toLowerCase()).toSet();

      faculty = recipients.contains('faculty');
      itStudents = recipients.contains('it') || recipients.contains('if');
      cmStudents = recipients.contains('cm');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // GET CURRENT USER DETAILS
  // ------------------------------------------------------------

  Future<Map<String, String?>> _getCurrentUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to publish a notice.');
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    return {
      'uid': user.uid,
      'name':
          userData?['name']?.toString() ?? user.displayName ?? 'Unknown User',
    };
  }

  // ------------------------------------------------------------
  // SAVE NOTICE
  // ------------------------------------------------------------

  Future<void> _saveNotice() async {
    if (!_formKey.currentState!.validate()) return;

    final recipients = <String>[];

    if (faculty) recipients.add('faculty');
    if (itStudents) recipients.add('IT');
    if (cmStudents) recipients.add('CM');

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one recipient.'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final userDetails = await _getCurrentUserDetails();

      final existingNotice = widget.notice;

      final noticeData = Notice(
        id: existingNotice?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: existingNotice?.createdBy ?? userDetails['name'],
        createdByUid: existingNotice?.createdByUid ?? userDetails['uid'],
        createdAt: existingNotice?.createdAt,
        lastUpdated: DateTime.now(),
        recipients: recipients,

        // Preserve previously uploaded attachments.
        attachmentUrls: existingNotice?.attachmentUrls ?? [],

        pinned: existingNotice?.pinned ?? false,
      );

      if (isEditing) {
        await NoticeService.updateNotice(
          existingNotice!.id!,
          noticeData,
        );
      } else {
        await NoticeService.createNotice(
          noticeData,
          [],
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Notice updated successfully.'
                : 'Notice published successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save notice: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: primaryBlue, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: headingColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: mutedColor),
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildRecipientTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: isSaving ? null : onChanged,
      activeColor: primaryBlue,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        title,
        style: const TextStyle(
          color: headingColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: mutedColor, fontSize: 12),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: headingColor,
        title: Text(
          isEditing ? 'Edit Notice' : 'Create Notice',
          style: const TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing
                          ? 'Update the notice details below.'
                          : 'Share an important update with your college community.',
                      style: const TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TITLE
                    _buildSectionCard(
                      title: 'Notice Title',
                      subtitle: 'Give your notice a clear heading.',
                      icon: Icons.title,
                      child: _buildTextField(
                        controller: _titleController,
                        hint: 'Enter notice title',
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a notice title.';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // DESCRIPTION
                    _buildSectionCard(
                      title: 'Description',
                      subtitle: 'Provide the complete notice information.',
                      icon: Icons.description_outlined,
                      child: _buildTextField(
                        controller: _descriptionController,
                        hint: 'Write your notice here...',
                        maxLines: 7,
                        maxLength: 5000,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the notice description.';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // RECIPIENTS
                    _buildSectionCard(
                      title: 'Recipients',
                      subtitle: 'Select who should receive this notice.',
                      icon: Icons.people_outline,
                      child: Column(
                        children: [
                          _buildRecipientTile(
                            title: 'Faculty',
                            subtitle: 'All faculty members',
                            value: faculty,
                            onChanged: (value) {
                              setState(() => faculty = value ?? false);
                            },
                          ),
                          const Divider(height: 1, color: borderColor),
                          _buildRecipientTile(
                            title: 'IT Department',
                            subtitle: 'IT students and IT class representative',
                            value: itStudents,
                            onChanged: (value) {
                              setState(
                                () => itStudents = value ?? false,
                              );
                            },
                          ),
                          const Divider(height: 1, color: borderColor),
                          _buildRecipientTile(
                            title: 'CM Department',
                            subtitle: 'CM students and CM class representative',
                            value: cmStudents,
                            onChanged: (value) {
                              setState(
                                () => cmStudents = value ?? false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveNotice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              primaryBlue.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditing
                                        ? Icons.save_outlined
                                        : Icons.send_outlined,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    isEditing
                                        ? 'Update Notice'
                                        : 'Publish Notice',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
