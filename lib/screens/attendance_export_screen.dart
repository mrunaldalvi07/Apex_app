import 'package:flutter/material.dart';

import '../services/attendance_export_service.dart';

class AttendanceExportScreen extends StatefulWidget {
  const AttendanceExportScreen({
    super.key,
  });

  @override
  State<AttendanceExportScreen> createState() =>
      _AttendanceExportScreenState();
}

class _AttendanceExportScreenState
    extends State<AttendanceExportScreen> {
  final AttendanceExportService _exportService =
      AttendanceExportService();

  // ============================================================
  // COLOUR SCHEME
  // ============================================================

  static const Color primaryNavy = Color(0xFF073B6F);
  static const Color darkNavy = Color(0xFF052B52);
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color cyan = Color(0xFF18A8C8);
  static const Color successGreen = Color(0xFF159957);
  static const Color warningOrange = Color(0xFFF39A23);

  // ============================================================
  // DATA
  // ============================================================

  final List<String> branches = [
    'IF',
    'CM',
  ];

  final List<String> years = [
    '1',
    '2',
    '3',
  ];

  final List<String> courses = [
    'OPS',
    'JAVA',
    'PYTHON',
    'DBMS',
    'NETWORKING',
    'DSA',
    'OS',
    'SWE',
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

  bool isGenerating = false;
  bool isExporting = false;

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validate() {
    if (selectedBranch == null ||
        selectedYear == null ||
        selectedCourse == null ||
        selectedMonth == null) {
      _showMessage(
        'Please select Branch, Year, Course and Month.',
        error: true,
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // GENERATE / SAVE
  // ============================================================

  Future<void> _generateSheet() async {
    if (!_validate()) {
      return;
    }

    if (isGenerating || isExporting) {
      return;
    }

    setState(() {
      isGenerating = true;
    });

    try {
      await _exportService.exportAttendanceSheet(
        branch: selectedBranch!,
        year: selectedYear!,
        course: selectedCourse!,
        month: selectedMonth!,
      );

      if (!mounted) return;

      _showMessage(
        'Attendance Excel sheet generated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to generate sheet.\n$e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  // ============================================================
  // EXPORT / SHARE
  // ============================================================

  Future<void> _exportSheet() async {
    if (!_validate()) {
      return;
    }

    if (isGenerating || isExporting) {
      return;
    }

    setState(() {
      isExporting = true;
    });

    try {
      await _exportService.shareAttendanceSheet(
        branch: selectedBranch!,
        year: selectedYear!,
        course: selectedCourse!,
        month: selectedMonth!,
      );

      if (!mounted) return;

      _showMessage(
        'Attendance sheet exported successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to export sheet.\n$e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? Colors.red.shade700 : successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: primaryBlue,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool loading,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              color.withValues(alpha: 0.55),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          children: [
            if (loading)
              const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                icon,
                size: 27,
              ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),

      appBar: AppBar(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Export Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      darkNavy,
                      primaryNavy,
                      primaryBlue,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Export',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Generate and export monthly attendance reports',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SELECTION
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.05,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Report',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _dropdown(
                      label: 'Branch',
                      icon:
                          Icons.account_tree_outlined,
                      value: selectedBranch,
                      items: branches,
                      onChanged: (value) {
                        setState(() {
                          selectedBranch = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    _dropdown(
                      label: 'Year',
                      icon: Icons.school_outlined,
                      value: selectedYear,
                      items: years,
                      onChanged: (value) {
                        setState(() {
                          selectedYear = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    _dropdown(
                      label: 'Course',
                      icon:
                          Icons.menu_book_outlined,
                      value: selectedCourse,
                      items: courses,
                      onChanged: (value) {
                        setState(() {
                          selectedCourse = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    _dropdown(
                      label: 'Month',
                      icon:
                          Icons.calendar_month_outlined,
                      value: selectedMonth,
                      items: months,
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SELECTED REPORT
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: primaryBlue.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _infoRow(
                      'Branch',
                      selectedBranch ?? '-',
                    ),

                    _infoRow(
                      'Year',
                      selectedYear ?? '-',
                    ),

                    _infoRow(
                      'Course',
                      selectedCourse ?? '-',
                    ),

                    _infoRow(
                      'Month',
                      selectedMonth ?? '-',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // ACTIONS
              // ==================================================

              const Text(
                'Actions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: darkNavy,
                ),
              ),

              const SizedBox(height: 12),

              // GENERATE / SAVE
              _actionCard(
                icon: Icons.download_outlined,
                title: 'Generate & Download Sheet',
                subtitle:
                    'Create the Excel attendance report and save it',
                color: primaryBlue,
                loading: isGenerating,
                onTap: _generateSheet,
              ),

              const SizedBox(height: 12),

              // EXPORT / SHARE
              _actionCard(
                icon: Icons.share_outlined,
                title: 'Export Sheet',
                subtitle:
                    'Share the generated attendance report',
                color: cyan,
                loading: isExporting,
                onTap: _exportSheet,
              ),

              const SizedBox(height: 22),

              // ==================================================
              // INFORMATION
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: successGreen.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: successGreen,
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The Excel report contains daily attendance, Present, Absent, Attendance %, and Regular/Detained status. An Overall Summary sheet is also generated.',
                        style: TextStyle(
                          fontSize: 12,
                          color: darkNavy,
                          height: 1.45,
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

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const Text(
            ':',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: darkNavy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}