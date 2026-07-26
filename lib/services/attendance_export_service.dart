import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceExportService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> exportAttendanceSheet({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {

    // -----------------------------
    // Get Students
    // -----------------------------
    final students = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .get();

    // -----------------------------
    // Get Attendance Sessions
    // -----------------------------
    final sessions = await firestore
        .collection('live_sessions')
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .where('course', isEqualTo: course)
        .where('status', isEqualTo: 'ended')
        .get();

    // -----------------------------
    // Filter Sessions by Month
    // -----------------------------
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

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        sessionDocs = [];

    for (final session in sessions.docs) {
      final Timestamp? timestamp =
          session.data()['createdAt'] as Timestamp?;

      if (timestamp == null) continue;

      final sessionMonth =
          monthNames[timestamp.toDate().month];

      if (sessionMonth == month) {
        sessionDocs.add(session);
      }
    }

    // -----------------------------
    // Sort Sessions by Date
    // -----------------------------
    sessionDocs.sort((a, b) {
      final Timestamp ta = a['createdAt'];
      final Timestamp tb = b['createdAt'];

      return ta.toDate().compareTo(
        tb.toDate(),
      );
    });
    // -----------------------------
    // Create / Open Excel File
    // -----------------------------
    final directory =
        await getApplicationDocumentsDirectory();

    final file = File(
      "${directory.path}/${year}_${branch}_${course}.xlsx",
    );

    Excel excel;

    if (await file.exists()) {
      excel = Excel.decodeBytes(
        await file.readAsBytes(),
      );
    } else {
      excel = Excel.createExcel();

      // Remove default sheet if present
      if (excel.tables.containsKey("Sheet1")) {
        excel.delete("Sheet1");
      }
    }

    // -----------------------------
    // Create Monthly Worksheet
    // -----------------------------
    if (excel.tables.containsKey(month)) {
      excel.delete(month);
    }

    final sheet = excel[month];

    // -----------------------------
    // Header Row
    // -----------------------------
    sheet.appendRow([
      TextCellValue("Sr No"),
      TextCellValue("Roll No"),
      TextCellValue("Student Name"),
    ]);

    // -----------------------------
    // Session Date Headers
    // -----------------------------
    int dateColumn = 3;

    for (final session in sessionDocs) {
      final Timestamp ts = session['createdAt'];

      final date =
          "${ts.toDate().day.toString().padLeft(2, '0')}-"
          "${ts.toDate().month.toString().padLeft(2, '0')}";

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

    // -----------------------------
    // Monthly Summary Columns
    // -----------------------------
    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: dateColumn,
            rowIndex: 0,
          ),
        )
        .value = TextCellValue("Present");

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: dateColumn + 1,
            rowIndex: 0,
          ),
        )
        .value = TextCellValue("Absent");

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: dateColumn + 2,
            rowIndex: 0,
          ),
        )
        .value = TextCellValue("Attendance %");

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: dateColumn + 3,
            rowIndex: 0,
          ),
        )
        .value = TextCellValue("Status");
        // -----------------------------
    // Sort Students by Roll Number
    // -----------------------------
    final studentDocs = students.docs.toList();

    studentDocs.sort((a, b) {
      final rollA = (a['rollNo'] ?? '').toString();
      final rollB = (b['rollNo'] ?? '').toString();
      return rollA.compareTo(rollB);
    });

    int row = 1;
    int srNo = 1;

    // -----------------------------
    // Fill Student Attendance
    // -----------------------------
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

      int present = 0;
      int absent = 0;

      for (final session in sessionDocs) {
        final attendanceDoc = await firestore
            .collection('attendance')
            .doc(session.id)
            .collection('students')
            .doc(student.id)
            .get();

        String mark = "A";

        if (attendanceDoc.exists) {
          final attendance =
              attendanceDoc.data();

          if (attendance != null &&
              attendance['status'] ==
                  'Present') {
            mark = "P";
            present++;
          } else {
            absent++;
          }
        } else {
          absent++;
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

      final totalClasses =
          sessionDocs.length;

      double percentage = 0;

      if (totalClasses > 0) {
        percentage =
            (present / totalClasses) * 100;
      }

      final status =
          percentage >= 75
              ? "Regular"
              : "Detained";

      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: column,
              rowIndex: row,
            ),
          )
          .value = TextCellValue(
        present.toString(),
      );

      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: column + 1,
              rowIndex: row,
            ),
          )
          .value = TextCellValue(
        absent.toString(),
      );

      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: column + 2,
              rowIndex: row,
            ),
          )
          .value = TextCellValue(
        percentage.toStringAsFixed(2),
      );

      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: column + 3,
              rowIndex: row,
            ),
          )
          .value = TextCellValue(status);

      srNo++;
      row++;
    }
    // =====================================================
