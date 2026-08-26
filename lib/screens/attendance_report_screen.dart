import 'package:flutter/material.dart';

import '../services/attendance_export_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends State<AttendanceReportScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryNavy = Color(0xFF073B6F);
  static const Color darkNavy = Color(0xFF052B52);
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color cyan = Color(0xFF18A8C8);
  static const Color successGreen = Color(0xFF159957);
  static const Color warningOrange = Color(0xFFF39A23);
  static const Color background = Color(0xFFF5F8FC);

  // ============================================================
  // SERVICE
  // ============================================================

  final AttendanceExportService _exportService =
      AttendanceExportService();

  // ============================================================
  // DROPDOWN DATA
  // ============================================================

  final List<String> _branches = <String>[
    'IT',
    'CM',
    'IF',
    'CO',
    'ME',
    'CE',
    'EE',
  ];

  final List<String> _years = <String>[
    '1 Year',
    '2 Year',
    '3 Year',
  ];

  final List<String> _courses = <String>[
    'Object Oriented Programming',
    'Database Management Systems',
    'Computer Networks',
    'Java Programming',
    'Python Programming',
  ];

  final List<String> _months = <String>[
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

  // ============================================================
  // SELECTED VALUES
  // ============================================================

  String? _selectedBranch;
  String? _selectedYear;
  String? _selectedCourse;
  String? _selectedMonth;

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = false;

  String? _generatedFilePath;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Attendance Reports',
          style: TextStyle(
            color: darkNavy,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(),

                    const SizedBox(height: 16),

                    _buildFilterCard(),

                    const SizedBox(height: 16),

                    _buildReportActions(),

                    if (_generatedFilePath != null) ...[
                      const SizedBox(height: 16),
                      _buildGeneratedFileCard(),
                    ],

                    const SizedBox(height: 20),

          

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryNavy,
            primaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Color(0x22073B6F),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.assessment_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Generate and export date-wise attendance sheets.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE1E8F0),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: primaryBlue,
                size: 21,
              ),

              SizedBox(width: 8),

              Text(
                'Report Filters',
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          _buildDropdown(
            label: 'Branch',
            value: _selectedBranch,
            items: _branches,
            icon: Icons.account_balance_rounded,
            onChanged: (String? value) {
              setState(() {
                _selectedBranch = value;
              });
            },
          ),

          const SizedBox(height: 12),

          _buildDropdown(
            label: 'Year',
            value: _selectedYear,
            items: _years,
            icon: Icons.calendar_today_rounded,
            onChanged: (String? value) {
              setState(() {
                _selectedYear = value;
              });
            },
          ),

          const SizedBox(height: 12),

          _buildDropdown(
            label: 'Course',
            value: _selectedCourse,
            items: _courses,
            icon: Icons.school_rounded,
            onChanged: (String? value) {
              setState(() {
                _selectedCourse = value;
              });
            },
          ),

          const SizedBox(height: 12),

          _buildDropdown(
            label: 'Month',
            value: _selectedMonth,
            items: _months,
            icon: Icons.date_range_rounded,
            onChanged: (String? value) {
              setState(() {
                _selectedMonth = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAFE DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    // IMPORTANT:
    // Make a guaranteed non-null copy.
    final List<String> safeItems =
        List<String>.from(items);

    // IMPORTANT:
    // Never pass a value which is not present
    // in the dropdown items.
    String? safeValue;

    if (value != null) {
      for (final String item in safeItems) {
        if (item == value) {
          safeValue = item;
          break;
        }
      }
    }

    return DropdownButtonFormField<String>(
      initialValue: safeValue,

      isExpanded: true,

      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: primaryNavy,
      ),

      decoration: InputDecoration(
        labelText: label,

        labelStyle: const TextStyle(
          color: darkNavy,
          fontSize: 13,
        ),

        prefixIcon: Icon(
          icon,
          color: primaryBlue,
          size: 21,
        ),

        filled: true,

        fillColor: const Color(0xFFF9FBFD),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),

          borderSide: const BorderSide(
            color: Color(0xFFE0E7EF),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),

          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),
      ),

      items: safeItems.map(
        (String item) {
          return DropdownMenuItem<String>(
            value: item,

            child: Text(
              item,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,

              style: const TextStyle(
                color: darkNavy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ).toList(),

      onChanged:
          safeItems.isEmpty
              ? null
              : onChanged,
    );
  }

  // ============================================================
  // REPORT ACTIONS
  // ============================================================

  Widget _buildReportActions() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE1E8F0),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: primaryBlue,
                size: 21,
              ),

              SizedBox(width: 8),

              Text(
                'Report Actions',
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildActionButton(
            icon: Icons.table_view_rounded,
            title: 'Generate Sheet',
            subtitle:
                'Create the attendance Excel sheet',
            iconColor: successGreen,
            onTap: _generateSheet,
          ),

          const SizedBox(height: 10),

          _buildActionButton(
            icon: Icons.download_rounded,
            title: 'Download Sheet',
            subtitle:
                'Generate and save the attendance sheet',
            iconColor: primaryBlue,
            onTap: _downloadSheet,
          ),

          const SizedBox(height: 10),

          _buildActionButton(
            icon: Icons.share_rounded,
            title: 'Export Sheet',
            subtitle:
                'Share the generated attendance sheet',
            iconColor: cyan,
            onTap: _exportSheet,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),

        onTap: _loading ? null : onTap,

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: const Color(0xFFFAFCFE),

            borderRadius:
                BorderRadius.circular(14),

            border: Border.all(
              color: const Color(0xFFE3EAF1),
            ),
          ),

          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,

                decoration: BoxDecoration(
                  color:
                      iconColor.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: primaryNavy,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GENERATED FILE CARD
  // ============================================================

  Widget _buildGeneratedFileCard() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: const Color(0xFFB9E5CE),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: successGreen,
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Attendance sheet generated successfully.',
              style: TextStyle(
                color: Color(0xFF126B3D),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATE FILTERS
  // ============================================================

  bool _validateFilters() {
    if (_selectedBranch == null ||
        _selectedYear == null ||
        _selectedCourse == null ||
        _selectedMonth == null) {
      _showMessage(
        'Please select Branch, Year, Course and Month.',
        isError: true,
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // GENERATE
  // ============================================================

  Future<void> _generateSheet() async {
    if (!_validateFilters()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final String filePath =
          await _exportService
              .exportAttendanceSheet(
        branch: _selectedBranch!,
        year: _selectedYear!,
        course: _selectedCourse!,
        month: _selectedMonth!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedFilePath = filePath;
      });

      _showMessage(
        'Attendance sheet generated successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to generate sheet: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================

  Future<void> _downloadSheet() async {
    if (!_validateFilters()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final String filePath =
          await _exportService
              .exportAttendanceSheet(
        branch: _selectedBranch!,
        year: _selectedYear!,
        course: _selectedCourse!,
        month: _selectedMonth!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedFilePath = filePath;
      });

      _showMessage(
        'Attendance sheet saved successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to save sheet: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // EXPORT / SHARE
  // ============================================================

  Future<void> _exportSheet() async {
    if (!_validateFilters()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _exportService
          .shareAttendanceSheet(
        branch: _selectedBranch!,
        year: _selectedYear!,
        course: _selectedCourse!,
        month: _selectedMonth!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Attendance sheet exported successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to export sheet: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor:
              isError
                  ? Colors.red.shade700
                  : successGreen,

          behavior:
              SnackBarBehavior.floating,

          margin:
              const EdgeInsets.all(16),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
  }
}