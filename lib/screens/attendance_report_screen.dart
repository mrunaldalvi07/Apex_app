import 'package:flutter/material.dart';

import 'attendance_sheet_preview_screen.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends State<AttendanceReportScreen> {
  static const Color primaryNavy = Color(0xFF073B6F);
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color cyan = Color(0xFF18A8C8);
  static const Color background = Color(0xFFF5F8FC);

  final List<String> branches = [
    'IT',
    'CM',
    'IF',
    'CO',
    'ME',
    'CE',
    'EE',
  ];

  final List<String> years = [
    '1',
    '2',
    '3',
  ];

  final List<String> courses = [
    'Object Oriented Programming',
    'Database Management Systems',
    'Computer Networks',
    'Java Programming',
    'Python Programming',
  ];

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String? selectedBranch;
  String? selectedYear;
  String? selectedCourse;
  String? selectedMonth;

  bool isOpeningPreview = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPreview() async {
    if (selectedBranch == null ||
        selectedYear == null ||
        selectedCourse == null ||
        selectedMonth == null) {
      _showMessage('Please select all report details.');
      return;
    }

    setState(() {
      isOpeningPreview = true;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceSheetPreview(
            branch: selectedBranch!,
            year: selectedYear!,
            course: selectedCourse!,
            month: selectedMonth!,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to open preview: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isOpeningPreview = false;
        });
      }
    }
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: primaryBlue,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: primaryBlue,
                width: 1.5,
              ),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Attendance Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      primaryNavy,
                      primaryBlue,
                      cyan,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Generate Attendance Report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Select report details and preview student attendance.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              _buildDropdown(
                label: 'Branch',
                hint: 'Select Branch',
                items: branches,
                value: selectedBranch,
                icon: Icons.account_tree_outlined,
                onChanged: (value) {
                  setState(() {
                    selectedBranch = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              _buildDropdown(
                label: 'Academic Year',
                hint: 'Select Year',
                items: years,
                value: selectedYear,
                icon: Icons.school_outlined,
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              _buildDropdown(
                label: 'Course',
                hint: 'Select Course',
                items: courses,
                value: selectedCourse,
                icon: Icons.menu_book_outlined,
                onChanged: (value) {
                  setState(() {
                    selectedCourse = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              _buildDropdown(
                label: 'Month',
                hint: 'Select Month',
                items: months,
                value: selectedMonth,
                icon: Icons.calendar_month_outlined,
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isOpeningPreview
                      ? null
                      : _openPreview,
                  icon: isOpeningPreview
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.visibility_outlined,
                        ),
                  label: const Text(
                    'Preview Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: primaryBlue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Preview displays the selected month. The Excel workbook contains all 12 monthly tabs. You can edit attendance before downloading or exporting.',
                        style: TextStyle(
                          color: primaryNavy,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}