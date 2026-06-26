import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceExportService {
  Future<void> exportAttendanceSheet({
    required String branch,
    required String year,
    required String course,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final students = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .get();

    final sessions = await firestore
        .collection('live_sessions')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .where('course', isEqualTo: course)
        .where('status', isEqualTo: 'ended')
        .get();

    final sessionDocs = sessions.docs.toList();

    sessionDocs.sort((a, b) {
      final Timestamp ta = a['createdAt'];
      final Timestamp tb = b['createdAt'];
      return ta.toDate().compareTo(tb.toDate());
    });

    final dir = await getApplicationDocumentsDirectory();

    final path =
        "${dir.path}/${branch}_${year}_$course.xlsx";

    final file = File(path);

    Excel excel;

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      excel = Excel.decodeBytes(bytes);
    } else {
      excel = Excel.createExcel();
    }

    final now = DateTime.now();

    const monthNames = [
      '',
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

    final sheetName = monthNames[now.month];

    if (excel.tables.containsKey(sheetName)) {
      excel.delete(sheetName);
    }

    final sheet = excel[sheetName];

    // Header Row
    sheet.appendRow([
      TextCellValue("Sr No"),
      TextCellValue("Roll No"),
      TextCellValue("Name"),
    ]);

    // Date Headers
    int dateColumn = 3;

    for (final session in sessionDocs) {
      final Timestamp? ts =
          session.data()['createdAt'] as Timestamp?;

      final date = ts == null
          ? "Date"
          : "${ts.toDate().day.toString().padLeft(2, '0')}-"
              "${ts.toDate().month.toString().padLeft(2, '0')}-"
              "${ts.toDate().year}";

      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: dateColumn,
              rowIndex: 0,
            ),
          )
          .value = TextCellValue(date);

      dateColumn++;
    }

    // Sort students by Roll No
    final studentDocs = students.docs.toList();

    studentDocs.sort((a, b) {
      final rollA = (a['rollNo'] ?? '').toString();
      final rollB = (b['rollNo'] ?? '').toString();
      return rollA.compareTo(rollB);
    });

    int row = 1;
    int srNo = 1;

    for (final student in studentDocs) {
      final studentData = student.data();

      sheet.appendRow([
        TextCellValue(srNo.toString()),
        TextCellValue(
          (studentData['rollNo'] ?? '').toString(),
        ),
        TextCellValue(
          (studentData['name'] ?? '').toString(),
        ),
      ]);

      int column = 3;

      for (final session in sessionDocs) {
        final attendanceDoc = await firestore
            .collection('attendance')
            .doc(session.id)
            .collection('students')
            .doc(student.id)
            .get();

        String mark = "A";

        if (attendanceDoc.exists) {
          final data = attendanceDoc.data();

          if (data != null &&
              data['status'] == 'Present') {
            mark = 'P';
          }
        }

        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: column,
                rowIndex: row,
              ),
            )
            .value = TextCellValue(mark);

        column++;
      }

      srNo++;
      row++;
    }

    final bytes = excel.encode();

    if (bytes != null) {
      await file.writeAsBytes(
        bytes,
        flush: true,
      );
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: "Attendance Report",
      ),
    );
  }
}