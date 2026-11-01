import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/attendance_export_service.dart';

class AttendanceSheetPreview extends StatefulWidget {
  final String branch;
  final String year;
  final String course;
  final String month;

  const AttendanceSheetPreview({
    super.key,
    required this.branch,
    required this.year,
    required this.course,
    required this.month,
  });

  @override
  State<AttendanceSheetPreview> createState() =>
      _AttendanceSheetPreviewState();
}

class _AttendanceSheetPreviewState
    extends State<AttendanceSheetPreview> {
  static const Color primaryNavy = Color(0xFF073B6F);
  static const Color darkNavy = Color(0xFF052B52);
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color cyan = Color(0xFF18A8C8);
  static const Color successGreen = Color(0xFF159957);
  static const Color warningOrange = Color(0xFFF39A23);
  static const Color background = Color(0xFFF5F8FC);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final AttendanceExportService _exportService =
      AttendanceExportService();

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> sessions = [];

  // Key format: sessionId::studentId
  final Map<String, bool> editedMarks = {};

  bool isLoading = true;
  bool isSaving = false;
  bool isDownloading = false;
  bool isExporting = false;

  String? generatedFilePath;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  DateTime? _getDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _isPresent(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;

    final status = value.toString().toLowerCase().trim();

    return status == 'present' ||
        status == 'p' ||
        status == 'true';
  }

  Future<void> _loadAttendance() async {
    try {
      setState(() {
        isLoading = true;
      });

      final studentSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('branch', isEqualTo: widget.branch)
          .where('year', isEqualTo: widget.year)
          .get();

      final loadedStudents =
          studentSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'rollNo': data['rollNo'] ?? '',
        };
      }).toList();

      loadedStudents.sort((a, b) {
        return a['rollNo']
            .toString()
            .compareTo(b['rollNo'].toString());
      });

      final sessionSnapshot = await _firestore
          .collection('live_sessions')
          .where('branch', isEqualTo: widget.branch)
          .where('year', isEqualTo: widget.year)
          .where('course', isEqualTo: widget.course)
          .where('status', isEqualTo: 'ended')
          .get();

      final monthNumber = _monthNumber(widget.month);

      final loadedSessions =
          sessionSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'date': _getDate(data['createdAt']),
        };
      }).where((session) {
        final date = session['date'] as DateTime?;

        return date != null &&
            date.month == monthNumber;
      }).toList();

      loadedSessions.sort((a, b) {
        return (a['date'] as DateTime)
            .compareTo(b['date'] as DateTime);
      });

      if (!mounted) return;

      setState(() {
        students = loadedStudents;
        sessions = loadedSessions;
        isLoading = false;
      });

      // Generate the annual workbook once for this preview.
      await _generateWorkbook();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Unable to load attendance: $e');
    }
  }

  int _monthNumber(String month) {
    const monthNames = [
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

    final index = monthNames.indexOf(month);

    return index == -1 ? DateTime.now().month : index + 1;
  }

  Future<bool> _getMark(
    String sessionId,
    String studentId,
  ) async {
    final key = '$sessionId::$studentId';

    if (editedMarks.containsKey(key)) {
      return editedMarks[key]!;
    }

    final doc = await _firestore
        .collection('attendance')
        .doc(sessionId)
        .collection('students')
        .doc(studentId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data() ?? {};

    return _isPresent(data['status']);
  }

  Future<void> _generateWorkbook() async {
    try {
      generatedFilePath =
          await _exportService.generateAnnualWorkbook(
        branch: widget.branch,
        year: widget.year,
        course: widget.course,
        editedMarks: editedMarks,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showMessage('Workbook generation failed: $e');
    }
  }

  Future<void> _updateWorkbook() async {
    if (!mounted) return;

    setState(() {
      isSaving = true;
    });

    try {
      // Overwrites the existing workbook at the same path.
      generatedFilePath =
          await _exportService.generateAnnualWorkbook(
        branch: widget.branch,
        year: widget.year,
        course: widget.course,
        editedMarks: editedMarks,
      );

      if (!mounted) return;

      _showMessage('Attendance changes saved successfully.');
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to save changes: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _editAttendance(
    String sessionId,
    String studentId,
    bool currentValue,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Attendance'),
          content: const Text(
            'Select the attendance status.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Absent'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Present'),
            ),
          ],
        );
      },
    );

    if (result == null || result == currentValue) return;

    final key = '$sessionId::$studentId';

    setState(() {
      editedMarks[key] = result;
    });

    await _updateWorkbook();
  }

  Future<void> _downloadWorkbook() async {
    if (generatedFilePath == null || isDownloading) return;

    setState(() {
      isDownloading = true;
    });

    try {
      await _updateWorkbook();

      if (generatedFilePath != null) {
        await _exportService.downloadWorkbook(
          generatedFilePath!,
        );
      }
    } catch (e) {
      _showMessage('Download failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  Future<void> _exportWorkbook() async {
    if (generatedFilePath == null || isExporting) return;

    setState(() {
      isExporting = true;
    });

    try {
      await _updateWorkbook();

      if (generatedFilePath != null) {
        await _exportService.shareWorkbook(
          generatedFilePath!,
        );
      }
    } catch (e) {
      _showMessage('Export failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    double width = 110,
  }) {
    return Container(
      width: width,
      height: 52,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: primaryNavy,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextCell(
    String text, {
    double width = 110,
  }) {
    return Container(
      width: width,
      height: 55,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAttendanceCell(
    String sessionId,
    String studentId,
    bool isPresent,
  ) {
    return InkWell(
      onTap: isSaving
          ? null
          : () => _editAttendance(
                sessionId,
                studentId,
                isPresent,
              ),
      child: Container(
        width: 65,
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isPresent
                ? successGreen.withOpacity(0.12)
                : Colors.red.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isPresent ? 'P' : 'A',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPresent
                  ? successGreen
                  : Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRow(
    Map<String, dynamic> student,
    int index,
  ) {
    final studentId = student['id'].toString();

    return FutureBuilder<List<bool>>(
      future: Future.wait(
        sessions.map((session) {
          return _getMark(
            session['id'].toString(),
            studentId,
          );
        }),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 55,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        final marks = snapshot.data!;

        final present = marks.where((mark) => mark).length;
        final absent = marks.length - present;

        final percentage = marks.isEmpty
            ? 0.0
            : (present / marks.length) * 100;

        final status = percentage >= 75
            ? 'Eligible'
            : 'Detained';

        return Row(
          children: [
            _buildTextCell('${index + 1}', width: 60),
            _buildTextCell(
              student['name'].toString(),
              width: 180,
            ),
            _buildTextCell(
              student['rollNo'].toString(),
              width: 100,
            ),
            ...List.generate(marks.length, (i) {
              return _buildAttendanceCell(
                sessions[i]['id'].toString(),
                studentId,
                marks[i],
              );
            }),
            _buildTextCell(
              present.toString(),
              width: 80,
            ),
            _buildTextCell(
              absent.toString(),
              width: 80,
            ),
            _buildTextCell(
              '${percentage.toStringAsFixed(1)}%',
              width: 100,
            ),
            Container(
              width: 110,
              height: 55,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: percentage >= 75
                      ? successGreen
                      : Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTable() {
    if (students.isEmpty) {
      return const Center(
        child: Text('No students found.'),
      );
    }

    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'No attendance sessions found for this month.',
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 60 +
              180 +
              100 +
              (sessions.length * 65) +
              80 +
              80 +
              100 +
              110,
          child: Column(
            children: [
              Row(
                children: [
                  _buildHeaderCell('Sr No', width: 60),
                  _buildHeaderCell(
                    'Student Name',
                    width: 180,
                  ),
                  _buildHeaderCell('Roll No', width: 100),
                  ...sessions.map((session) {
                    final date =
                        session['date'] as DateTime;

                    return _buildHeaderCell(
                      '${date.day}/${date.month}',
                      width: 65,
                    );
                  }),
                  _buildHeaderCell(
                    'Present',
                    width: 80,
                  ),
                  _buildHeaderCell(
                    'Absent',
                    width: 80,
                  ),
                  _buildHeaderCell(
                    'Attendance %',
                    width: 100,
                  ),
                  _buildHeaderCell(
                    'Status',
                    width: 110,
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    return _buildStudentRow(
                      students[index],
                      index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    bool loading = false,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 19),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Attendance Preview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : _loadAttendance,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        primaryNavy,
                        primaryBlue,
                        cyan,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APEX ATTENDANCE REPORT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Branch: ${widget.branch}   |   Year: ${widget.year}',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Course: ${widget.course}',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Month: ${widget.month}',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          'Tap P or A to edit attendance.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      if (isSaving)
                        const Text(
                          'Saving...',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildTable(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildActionButton(
                        label: 'Download',
                        icon: Icons.download,
                        color: successGreen,
                        loading: isDownloading,
                        onPressed: generatedFilePath == null
                            ? null
                            : _downloadWorkbook,
                      ),
                      const SizedBox(width: 10),
                      _buildActionButton(
                        label: 'Export',
                        icon: Icons.share,
                        color: primaryBlue,
                        loading: isExporting,
                        onPressed: generatedFilePath == null
                            ? null
                            : _exportWorkbook,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}