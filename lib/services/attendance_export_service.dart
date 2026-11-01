import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> months = [
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

  // Converts 1, 2, 3 into 1 Year, 2 Year, 3 Year.
  String _displayYear(String year) {
    final value = year.trim().toLowerCase();

    switch (value) {
      case '1':
      case '1 year':
      case 'first year':
      case 'fy':
        return '1 Year';

      case '2':
      case '2 year':
      case 'second year':
      case 'sy':
        return '2 Year';

      case '3':
      case '3 year':
      case 'third year':
      case 'ty':
        return '3 Year';

      default:
        return year;
    }
  }

  DateTime? _getDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _isPresent(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;

    final status = value.toString().trim().toLowerCase();

    return status == 'present' ||
        status == 'p' ||
        status == 'true';
  }

  Future<List<Map<String, dynamic>>> _getStudents(
    String branch,
    String year,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .get();

    final students = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'rollNo': data['rollNo'] ?? '',
      };
    }).toList();

    students.sort((a, b) {
      return a['rollNo']
          .toString()
          .compareTo(b['rollNo'].toString());
    });

    return students;
  }

  Future<List<Map<String, dynamic>>> _getSessions(
    String branch,
    String year,
    String course,
  ) async {
    final snapshot = await _firestore
        .collection('live_sessions')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .where('course', isEqualTo: course)
        .where('status', isEqualTo: 'ended')
        .get();

    final sessions = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'date': _getDate(data['createdAt']),
      };
    }).where((session) {
      return session['date'] != null;
    }).toList();

    sessions.sort((a, b) {
      return (a['date'] as DateTime)
          .compareTo(b['date'] as DateTime);
    });

    return sessions;
  }

  Future<bool> _getAttendanceMark(
    String sessionId,
    String studentId,
  ) async {
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

  Future<String> generateAnnualWorkbook({
    required String branch,
    required String year,
    required String course,
    Map<String, bool> editedMarks = const {},
  }) async {
    final students = await _getStudents(branch, year);
    final sessions = await _getSessions(branch, year, course);

    final excel = Excel.createExcel();

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final displayYear = _displayYear(year);

    for (final month in months) {
      final sheet = excel[month];

      final monthSessions = sessions.where((session) {
        final date = session['date'] as DateTime;
        return date.month == months.indexOf(month) + 1;
      }).toList();

      // Original approved Excel column format.
      final headers = [
        'Sr No',
        'Roll No',
        'Name',
        ...monthSessions.map((session) {
          final date = session['date'] as DateTime;
          return '${date.day}/${date.month}';
        }),
      ];

      // Merge title cells according to the number of columns.
      final lastColumn = headers.length > 3
          ? headers.length - 1
          : 2;

      sheet.merge(
        CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: 0,
        ),
        CellIndex.indexByColumnRow(
          columnIndex: lastColumn,
          rowIndex: 0,
        ),
      );

      // Monthly title with course and year.
      sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: 0,
        ),
      ).value = TextCellValue(
        'APEX ATTENDANCE REPORT - $month - $course - $displayYear',
      );

      // Column headings.
      for (int col = 0; col < headers.length; col++) {
        sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: 2,
          ),
        ).value = TextCellValue(headers[col]);
      }

      // Student attendance data.
      for (int row = 0; row < students.length; row++) {
        final student = students[row];
        final excelRow = row + 3;

        sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: excelRow,
          ),
        ).value = IntCellValue(row + 1);

        sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: 1,
            rowIndex: excelRow,
          ),
        ).value = TextCellValue(
          student['rollNo'].toString(),
        );

        sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: 2,
            rowIndex: excelRow,
          ),
        ).value = TextCellValue(
          student['name'].toString(),
        );

        for (int col = 0; col < monthSessions.length; col++) {
          final session = monthSessions[col];

          final sessionId = session['id'].toString();
          final studentId = student['id'].toString();

          final key = '$sessionId::$studentId';

          final isPresent = editedMarks.containsKey(key)
              ? editedMarks[key]!
              : await _getAttendanceMark(
                  sessionId,
                  studentId,
                );

          sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: col + 3,
              rowIndex: excelRow,
            ),
          ).value = TextCellValue(
            isPresent ? 'P' : 'A',
          );
        }
      }

      // Column widths.
      sheet.setColumnWidth(0, 10);
      sheet.setColumnWidth(1, 15);
      sheet.setColumnWidth(2, 25);

      for (int col = 3; col < headers.length; col++) {
        sheet.setColumnWidth(col, 12);
      }
    }

    final directory = await getApplicationDocumentsDirectory();

    final filePath =
        '${directory.path}/APEX_Attendance_${branch}_${displayYear.replaceAll(' ', '_')}_${course.replaceAll(' ', '_')}.xlsx';

    final bytes = excel.encode();

    if (bytes == null) {
      throw Exception('Unable to generate Excel workbook.');
    }

    final file = File(filePath);

    // Overwrite the same working file on every update.
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }

  Future<void> downloadWorkbook(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Workbook not found. Generate Preview first.');
    }

    final bytes = await file.readAsBytes();

    final savedPath = await FilePicker.saveFile(
      dialogTitle: 'Save APEX Attendance Workbook',
      fileName: 'APEX_Attendance.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );

    if (savedPath == null) return;
  }

  Future<void> shareWorkbook(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Workbook not found. Generate Preview first.');
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            filePath,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'APEX Attendance Report',
        text: 'APEX Annual Attendance Workbook',
      ),
    );
  }
}