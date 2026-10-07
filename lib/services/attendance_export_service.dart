import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceExportService {
  AttendanceExportService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<String> monthNames = [
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
  // EXPORT ATTENDANCE
  // ============================================================

  Future<String> exportAttendanceSheet({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {
    final String cleanBranch = branch.trim().toUpperCase();
    final String cleanYear = year.trim();
    final String cleanCourse = course.trim().toUpperCase();
    final String cleanMonth = month.trim();

    if (cleanBranch.isEmpty) {
      throw Exception('Branch is required.');
    }

    if (cleanYear.isEmpty) {
      throw Exception('Year is required.');
    }

    if (cleanCourse.isEmpty) {
      throw Exception('Course is required.');
    }

    if (!monthNames.contains(cleanMonth)) {
      throw Exception('Invalid month: $cleanMonth');
    }

    // ==========================================================
    // 1. GET STUDENTS
    // ==========================================================

    final studentSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: cleanBranch)
        .where('year', isEqualTo: cleanYear)
        .get();

    final List<Map<String, dynamic>> students = [];

    for (final doc in studentSnapshot.docs) {
      students.add({
        'id': doc.id,
        ...doc.data(),
      });
    }

    // ==========================================================
    // 2. SORT STUDENTS
    // ==========================================================

    students.sort(
      (a, b) {
        final String rollA = _getRollNumber(a);
        final String rollB = _getRollNumber(b);

        final int? numberA = int.tryParse(rollA);
        final int? numberB = int.tryParse(rollB);

        if (numberA != null && numberB != null) {
          return numberA.compareTo(numberB);
        }

        return rollA.compareTo(rollB);
      },
    );

    // ==========================================================
    // 3. GET COMPLETED ATTENDANCE SESSIONS
    // ==========================================================

    final sessionSnapshot = await _firestore
        .collection('live_sessions')
        .where('branch', isEqualTo: cleanBranch)
        .where('year', isEqualTo: cleanYear)
        .where('course', isEqualTo: cleanCourse)
        .where('status', isEqualTo: 'ended')
        .get();

    final int selectedMonth =
        monthNames.indexOf(cleanMonth) + 1;

    final List<Map<String, dynamic>> sessions = [];

    for (final doc in sessionSnapshot.docs) {
      final data = doc.data();

      final DateTime? date =
          _getDate(data['createdAt']);

      if (date == null) {
        continue;
      }

      if (date.month != selectedMonth) {
        continue;
      }

      sessions.add({
        'id': doc.id,
        ...data,
      });
    }

    // ==========================================================
    // 4. SORT SESSIONS DATE-WISE
    // ==========================================================

    sessions.sort(
      (a, b) {
        final DateTime dateA =
            _getDate(a['createdAt']) ??
                DateTime(2000);

        final DateTime dateB =
            _getDate(b['createdAt']) ??
                DateTime(2000);

        return dateA.compareTo(dateB);
      },
    );

    // ==========================================================
    // 5. CREATE EXCEL
    // ==========================================================

    final Excel excel = Excel.createExcel();

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final Sheet sheet = excel[cleanMonth];

    const int firstDateColumn = 3;
    const int headerRow = 3;

    final int presentColumn =
        firstDateColumn + sessions.length;

    final int absentColumn =
        presentColumn + 1;

    final int percentageColumn =
        presentColumn + 2;

    final int statusColumn =
        presentColumn + 3;

    final int lastColumn = statusColumn;

    // ==========================================================
    // 6. TITLE
    // ==========================================================

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

    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 0,
      ),
    );

    titleCell.value =
        TextCellValue('ATTENDANCE REPORT');

    titleCell.cellStyle = _titleStyle();

    // ==========================================================
    // 7. INFORMATION
    // ==========================================================

    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 1,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: lastColumn,
        rowIndex: 1,
      ),
    );

    final infoCell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 1,
      ),
    );

    infoCell.value = TextCellValue(
      'Branch: $cleanBranch    '
      'Year: $cleanYear    '
      'Course: $cleanCourse    '
      'Month: $cleanMonth',
    );

    infoCell.cellStyle = _infoStyle();

    // ==========================================================
    // 8. HEADERS
    // ==========================================================

    _setCell(
      sheet,
      0,
      headerRow,
      'Sr No',
      _headerStyle(),
    );

    _setCell(
      sheet,
      1,
      headerRow,
      'Roll No',
      _headerStyle(),
    );

    _setCell(
      sheet,
      2,
      headerRow,
      'Name',
      _headerStyle(),
    );

    // DATE-WISE HEADERS
    for (int i = 0; i < sessions.length; i++) {
      final DateTime? date =
          _getDate(sessions[i]['createdAt']);

      String dateText = '-';

      if (date != null) {
        dateText =
            '${date.day.toString().padLeft(2, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.year}';
      }

      _setCell(
        sheet,
        firstDateColumn + i,
        headerRow,
        dateText,
        _headerStyle(),
      );
    }

    _setCell(
      sheet,
      presentColumn,
      headerRow,
      'Present',
      _headerStyle(),
    );

    _setCell(
      sheet,
      absentColumn,
      headerRow,
      'Absent',
      _headerStyle(),
    );

    _setCell(
      sheet,
      percentageColumn,
      headerRow,
      'Attendance %',
      _headerStyle(),
    );

    _setCell(
      sheet,
      statusColumn,
      headerRow,
      'Status',
      _headerStyle(),
    );

    // ==========================================================
    // 9. STUDENT DATA
    // ==========================================================

    for (int studentIndex = 0;
        studentIndex < students.length;
        studentIndex++) {
      final Map<String, dynamic> student =
          students[studentIndex];

      final int row =
          headerRow + 1 + studentIndex;

      final String studentId =
          (student['id'] ?? '').toString();

      final String rollNo =
          _getRollNumber(student);

      final String name =
          _getStudentName(student);

      int presentCount = 0;
      int absentCount = 0;

      // --------------------------------------------------------
      // BASIC DETAILS
      // --------------------------------------------------------

      _setCell(
        sheet,
        0,
        row,
        '${studentIndex + 1}',
        _bodyStyle(),
      );

      _setCell(
        sheet,
        1,
        row,
        rollNo,
        _bodyStyle(),
      );

      _setCell(
        sheet,
        2,
        row,
        name,
        _bodyStyle(),
      );

      // --------------------------------------------------------
      // DATE-WISE P / A
      // --------------------------------------------------------

      for (int sessionIndex = 0;
          sessionIndex < sessions.length;
          sessionIndex++) {
        final String sessionId =
            (sessions[sessionIndex]['id'] ?? '')
                .toString();

        final String mark =
            await _getAttendanceMark(
          sessionId: sessionId,
          studentId: studentId,
        );

        // P = Present
        if (mark == 'P') {
          presentCount++;
        }

        // A = Absent
        else {
          absentCount++;
        }

        _setCell(
          sheet,
          firstDateColumn + sessionIndex,
          row,
          mark,
          _bodyStyle(),
        );
      }

      // --------------------------------------------------------
      // ATTENDANCE PERCENTAGE
      // --------------------------------------------------------

      final int totalClasses =
          sessions.length;

      final double percentage =
          totalClasses == 0
              ? 0
              : (presentCount /
                      totalClasses) *
                  100;

      final String status =
          percentage >= 75
              ? 'Regular'
              : 'Detained';

      // --------------------------------------------------------
      // SUMMARY
      // --------------------------------------------------------

      _setCell(
        sheet,
        presentColumn,
        row,
        presentCount.toString(),
        _bodyStyle(),
      );

      _setCell(
        sheet,
        absentColumn,
        row,
        absentCount.toString(),
        _bodyStyle(),
      );

      _setCell(
        sheet,
        percentageColumn,
        row,
        percentage.toStringAsFixed(2),
        _bodyStyle(),
      );

      _setCell(
        sheet,
        statusColumn,
        row,
        status,
        _bodyStyle(),
      );
    }

    // ==========================================================
    // 10. COLUMN WIDTHS
    // ==========================================================

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 28);

    for (int i = 0;
        i < sessions.length;
        i++) {
      sheet.setColumnWidth(
        firstDateColumn + i,
        14,
      );
    }

    sheet.setColumnWidth(
      presentColumn,
      12,
    );

    sheet.setColumnWidth(
      absentColumn,
      12,
    );

    sheet.setColumnWidth(
      percentageColumn,
      16,
    );

    sheet.setColumnWidth(
      statusColumn,
      14,
    );

    // ==========================================================
    // 11. ROW HEIGHTS
    // ==========================================================

    sheet.setRowHeight(0, 28);
    sheet.setRowHeight(1, 24);
    sheet.setRowHeight(headerRow, 32);

    for (int i = 0;
        i < students.length;
        i++) {
      sheet.setRowHeight(
        headerRow + 1 + i,
        24,
      );
    }

    // ==========================================================
    // 12. SAVE EXCEL
    // ==========================================================

    final Directory directory =
        await getApplicationDocumentsDirectory();

    final String fileName =
        '${cleanYear}_${cleanBranch}_${cleanCourse.replaceAll(' ', '_')}_Attendance.xlsx';

    final String filePath =
        '${directory.path}/$fileName';

    final List<int>? bytes =
        excel.encode();

    if (bytes == null || bytes.isEmpty) {
      throw Exception(
        'Excel file could not be generated.',
      );
    }

    final File file = File(filePath);

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return filePath;
  }

  // ============================================================
  // GET ATTENDANCE MARK
  // ============================================================

  Future<String> _getAttendanceMark({
    required String sessionId,
    required String studentId,
  }) async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> doc =
          await _firestore
              .collection('attendance')
              .doc(sessionId)
              .collection('students')
              .doc(studentId)
              .get();

      // No record = ABSENT
      if (!doc.exists) {
        return 'A';
      }

      final Map<String, dynamic>? data =
          doc.data();

      if (data == null) {
        return 'A';
      }

      final dynamic status =
          data['status'];

      // PRESENT
      if (status == 'Present' ||
          status == 'present' ||
          status == 'P' ||
          status == true) {
        return 'P';
      }

      // Everything else = ABSENT
      return 'A';
    } catch (_) {
      // If attendance cannot be found,
      // treat the student as absent.
      return 'A';
    }
  }

  // ============================================================
  // SET CELL
  // ============================================================

  void _setCell(
    Sheet sheet,
    int column,
    int row,
    String value,
    CellStyle style,
  ) {
    final Data cell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: column,
        rowIndex: row,
      ),
    );

    cell.value = TextCellValue(value);
    cell.cellStyle = style;
  }

  // ============================================================
  // STUDENT NAME
  // ============================================================

  String _getStudentName(
    Map<String, dynamic> student,
  ) {
    final dynamic name = student['name'];

    if (name != null &&
        name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    final dynamic displayName =
        student['displayName'];

    if (displayName != null &&
        displayName.toString().trim().isNotEmpty) {
      return displayName.toString().trim();
    }

    final dynamic fullName =
        student['fullName'];

    if (fullName != null &&
        fullName.toString().trim().isNotEmpty) {
      return fullName.toString().trim();
    }

    return 'Unknown Student';
  }

  // ============================================================
  // ROLL NUMBER
  // ============================================================

  String _getRollNumber(
    Map<String, dynamic> student,
  ) {
    final dynamic roll =
        student['rollNo'] ??
            student['rollNumber'] ??
            student['roll'];

    if (roll == null) {
      return '';
    }

    return roll.toString().trim();
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime? _getDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // TITLE STYLE
  // ============================================================

  CellStyle _titleStyle() {
    return CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign:
          HorizontalAlign.Center,
      verticalAlign:
          VerticalAlign.Center,
    );
  }

  // ============================================================
  // INFO STYLE
  // ============================================================

  CellStyle _infoStyle() {
    return CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign:
          HorizontalAlign.Center,
      verticalAlign:
          VerticalAlign.Center,
      textWrapping:
          TextWrapping.WrapText,
    );
  }

  // ============================================================
  // HEADER STYLE
  // ============================================================

  CellStyle _headerStyle() {
    return CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign:
          HorizontalAlign.Center,
      verticalAlign:
          VerticalAlign.Center,
      textWrapping:
          TextWrapping.WrapText,
      leftBorder: Border(
        borderStyle: BorderStyle.Thin,
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thin,
      ),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thin,
      ),
    );
  }

  // ============================================================
  // BODY STYLE
  // ============================================================

  CellStyle _bodyStyle() {
    return CellStyle(
      fontSize: 10,
      horizontalAlign:
          HorizontalAlign.Center,
      verticalAlign:
          VerticalAlign.Center,
      textWrapping:
          TextWrapping.WrapText,
      leftBorder: Border(
        borderStyle: BorderStyle.Thin,
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thin,
      ),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thin,
      ),
    );
  }

  // ============================================================
  // SHARE ATTENDANCE SHEET
  // ============================================================

  Future<void> shareAttendanceSheet({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {
    final String filePath =
        await exportAttendanceSheet(
      branch: branch,
      year: year,
      course: course,
      month: month,
    );

    final File file = File(filePath);

    if (!await file.exists()) {
      throw Exception(
        'Attendance Excel file was not created.',
      );
    }

    await Share.shareXFiles(
      [
        XFile(filePath),
      ],
      subject:
          'Attendance Report - $course',
      text:
          'Attendance Report\n'
          'Branch: $branch\n'
          'Year: $year\n'
          'Course: $course\n'
          'Month: $month',
    );
  }
}