// PART 4A
// CREATE OVERALL SUMMARY SHEET
// =====================================================

final summarySheet =
    excel['Overall Summary'];


// -----------------------------
// Summary Title
// -----------------------------

summarySheet.merge(
  CellIndex.indexByString("A1"),
  CellIndex.indexByString("J1"),
);

summarySheet
    .cell(
      CellIndex.indexByString("A1"),
    )
    .value =
    TextCellValue(
      "$course - Overall Attendance Summary",
    );


// -----------------------------
// Header Row
// -----------------------------

summarySheet.appendRow([
  TextCellValue("Sr No"),
  TextCellValue("Roll No"),
  TextCellValue("Student Name"),
  TextCellValue("Total Classes"),
  TextCellValue("Present"),
  TextCellValue("Absent"),
  TextCellValue("Attendance %"),
  TextCellValue("Status"),
  TextCellValue("Month Wise Details"),
  TextCellValue("Remarks"),
]);


// -----------------------------
// Header Styling
// -----------------------------

for(int i = 0; i < 10; i++){

  summarySheet
      .cell(
        CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: 1,
        ),
      )
      .cellStyle =
      CellStyle(
        bold: true,
        horizontalAlign:
            HorizontalAlign.Center,
      );
}


// -----------------------------
// Set Column Width
// -----------------------------

summarySheet.setColumnWidth(
    0, 8);

summarySheet.setColumnWidth(
    1, 15);

summarySheet.setColumnWidth(
    2, 25);

summarySheet.setColumnWidth(
    3, 15);

summarySheet.setColumnWidth(
    4, 12);

summarySheet.setColumnWidth(
    5, 12);

summarySheet.setColumnWidth(
    6, 15);

summarySheet.setColumnWidth(
    7, 15);

summarySheet.setColumnWidth(
    8, 30);

summarySheet.setColumnWidth(
    9, 20);
    // =====================================================
// PART 4B
// READ MONTHLY SHEETS AND CALCULATE TOTALS
// =====================================================


// -----------------------------
// Month Sheet Names
// -----------------------------

final months = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];


// -----------------------------
// Fetch Students Again
// -----------------------------

final studentsSnapshot =
    await firestore
        .collection('users')
        .where(
          'branch',
          isEqualTo: branch,
        )
        .where(
          'year',
          isEqualTo: year,
        )
        .where(
          'role',
          isEqualTo: 'student',
        )
        .get();


final summaryStudents =
    studentsSnapshot.docs.toList();


// Sort by Roll Number

summaryStudents.sort((a,b){

  final rollA =
      (a['rollNo'] ?? '').toString();

  final rollB =
      (b['rollNo'] ?? '').toString();

  return rollA.compareTo(rollB);

});



// -----------------------------
// Process Each Student
// -----------------------------


int summaryRow = 2;
int summarySrNo = 1;


