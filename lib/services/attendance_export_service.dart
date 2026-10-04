import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceExportService {
  AttendanceExportService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ============================================================
  // MONTHS
  // ============================================================

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
  // GENERATE ATTENDANCE EXCEL
  // ============================================================

  Future<String> exportAttendanceSheet({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {
    final String cleanBranch =
        branch.trim().toUpperCase();

    final String cleanYear =
        year.trim();

    final String cleanCourse =
        course.trim().toUpperCase();

    final String cleanMonth =
        month.trim();

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
      throw Exception(
        'Invalid month: $cleanMonth',
      );
    }

    // ==========================================================
    // 1. GET STUDENTS
    // ==========================================================

    final QuerySnapshot<Map<String, dynamic>>
        studentSnapshot =
        await _firestore
            .collection('users')
            .where(
              'role',
              isEqualTo: 'student',
            )
            .where(
              'branch',
              isEqualTo: cleanBranch,
            )
            .where(
              'year',
              isEqualTo: cleanYear,
            )
            .get();

    final List<Map<String, dynamic>>
        students = [];

    for (final QueryDocumentSnapshot<
        Map<String, dynamic>> doc
        in studentSnapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      students.add({
        'id': doc.id,
        ...data,
      });
    }

    // ==========================================================
    // 2. SORT STUDENTS BY ROLL NUMBER
    // ==========================================================

    students.sort(
      (
        Map<String, dynamic> a,
        Map<String, dynamic> b,
      ) {
        final String rollA =
            _getRollNumber(a);

        final String rollB =
            _getRollNumber(b);

        final int? numberA =
            int.tryParse(rollA);

        final int? numberB =
            int.tryParse(rollB);

        if (numberA != null &&
            numberB != null) {
          return numberA.compareTo(numberB);
        }

        return rollA.compareTo(rollB);
      },
    );

    // ==========================================================
    // 3. GET LIVE SESSIONS
    // ==========================================================

    final QuerySnapshot<Map<String, dynamic>>
        sessionSnapshot =
        await _firestore
            .collection('live_sessions')
            .where(
              'branch',
              isEqualTo: cleanBranch,
            )
            .where(
              'year',
              isEqualTo: cleanYear,
            )
            .where(
              'course',
              isEqualTo: cleanCourse,
            )
            .where(
              'status',
              isEqualTo: 'ended',
            )
            .get();

    final int selectedMonth =
        monthNames.indexOf(cleanMonth) + 1;

    final List<Map<String, dynamic>>
        sessions = [];

    for (final QueryDocumentSnapshot<
        Map<String, dynamic>> doc
        in sessionSnapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      final dynamic createdAt =
          data['createdAt'];

      DateTime? date;

      if (createdAt is Timestamp) {
        date = createdAt.toDate();
      } else if (createdAt is DateTime) {
        date = createdAt;
      }

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
    // 4. SORT SESSIONS BY DATE
    // ==========================================================

    sessions.sort(
      (
        Map<String, dynamic> a,
        Map<String, dynamic> b,
      ) {
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
    // 5. CREATE EXCEL WORKBOOK
    // ==========================================================

    final Excel excel =
        Excel.createExcel();

    // Remove default sheet.
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ==========================================================
    // 6. CREATE MONTH SHEET
    // ==========================================================

    final Sheet sheet =
        excel[cleanMonth];

    final int firstDateColumn = 3;

    final int presentColumn =
        firstDateColumn + sessions.length;

    final int absentColumn =
        presentColumn + 1;

    final int percentageColumn =
        presentColumn + 2;

    final int statusColumn =
        presentColumn + 3;

    final int lastColumn =
        statusColumn;

    // ==========================================================
    // 7. TITLE
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

    final Data titleCell =
        sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 0,
      ),
    );

    titleCell.value =
        TextCellValue(
      'ATTENDANCE REPORT',
    );

    titleCell.cellStyle =
        _titleStyle();

    // ==========================================================
    // 8. REPORT INFORMATION
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

    final Data infoCell =
        sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 1,
      ),
    );

    infoCell.value =
        TextCellValue(
      'Branch: $cleanBranch    '
      'Year: $cleanYear    '
      'Course: $cleanCourse    '
      'Month: $cleanMonth',
    );

    infoCell.cellStyle =
        _infoStyle();

    // ==========================================================
    // 9. HEADER
    // ==========================================================

    const int headerRow = 3;

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

    // Date headers.
    for (int i = 0;
        i < sessions.length;
        i++) {
      final DateTime? date =
          _getDate(
        sessions[i]['createdAt'],
      );

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
    // 10. STUDENT DATA
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
      // ATTENDANCE FOR EACH SESSION
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

        if (mark == 'P') {
          presentCount++;
        } else {
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
      // CALCULATE PERCENTAGE
      // --------------------------------------------------------

      final int totalClasses =
          sessions.length;

      final double percentage =
          totalClasses == 0
              ? 0.0
              : (presentCount /
                      totalClasses) *
                  100.0;

      final String status =
          percentage >= 75.0
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
    // 11. COLUMN WIDTHS
    // ==========================================================

    sheet.setColumnWidth(
      0,
      8,
    );

    sheet.setColumnWidth(
      1,
      12,
    );

    sheet.setColumnWidth(
      2,
      28,
    );

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
    // 12. ROW HEIGHTS
    // ==========================================================

    sheet.setRowHeight(
      0,
      28,
    );

    sheet.setRowHeight(
      1,
      24,
    );

    sheet.setRowHeight(
      headerRow,
      32,
    );

    for (int i = 0;
        i < students.length;
        i++) {
      sheet.setRowHeight(
        headerRow + 1 + i,
        24,
      );
    }

    // ==========================================================
    // 13. OVERALL SUMMARY
    // ==========================================================

    await _createOverallSummary(
      excel: excel,
      students: students,
      sessions: sessions,
      branch: cleanBranch,
      year: cleanYear,
      course: cleanCourse,
    );

    // ==========================================================
    // 14. SAVE FILE
    // ==========================================================

    final Directory directory =
        await getApplicationDocumentsDirectory();

    final String fileName =
        '${cleanYear}_${cleanBranch}_${cleanCourse}.xlsx';

    final String filePath =
        '${directory.path}/$fileName';

    final List<int>? bytes =
        excel.encode();

    if (bytes == null ||
        bytes.isEmpty) {
      throw Exception(
        'Excel file could not be generated.',
      );
    }

    final File file =
        File(filePath);

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return filePath;
  }

  // ============================================================
  // ATTENDANCE MARK
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

      if (status == 'Present' ||
          status == 'present' ||
          status == 'P' ||
          status == true) {
        return 'P';
      }

      return 'A';
    } catch (_) {
      return 'A';
    }
  }

  // ============================================================
  // OVERALL SUMMARY
  // ============================================================

  Future<void> _createOverallSummary({
    required Excel excel,
    required List<Map<String, dynamic>>
        students,
    required List<Map<String, dynamic>>
        sessions,
    required String branch,
    required String year,
    required String course,
  }) async {
    final Sheet sheet =
        excel['Overall Summary'];

    const int headerRow = 3;

    // ----------------------------------------------------------
    // TITLE
    // ----------------------------------------------------------

    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 0,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: 6,
        rowIndex: 0,
      ),
    );

    final Data titleCell =
        sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 0,
      ),
    );

    titleCell.value =
        TextCellValue(
      'OVERALL ATTENDANCE SUMMARY',
    );

    titleCell.cellStyle =
        _titleStyle();

    // ----------------------------------------------------------
    // INFORMATION
    // ----------------------------------------------------------

    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 1,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: 6,
        rowIndex: 1,
      ),
    );

    final Data infoCell =
        sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 1,
      ),
    );

    infoCell.value =
        TextCellValue(
      'Branch: $branch    '
      'Year: $year    '
      'Course: $course',
    );

    infoCell.cellStyle =
        _infoStyle();

    // ----------------------------------------------------------
    // HEADERS
    // ----------------------------------------------------------

    const List<String> headers = [
      'Sr No',
      'Roll No',
      'Name',
      'Present',
      'Absent',
      'Attendance %',
      'Status',
    ];

    for (int i = 0;
        i < headers.length;
        i++) {
      _setCell(
        sheet,
        i,
        headerRow,
        headers[i],
        _headerStyle(),
      );
    }

    // ----------------------------------------------------------
    // STUDENTS
    // ----------------------------------------------------------

    for (int studentIndex = 0;
        studentIndex < students.length;
        studentIndex++) {
      final Map<String, dynamic> student =
          students[studentIndex];

      final int row =
          headerRow + 1 + studentIndex;

      final String studentId =
          (student['id'] ?? '').toString();

      int presentCount = 0;
      int absentCount = 0;

      for (final Map<String, dynamic> session
          in sessions) {
        final String mark =
            await _getAttendanceMark(
          sessionId:
              (session['id'] ?? '').toString(),
          studentId: studentId,
        );

        if (mark == 'P') {
          presentCount++;
        } else {
          absentCount++;
        }
      }

      final double percentage =
          sessions.isEmpty
              ? 0.0
              : (presentCount /
                      sessions.length) *
                  100.0;

      final String status =
          percentage >= 75.0
              ? 'Regular'
              : 'Detained';

      final List<String> values = [
        '${studentIndex + 1}',
        _getRollNumber(student),
        _getStudentName(student),
        presentCount.toString(),
        absentCount.toString(),
        percentage.toStringAsFixed(2),
        status,
      ];

      for (int i = 0;
          i < values.length;
          i++) {
        _setCell(
          sheet,
          i,
          row,
          values[i],
          _bodyStyle(),
        );
      }
    }

    // ----------------------------------------------------------
    // WIDTHS
    // ----------------------------------------------------------

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 28);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 14);

    sheet.setRowHeight(0, 28);
    sheet.setRowHeight(1, 24);
    sheet.setRowHeight(
      headerRow,
      32,
    );

    for (int i = 0;
        i < students.length;
        i++) {
      sheet.setRowHeight(
        headerRow + 1 + i,
        24,
      );
    }
  }

  // ============================================================
  // CELL WRITER
  // ============================================================

  void _setCell(
    Sheet sheet,
    int column,
    int row,
    String value,
    CellStyle style,
  ) {
    final Data cell =
        sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: column,
        rowIndex: row,
      ),
    );

    cell.value =
        TextCellValue(value);

    cell.cellStyle =
        style;
  }

  // ============================================================
  // STUDENT NAME
  // ============================================================

  String _getStudentName(
    Map<String, dynamic> student,
  ) {
    final dynamic name =
        student['name'];

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

  DateTime? _getDate(
    dynamic value,
  ) {
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
  // INFORMATION STYLE
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
        borderStyle:
            BorderStyle.Thin,
      ),
      rightBorder: Border(
        borderStyle:
            BorderStyle.Thin,
      ),
      topBorder: Border(
        borderStyle:
            BorderStyle.Thin,
      ),
      bottomBorder: Border(
        borderStyle:
            BorderStyle.Thin,
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
        borderStyle:
            BorderStyle.Thin,
      ),
      rightBorder: Border(
        borderStyle:
            BorderStyle.Thin,
      ),
      topBorder: Border(
        borderStyle:
            BorderStyle.Thin,
      ),
      bottomBorder: Border(
        borderStyle:
            BorderStyle.Thin,
      ),
    );
  }

  // ============================================================
  // SHARE GENERATED FILE
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

    final File file =
        File(filePath);

    if (!await file.exists()) {
      throw Exception(
        'Attendance Excel file was not created.',
      );
    }

    await Share.shareXFiles(
      <XFile>[
        XFile(filePath),
      ],
      subject:
          'Attendance Report - '
          '${course.toUpperCase()}',
      text:
          'Attendance Report\n'
          'Branch: ${branch.toUpperCase()}\n'
          'Year: $year\n'
          'Course: ${course.toUpperCase()}\n'
          'Month: $month',
    );
  }
}
