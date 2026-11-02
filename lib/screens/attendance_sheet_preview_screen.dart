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
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color cyan = Color(0xFF18A8C8);
  static const Color successGreen = Color(0xFF159957);
  static const Color background = Color(0xFFF5F8FC);

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AttendanceExportService exportService =
      AttendanceExportService();

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> sessions = [];

  final Map<String, bool> editedMarks = {};
  final Map<String, bool> attendanceCache = {};

  String? generatedFilePath;
  String? errorMessage;

  bool isLoading = true;
  bool isSaving = false;
  bool isDownloading = false;
  bool isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Normalize values to avoid mismatches such as IT / Information Technology.
  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _normalizeBranch(dynamic value) {
    final branch = _normalize(value?.toString() ?? '');

    if (branch == 'it' ||
        branch.contains('informationtechnology')) {
      return 'it';
    }

    if (branch == 'cm' ||
        branch.contains('computertechnology')) {
      return 'cm';
    }

    return branch;
  }

  int _normalizeYear(dynamic value) {
    final year = _normalize(value?.toString() ?? '');

    if (year == 'firstyear' ||
        year == 'first' ||
        year == 'fy') {
      return 1;
    }

    if (year == 'secondyear' ||
        year == 'second' ||
        year == 'sy') {
      return 2;
    }

    if (year == 'thirdyear' ||
        year == 'third' ||
        year == 'ty') {
      return 3;
    }

    final match = RegExp(r'[1-3]').firstMatch(year);
    return match == null ? 0 : int.parse(match.group(0)!);
  }

  bool _matchesCourse(dynamic value) {
    final actual = _normalize(value?.toString() ?? '');
    final selected = _normalize(widget.course);

    if (actual.isEmpty || selected.isEmpty) return false;

    if (actual == selected) return true;

    // Allow a course name to match when one contains the other.
    return actual.contains(selected) ||
        selected.contains(actual);
  }

  int _monthNumber(String month) {
    const months = [
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

    final index = months.indexWhere(
      (item) => _normalize(item) == _normalize(month),
    );

    return index + 1;
  }

  DateTime? _readDate(Map<String, dynamic> data) {
    for (final key in [
      'createdAt',
      'date',
      'sessionDate',
      'startTime',
      'timestamp',
    ]) {
      final value = data[key];

      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;

      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  bool _isStudent(Map<String, dynamic> data) {
    final role = _normalize(
      (data['role'] ?? data['userRole'] ?? '').toString(),
    );

    return role == 'student';
  }

  bool _matchesStudent(Map<String, dynamic> data) {
    final branch = _normalizeBranch(
      data['branch'] ?? data['department'],
    );

    final year = _normalizeYear(
      data['year'] ?? data['academicYear'],
    );

    return branch == _normalizeBranch(widget.branch) &&
        year == _normalizeYear(widget.year);
  }

  Future<void> _loadData() async {
    if (!_isAllowedBranch(widget.branch)) {
      setState(() {
        isLoading = false;
        errorMessage = 'Only IT and CM branches are supported.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await Future.wait([
        _loadStudents(),
        _loadSessions(),
      ]);

      if (!mounted) return;

      // Load all attendance marks into memory for the selected month.
      await _loadAllAttendanceMarks();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // Generate the annual workbook after the preview data is loaded.
      await _generateWorkbook();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to fetch report data: $e';
      });
    }
  }

  bool _isAllowedBranch(String branch) {
    final value = _normalizeBranch(branch);
    return value == 'it' || value == 'cm';
  }

  Future<void> _loadStudents() async {
    final snapshot = await firestore.collection('users').get();

    final Map<String, Map<String, dynamic>> uniqueStudents = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (!_isStudent(data)) continue;
      if (!_matchesStudent(data)) continue;

      uniqueStudents[doc.id] = {
        'id': doc.id,
        'name': data['name'] ??
            data['fullName'] ??
            data['studentName'] ??
            'Unnamed Student',
        'rollNo': data['rollNo'] ??
            data['rollNumber'] ??
            '',
        'email': data['email'] ?? '',
      };
    }

    students = uniqueStudents.values.toList();

    students.sort((a, b) {
      final rollA = a['rollNo'].toString();
      final rollB = b['rollNo'].toString();

      final numberA = int.tryParse(rollA);
      final numberB = int.tryParse(rollB);

      if (numberA != null && numberB != null) {
        return numberA.compareTo(numberB);
      }

      return rollA.compareTo(rollB);
    });
  }

  Future<void> _loadSessions() async {
    final snapshot =
        await firestore.collection('live_sessions').get();

    final selectedMonth = _monthNumber(widget.month);
    final selectedYear = _normalizeYear(widget.year);

    final loaded = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final branch = _normalizeBranch(
        data['branch'] ?? data['department'],
      );

      final year = _normalizeYear(
        data['year'] ?? data['academicYear'],
      );

      final course = data['course'] ??
          data['subject'] ??
          data['courseName'];

      if (branch != _normalizeBranch(widget.branch)) continue;
      if (year != selectedYear) continue;
      if (!_matchesCourse(course)) continue;

      final status = _normalize(
        data['status']?.toString() ?? '',
      );

      // Exclude sessions that are still running.
      if ([
        'active',
        'ongoing',
        'live',
        'started',
      ].contains(status)) {
        continue;
      }

      final date = _readDate(data);

      if (date == null) continue;
      if (date.month != selectedMonth) continue;

      loaded.add({
        'id': doc.id,
        'date': date,
        'course': course,
      });
    }

    loaded.sort((a, b) {
      return (a['date'] as DateTime)
          .compareTo(b['date'] as DateTime);
    });

    sessions = loaded;
  }

  bool _readPresent(Map<String, dynamic> data) {
    final value = data['status'] ??
        data['attendanceStatus'] ??
        data['isPresent'];

    if (value is bool) return value;

    final status = _normalize(value?.toString() ?? '');

    return status == 'present' ||
        status == 'p' ||
        status == 'true';
  }

  Future<void> _loadAllAttendanceMarks() async {
    attendanceCache.clear();

    for (final session in sessions) {
      final sessionId = session['id'].toString();

      final snapshot = await firestore
          .collection('attendance')
          .doc(sessionId)
          .collection('students')
          .get();

      for (final doc in snapshot.docs) {
        final key = '$sessionId::${doc.id}';
        attendanceCache[key] = _readPresent(doc.data());
      }
    }
  }

  bool _getMark(String sessionId, String studentId) {
    final key = '$sessionId::$studentId';

    if (editedMarks.containsKey(key)) {
      return editedMarks[key]!;
    }

    return attendanceCache[key] ?? false;
  }

  Future<void> _generateWorkbook() async {
    try {
      generatedFilePath =
          await exportService.generateAnnualWorkbook(
        branch: widget.branch,
        year: widget.year,
        course: widget.course,
        editedMarks: editedMarks,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        _showMessage('Excel generation failed: $e');
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);

    try {
      generatedFilePath =
          await exportService.generateAnnualWorkbook(
        branch: widget.branch,
        year: widget.year,
        course: widget.course,
        editedMarks: editedMarks,
      );

      if (mounted) {
        _showMessage('Workbook updated successfully.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to update workbook: $e');
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _editMark(
    String sessionId,
    String studentId,
  ) async {
    final current = _getMark(sessionId, studentId);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Attendance'),
        content: const Text(
          'Choose the new attendance status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Absent'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Present'),
          ),
        ],
      ),
    );

    if (result == null || result == current) return;

    setState(() {
      editedMarks['$sessionId::$studentId'] = result;
    });

    await _saveChanges();
  }

  Future<void> _download() async {
    if (generatedFilePath == null || isDownloading) return;

    setState(() => isDownloading = true);

    try {
      await _saveChanges();

      if (generatedFilePath != null) {
        await exportService.downloadWorkbook(
          generatedFilePath!,
        );
      }
    } catch (e) {
      _showMessage('Download failed: $e');
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  Future<void> _export() async {
    if (generatedFilePath == null || isExporting) return;

    setState(() => isExporting = true);

    try {
      await _saveChanges();

      if (generatedFilePath != null) {
        await exportService.shareWorkbook(
          generatedFilePath!,
        );
      }
    } catch (e) {
      _showMessage('Export failed: $e');
    } finally {
      if (mounted) setState(() => isExporting = false);
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

  Widget _header(String value, double width) {
    return Container(
      width: width,
      height: 52,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      color: primaryNavy,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _cell(String value, double width) {
    return Container(
      width: width,
      height: 54,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _markCell(String sessionId, String studentId) {
    final present = _getMark(sessionId, studentId);

    return InkWell(
      onTap: isSaving
          ? null
          : () => _editMark(sessionId, studentId),
      child: Container(
        width: 65,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: present
                ? successGreen.withOpacity(0.12)
                : Colors.red.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            present ? 'P' : 'A',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: present ? successGreen : Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentRow(
    Map<String, dynamic> student,
    int index,
  ) {
    final studentId = student['id'].toString();

    final marks = sessions.map((session) {
      return _getMark(
        session['id'].toString(),
        studentId,
      );
    }).toList();

    final present = marks.where((mark) => mark).length;
    final absent = marks.length - present;

    final percentage = marks.isEmpty
        ? 0.0
        : present / marks.length * 100;

    return Row(
      children: [
        _cell('${index + 1}', 55),
        _cell(student['name'].toString(), 175),
        _cell(student['rollNo'].toString(), 90),
        ...sessions.map((session) {
          return _markCell(
            session['id'].toString(),
            studentId,
          );
        }),
        _cell('$present', 75),
        _cell('$absent', 75),
        _cell('${percentage.toStringAsFixed(1)}%', 95),
        Container(
          width: 105,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: Text(
            percentage >= 75 ? 'Eligible' : 'Detained',
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
  }

  Widget _buildTable() {
    if (students.isEmpty) {
      return const Center(
        child: Text(
          'No students found for this branch and year.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'Students were found, but no matching attendance sessions were found for this month.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final tableWidth =
        55 + 175 + 90 + sessions.length * 65 + 75 + 75 + 95 + 105;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth.toDouble(),
        child: Column(
          children: [
            Row(
              children: [
                _header('Sr No', 55),
                _header('Student Name', 175),
                _header('Roll No', 90),
                ...sessions.map((session) {
                  final date = session['date'] as DateTime;
                  return _header(
                    '${date.day}/${date.month}',
                    65,
                  );
                }),
                _header('Present', 75),
                _header('Absent', 75),
                _header('Attendance %', 95),
                _header('Status', 105),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return _studentRow(students[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
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
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Attendance Preview'),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'APEX ATTENDANCE REPORT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Branch: ${widget.branch}  |  Year: ${widget.year}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Course: ${widget.course}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Month: ${widget.month}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Students: ${students.length}  |  Sessions: ${sessions.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: primaryBlue,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Tap P or A to edit attendance.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
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
                          _actionButton(
                            label: 'Download',
                            icon: Icons.download,
                            color: successGreen,
                            loading: isDownloading,
                            onPressed: generatedFilePath == null
                                ? null
                                : _download,
                          ),
                          const SizedBox(width: 10),
                          _actionButton(
                            label: 'Export',
                            icon: Icons.share,
                            color: primaryBlue,
                            loading: isExporting,
                            onPressed: generatedFilePath == null
                                ? null
                                : _export,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}