for(final student in summaryStudents){

  final studentData =
      student.data();


  int totalClasses = 0;
  int totalPresent = 0;
  int totalAbsent = 0;


  List<String> monthDetails = [];



  // -----------------------------
  // Read Every Month Sheet
  // -----------------------------

  for(final month in months){


    if(!excel.sheets.containsKey(month)){
      continue;
    }


    final monthSheet =
        excel[month];


    int lastRow =
        monthSheet.maxRows;


    int studentRow = -1;



    // Find Student Row

    for(int r = 2; r <= lastRow; r++){


      final rollCell =
          monthSheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 1,
                  rowIndex: r,
                ),
              )
              .value;


      if(
        rollCell != null &&
        rollCell
            .toString()
            .contains(
              (studentData['rollNo'] ?? '')
                  .toString()
            )
      ){

        studentRow = r;
        break;
      }

    }



    if(studentRow == -1){
      continue;
    }



    int monthPresent = 0;
    int monthAbsent = 0;



    // Attendance Columns Start From Column 4

    for(int c = 3; c < 50; c++){


      final value =
          monthSheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: c,
                  rowIndex: studentRow,
                ),
              )
              .value;


      if(value == null){
        continue;
      }


      String mark =
          value.toString();


      if(mark == "P"){

        totalPresent++;
        monthPresent++;

      }
      else if(mark == "A"){

        totalAbsent++;
        monthAbsent++;

      }


      if(mark == "P" || mark == "A"){
        totalClasses++;
      }

    }



    if(monthPresent + monthAbsent > 0){

      monthDetails.add(
        "$month : P=$monthPresent A=$monthAbsent"
      );

    }

  }



  // -----------------------------
  // Calculate Percentage
  // -----------------------------


  double percentage = 0;


  if(totalClasses > 0){

    percentage =
        (totalPresent / totalClasses) * 100;

  }



  String status =
      percentage >= 75
          ? "Regular"
          : "Detained";



  // Data storage for Part 4C

  summarySheet.appendRow([

    TextCellValue(
      summarySrNo.toString(),
    ),

    TextCellValue(
      (studentData['rollNo'] ?? '')
          .toString(),
    ),

    TextCellValue(
      (studentData['name'] ?? '')
          .toString(),
    ),

    TextCellValue(
      totalClasses.toString(),
    ),

    TextCellValue(
      totalPresent.toString(),
    ),

    TextCellValue(
      totalAbsent.toString(),
    ),

    TextCellValue(
      percentage
          .toStringAsFixed(2),
    ),

    TextCellValue(
      status,
    ),

    TextCellValue(
      monthDetails.join("\n"),
    ),

    TextCellValue(
      "",
    ),

  ]);



  summarySrNo++;
  summaryRow++;

}
// =====================================================
// PART 4C
// FORMAT, SAVE AND SHARE EXCEL FILE
// =====================================================


// -----------------------------
// Overall Summary Formatting
// -----------------------------

for(int i = 0; i < 10; i++){

  summarySheet
      .cell(
        CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: 1,
        ),
      )
      .cellStyle = CellStyle(
        bold: true,
        horizontalAlign:
            HorizontalAlign.Center,
        verticalAlign:
            VerticalAlign.Center,
      );

}



// -----------------------------
// Apply Row Height
// -----------------------------

summarySheet.setRowHeight(
    0, 25);

summarySheet.setRowHeight(
    1, 22);


// -----------------------------
// Generate Excel Bytes
// -----------------------------

final excelBytes =
    excel.encode();



if(excelBytes == null){

  throw Exception(
      "Excel generation failed");

}



// -----------------------------
// Create File Path
// -----------------------------

final saveDirectory =
    await getApplicationDocumentsDirectory();


final filePath =
    "${saveDirectory.path}/"
    "${course}_Attendance_Report.xlsx";



final reportFile =
    File(filePath);



// -----------------------------
// Write Excel File
// -----------------------------

await reportFile.writeAsBytes(
  excelBytes,
  flush: true,
);



// -----------------------------
// Share File
// -----------------------------

await Share.shareXFiles(
  [
    XFile(
      reportFile.path,
    ),
  ],

  text:
      "$course Attendance Report",

);
  }
}