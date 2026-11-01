import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'attendance_summary_service.dart';

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
    Map<String, String> editedMarks = const {},
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

    final int selectedMonth = monthNames.indexOf(cleanMonth) + 1;

    final List<Map<String, dynamic>> sessions = [];

    for (final doc in sessionSnapshot.docs) {
      final data = doc.data();

      final DateTime? date = _getDate(data['createdAt']);

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
        final DateTime dateA = _getDate(a['createdAt']) ?? DateTime(2000);

        final DateTime dateB = _getDate(b['createdAt']) ?? DateTime(2000);

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

    final int presentColumn = firstDateColumn + sessions.length;

    final int absentColumn = presentColumn + 1;

    final int percentageColumn = presentColumn + 2;

    final int statusColumn = presentColumn + 3;

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

    titleCell.value = TextCellValue('ATTENDANCE REPORT');

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
      final DateTime? date = _getDate(sessions[i]['createdAt']);

      String dateText = '-';

      if (date != null) {
        dateText = '${date.day.toString().padLeft(2, '0')}-'
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

    for (int studentIndex = 0; studentIndex < students.length; studentIndex++) {
      final Map<String, dynamic> student = students[studentIndex];

      final int row = headerRow + 1 + studentIndex;

      final String studentId = (student['id'] ?? '').toString();

      final String rollNo = _getRollNumber(student);

      final String name = _getStudentName(student);

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
            (sessions[sessionIndex]['id'] ?? '').toString();

        final String mark = editedMarks['$sessionId::$studentId'] ?? await _getAttendanceMark(
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

      final int totalClasses = sessions.length;

      final double percentage =
          totalClasses == 0 ? 0 : (presentCount / totalClasses) * 100;

      final String status = percentage >= 75 ? 'Regular' : 'Detained';

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

    for (int i = 0; i < sessions.length; i++) {
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

    for (int i = 0; i < students.length; i++) {
      sheet.setRowHeight(
        headerRow + 1 + i,
        24,
      );
    }

    // ==========================================================
    // 12. SAVE EXCEL
    // ==========================================================

    final Directory directory = await getApplicationDocumentsDirectory();

    final String fileName =
        '${cleanYear}_${cleanBranch}_${cleanCourse.replaceAll(' ', '_')}_Attendance.xlsx';

    final String filePath = '${directory.path}/$fileName';

    final List<int>? bytes = excel.encode();

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
  // ANNUAL WORKBOOK: ONE FILE WITH 12 MONTH TABS
  // ============================================================

  Future<String> exportAnnualAttendanceWorkbook({
    required String branch,
    required String year,
    required String course,
  }) async {
    final cleanBranch = branch.trim().toUpperCase();
    final cleanYear = year.trim().replaceAll(RegExp(r'\s*Year$', caseSensitive: false), '');
    final cleanCourse = course.trim().toUpperCase();
    if (cleanBranch.isEmpty || cleanYear.isEmpty || cleanCourse.isEmpty) {
      throw ArgumentError('Branch, year and course are required.');
    }

    final studentSnapshot = await _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: cleanBranch)
        .where('year', isEqualTo: cleanYear)
        .get();
    final students = studentSnapshot.docs.map((doc) => <String, dynamic>{
      'id': doc.id,
      ...doc.data(),
    }).toList();
    students.sort((a, b) {
      final ra = _getRollNumber(a);
      final rb = _getRollNumber(b);
      final na = int.tryParse(ra);
      final nb = int.tryParse(rb);
      if (na != null && nb != null) return na.compareTo(nb);
      return ra.compareTo(rb);
    });

    final sessionSnapshot = await _firestore.collection('live_sessions')
        .where('branch', isEqualTo: cleanBranch)
        .where('year', isEqualTo: cleanYear)
        .where('course', isEqualTo: cleanCourse)
        .where('status', isEqualTo: 'ended')
        .get();

    final sessionsByMonth = <int, List<Map<String, dynamic>>>{
      for (var m = 1; m <= 12; m++) m: <Map<String, dynamic>>[],
    };
    for (final doc in sessionSnapshot.docs) {
      final date = _getDate(doc.data()['createdAt']);
      if (date == null) continue;
      sessionsByMonth[date.month]!.add({'id': doc.id, ...doc.data()});
    }

    final excel = Excel.createExcel();
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

    for (var monthIndex = 1; monthIndex <= 12; monthIndex++) {
      final month = monthNames[monthIndex - 1];
      final sessions = sessionsByMonth[monthIndex]!
        ..sort((a, b) => (_getDate(a['createdAt']) ?? DateTime(2000))
            .compareTo(_getDate(b['createdAt']) ?? DateTime(2000)));
      final sheet = excel[month];
      final lastColumn = 2 + sessions.length;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: lastColumn, rowIndex: 0),
      );
      final title = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      title.value = TextCellValue('ATTENDANCE REGISTER - $month');
      title.cellStyle = _titleStyle();
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: lastColumn, rowIndex: 1),
      );
      final info = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      info.value = TextCellValue('Branch: $cleanBranch    Year: $cleanYear    Course: $cleanCourse');
      info.cellStyle = _infoStyle();

      _setCell(sheet, 0, 3, 'Sr No', _headerStyle());
      _setCell(sheet, 1, 3, 'Student Name', _headerStyle());
      _setCell(sheet, 2, 3, 'Roll No', _headerStyle());
      for (var i = 0; i < sessions.length; i++) {
        final date = _getDate(sessions[i]['createdAt']);
        final label = date == null ? '-' : '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}';
        _setCell(sheet, 3 + i, 3, label, _headerStyle());
      }

      // Fetch each session's attendance once. Missing records for completed sessions are A.
      final marksBySession = <String, Set<String>>{};
      for (final session in sessions) {
        final snapshot = await _firestore.collection('attendance')
            .doc(session['id'].toString()).collection('students').get();
        marksBySession[session['id'].toString()] = snapshot.docs
            .where((d) => _isPresentStatus(d.data()['status']))
            .map((d) => d.id).toSet();
      }

      for (var studentIndex = 0; studentIndex < students.length; studentIndex++) {
        final student = students[studentIndex];
        final row = 4 + studentIndex;
        final studentId = student['id'].toString();
        _setCell(sheet, 0, row, '${studentIndex + 1}', _bodyStyle());
        _setCell(sheet, 1, row, _getStudentName(student), _bodyStyle());
        _setCell(sheet, 2, row, _getRollNumber(student), _bodyStyle());
        for (var sessionIndex = 0; sessionIndex < sessions.length; sessionIndex++) {
          final id = sessions[sessionIndex]['id'].toString();
          final mark = marksBySession[id]!.contains(studentId) ? 'P' : 'A';
          _setCell(sheet, 3 + sessionIndex, row, mark, _bodyStyle());
        }
      }
      sheet.setColumnWidth(0, 9);
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 13);
      for (var i = 0; i < sessions.length; i++) {
        sheet.setColumnWidth(3 + i, 10);
      }
      sheet.setRowHeight(0, 28);
      sheet.setRowHeight(1, 24);
      sheet.setRowHeight(3, 30);
    }

    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) throw Exception('Could not create annual workbook.');
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${cleanBranch}_${cleanYear}_${cleanCourse.replaceAll(RegExp(r'[^A-Z0-9]+'), '_')}_Annual_Attendance.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  bool _isPresentStatus(dynamic status) {
    if (status == true) return true;
    final value = status?.toString().trim().toLowerCase();
    return value == 'present' || value == 'p' || value == 'true';
  }

  Future<void> shareAnnualAttendanceWorkbook({
    required String branch,
    required String year,
    required String course,
  }) async {
    final path = await exportAnnualAttendanceWorkbook(
      branch: branch, year: year, course: course,
    );
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Annual Attendance Report - $course',
      text: 'Annual attendance workbook\nBranch: $branch\nYear: $year\nCourse: $course',
    );
  }

  // Creates a selected-month PDF in the application's documents directory.
  Future<String?> downloadAttendancePdf({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {
    final summary = await AttendanceSummaryService(firestore: _firestore)
        .getAttendanceSummary(
      branch: branch, year: year, course: course, month: month,
    );
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(build: (context) => [
      pw.Text('ATTENDANCE REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text('Branch: $branch    Year: $year    Course: $course    Month: $month'),
      pw.SizedBox(height: 14),
      pw.Table.fromTextArray(
        headers: const ['Sr No', 'Student Name', 'Roll No', 'Present', 'Absent', 'Attendance %', 'Status'],
        data: summary.asMap().entries.map((entry) {
          final s = entry.value;
          return ['${entry.key + 1}', s.studentName, s.rollNo, '${s.present}', '${s.absent}', '${s.attendancePercentage.toStringAsFixed(1)}%', s.status];
        }).toList(),
      ),
      pw.SizedBox(height: 12),
      pw.Text('Total students: ${summary.length}'),
    ]));

    final safeCourse = course.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final fileName = '${branch}_${year}_${safeCourse}_${month}_Attendance.pdf';
    final Uint8List bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ============================================================
  // GET ATTENDANCE MARK
  // ============================================================

  Future<String> _getAttendanceMark({
    required String sessionId,
    required String studentId,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('attendance')
          .doc(sessionId)
          .collection('students')
          .doc(studentId)
          .get();

      // No record = ABSENT
      if (!doc.exists) {
        return 'A';
      }

      final Map<String, dynamic>? data = doc.data();

      if (data == null) {
        return 'A';
      }

      final dynamic status = data['status'];

      // PRESENT
      if (status == 'Present' ||
          status == 'present' ||
          status == 'P' ||
          status == true) {
        return 'P';
      }

      // Everything else = ABSENT
      return 'A';
    } catch (e) {
      // A failed Firestore read is not proof of absence.
      rethrow;
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

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    final dynamic displayName = student['displayName'];

    if (displayName != null && displayName.toString().trim().isNotEmpty) {
      return displayName.toString().trim();
    }

    final dynamic fullName = student['fullName'];

    if (fullName != null && fullName.toString().trim().isNotEmpty) {
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
        student['rollNo'] ?? student['rollNumber'] ?? student['roll'];

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
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  // ============================================================
  // INFO STYLE
  // ============================================================

  CellStyle _infoStyle() {
    return CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
  }

  // ============================================================
  // HEADER STYLE
  // ============================================================

  CellStyle _headerStyle() {
    return CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
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
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
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

  // Save the generated XLSX through Android's system file picker (choose Downloads).
  Future<String?> downloadAttendanceExcel({
    required String branch, required String year, required String course,
    required String month, Map<String, String> editedMarks = const {},
  }) async {
    final path = await exportAttendanceSheet(
      branch: branch, year: year, course: course, month: month, editedMarks: editedMarks,
    );
    final file = File(path);
    if (!await file.exists()) throw Exception('Excel workbook was not generated.');
    final bytes = await file.readAsBytes();
    return FilePicker.saveFile(
      dialogTitle: 'Save Excel attendance workbook in Downloads',
      fileName: '${year}_${branch}_${course.trim()}.xlsx',
      type: FileType.custom, allowedExtensions: const ['xlsx'], bytes: bytes,
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
    final String filePath = await exportAttendanceSheet(
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
      subject: 'Attendance Report - $course',
      text: 'Attendance Report\n'
          'Branch: $branch\n'
          'Year: $year\n'
          'Course: $course\n'
          'Month: $month',
    );
  }
}
