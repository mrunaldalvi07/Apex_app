import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/attendance_summary_model.dart';
import '../services/notification_service.dart';
import 'attendance_summary_screen.dart';

class DetentionListScreen extends StatefulWidget {
  const DetentionListScreen({
    super.key, required String branch, required String year, required String course, required String month,
  });

  @override
  State<DetentionListScreen> createState() =>
      _DetentionListScreenState();
}

class _DetentionListScreenState
    extends State<DetentionListScreen> {
  // ============================================================
  // COLOUR SCHEME
  // ============================================================

  static const Color primaryNavy =
      Color(0xFF073B6F);

  static const Color darkNavy =
      Color(0xFF052B52);

  static const Color primaryBlue =
      Color(0xFF0B6EAA);

  static const Color cyan =
      Color(0xFF18A8C8);

  static const Color successGreen =
      Color(0xFF159957);

  static const Color warningOrange =
      Color(0xFF18A8C8);

  static const Color red =
      Color(0xFFE94B4B);

  static const Color background =
      Color(0xFFF5F8FC);

  static const Color textGrey =
      Color(0xFF6B7C93);

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // FILTER DATA
  // ============================================================

  final List<String> branches = [
    'IT',
    'CM',
    'IF',
    'CO',
    'ME',
    'CE',
    'EE',
  ];

  final List<String> years = [
    '1',
    '2',
    '3',
  ];

  final List<String> courses = [
    'Object Oriented Programming',
    'Database Management Systems',
    'Computer Networks',
    'Java Programming',
    'Python Programming',
  ];

  // ============================================================
  // SELECTED FILTERS
  // ============================================================

  String? selectedBranch;
  String? selectedYear;
  String? selectedCourse;

  // ============================================================
  // THRESHOLD
  // ============================================================

  final TextEditingController thresholdController =
      TextEditingController(
    text: '75',
  );

  double threshold = 75;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController searchController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool loading = false;

  bool notifying = false;

  bool printing = false;

  List<AttendanceSummaryModel> students = [];

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    thresholdController.addListener(
      _thresholdChanged,
    );
  }

  // ============================================================
  // THRESHOLD CHANGE
  // ============================================================

  void _thresholdChanged() {
    final value =
        double.tryParse(
      thresholdController.text,
    );

    if (value == null) {
      return;
    }

    if (value < 0 || value > 100) {
      return;
    }

    setState(() {
      threshold = value;
    });
  }

  // ============================================================
  // LOAD ATTENDANCE
  // ============================================================

  Future<void> loadDetentionData() async {
    if (selectedBranch == null ||
        selectedYear == null ||
        selectedCourse == null) {
      _showMessage(
        'Please select Branch, Year and Course.',
        isError: true,
      );

      return;
    }

    final enteredThreshold =
        double.tryParse(
      thresholdController.text,
    );

    if (enteredThreshold == null ||
        enteredThreshold < 0 ||
        enteredThreshold > 100) {
      _showMessage(
        'Enter a valid threshold between 0 and 100.',
        isError: true,
      );

      return;
    }

    setState(() {
      loading = true;
      threshold = enteredThreshold;
    });

    try {
      // ========================================================
      // GET STUDENTS
      // ========================================================

      final studentsSnapshot =
          await _firestore
              .collection('users')
              .where(
                'role',
                isEqualTo: 'student',
              )
              .where(
                'branch',
                isEqualTo: selectedBranch,
              )
              .where(
                'year',
                isEqualTo: selectedYear,
              )
              .get();

      // ========================================================
      // GET ENDED SESSIONS
      // ========================================================

      final sessionsSnapshot =
          await _firestore
              .collection('live_sessions')
              .where(
                'branch',
                isEqualTo: selectedBranch,
              )
              .where(
                'year',
                isEqualTo: selectedYear,
              )
              .where(
                'course',
                isEqualTo:
                    selectedCourse!.toUpperCase(),
              )
              .where(
                'status',
                isEqualTo: 'ended',
              )
              .get();

      final sessions =
          sessionsSnapshot.docs.toList();

      sessions.sort((a, b) {
        final aValue =
            a.data()['createdAt'];

        final bValue =
            b.data()['createdAt'];

        if (aValue is Timestamp &&
            bValue is Timestamp) {
          return aValue
              .compareTo(bValue);
        }

        return 0;
      });

      // ========================================================
      // SORT STUDENTS BY ROLL NUMBER
      // ========================================================

      final studentDocs =
          studentsSnapshot.docs.toList();

      studentDocs.sort((a, b) {
        final rollA =
            (a.data()['rollNo'] ?? '')
                .toString();

        final rollB =
            (b.data()['rollNo'] ?? '')
                .toString();

        final numA =
            int.tryParse(rollA);

        final numB =
            int.tryParse(rollB);

        if (numA != null &&
            numB != null) {
          return numA.compareTo(numB);
        }

        return rollA.compareTo(
          rollB,
        );
      });

      // ========================================================
      // CREATE SUMMARY
      // ========================================================

      final result =
          <AttendanceSummaryModel>[];

      for (final student
          in studentDocs) {
        int present = 0;
        int absent = 0;

        for (final session
            in sessions) {
          final attendance =
              await _firestore
                  .collection(
                      'attendance')
                  .doc(session.id)
                  .collection(
                      'students')
                  .doc(student.id)
                  .get();

          final status =
              attendance.data()?[
                  'status'];

          if (status == 'Present' ||
              status == 'present' ||
              status == true) {
            present++;
          } else {
            absent++;
          }
        }

        final totalClasses =
            sessions.length;

        final percentage =
            totalClasses == 0
                ? 0.0
                : (present /
                        totalClasses) *
                    100;

        final data =
            student.data();

        result.add(
          AttendanceSummaryModel(
            studentId: student.id,
            rollNo:
                (data['rollNo'] ?? '')
                    .toString(),
            studentName:
                (data['name'] ??
                        data['displayName'] ??
                        '')
                    .toString(),
            present: present,
            absent: absent,
            totalClasses:
                totalClasses,
            attendancePercentage:
                percentage,
            status:
                percentage < threshold
                    ? 'Detained'
                    : 'Regular',
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        students = result;
      });

      _showMessage(
        'Detention list generated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to generate detention list: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // DETAINED STUDENTS
  // ============================================================

  List<AttendanceSummaryModel>
      get detainedStudents {
    return students.where(
      (student) {
        return student.attendancePercentage <
            threshold;
      },
    ).toList();
  }

  // ============================================================
  // FILTERED DETAINED STUDENTS
  // ============================================================

  List<AttendanceSummaryModel>
      get filteredDetainedStudents {
    final query =
        searchController.text
            .trim()
            .toLowerCase();

    return detainedStudents.where(
      (student) {
        if (query.isEmpty) {
          return true;
        }

        return student.studentName
                .toLowerCase()
                .contains(query) ||
            student.rollNo
                .toLowerCase()
                .contains(query);
      },
    ).toList();
  }

  // ============================================================
  // NOTIFY ONE STUDENT
  // ============================================================

  Future<void> notifyStudent(
    AttendanceSummaryModel student,
  ) async {
    if (selectedCourse == null) {
      return;
    }

    try {
      await NotificationService()
          .sendAttendanceWarning(
        studentId:
            student.studentId,
        course:
            selectedCourse!,
        percentage:
            student.attendancePercentage,
      );

      if (!mounted) return;

      _showMessage(
        'Notification sent to ${student.studentName}.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Notification failed: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // NOTIFY ALL
  // ============================================================

  Future<void> notifyAll() async {
    final detained =
        detainedStudents;

    if (detained.isEmpty) {
      _showMessage(
        'No detained students available.',
        isError: true,
      );

      return;
    }

    setState(() {
      notifying = true;
    });

    int successCount = 0;

    try {
      for (final student in detained) {
        try {
          await NotificationService()
              .sendAttendanceWarning(
            studentId:
                student.studentId,
            course:
                selectedCourse!,
            percentage:
                student.attendancePercentage,
          );

          successCount++;
        } catch (_) {
          // Continue notifying remaining students.
        }
      }

      if (!mounted) return;

      _showMessage(
        '$successCount of ${detained.length} notifications sent.',
      );
    } finally {
      if (mounted) {
        setState(() {
          notifying = false;
        });
      }
    }
  }

  // ============================================================
  // PRINT DETENTION LIST
  // ============================================================

  Future<void> printDetentionList() async {
    final detained =
        detainedStudents;

    if (detained.isEmpty) {
      _showMessage(
        'No detained students to print.',
        isError: true,
      );

      return;
    }

    setState(() {
      printing = true;
    });

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (context) {
            return [
              pw.Text(
                'DETENTION LIST',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(
                height: 8,
              ),

              pw.Text(
                'Branch: ${selectedBranch ?? '-'}',
              ),

              pw.Text(
                'Year: ${selectedYear ?? '-'} Year',
              ),

              pw.Text(
                'Course: ${selectedCourse ?? '-'}',
              ),

              pw.Text(
                'Detention Threshold: ${threshold.toStringAsFixed(0)}%',
              ),

              pw.SizedBox(
                height: 15,
              ),

              pw.Table.fromTextArray(
                headers: const [
                  'Sr. No.',
                  'Roll No.',
                  'Student Name',
                  'Present',
                  'Absent',
                  'Attendance',
                  'Status',
                ],
                data: detained
                    .asMap()
                    .entries
                    .map(
                  (entry) {
                    final student =
                        entry.value;

                    return [
                      '${entry.key + 1}',
                      student.rollNo,
                      student.studentName,
                      '${student.present}',
                      '${student.absent}',
                      '${student.attendancePercentage.toStringAsFixed(1)}%',
                      'DETAINED',
                    ];
                  },
                ).toList(),
              ),

              pw.SizedBox(
                height: 15,
              ),

              pw.Text(
                'Total Detained Students: ${detained.length}',
                style: pw.TextStyle(
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async =>
            pdf.save(),
      );

      if (!mounted) return;

      _showMessage(
        'Detention list sent to printer.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to print detention list: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          printing = false;
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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          backgroundColor:
              isError
                  ? red
                  : successGreen,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    thresholdController
        .removeListener(
      _thresholdChanged,
    );

    thresholdController.dispose();
    searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: darkNavy,
            size: 19,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),

        title: const Text(
          'Detention Management',
          style: TextStyle(
            color: darkNavy,
            fontSize: 19,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: darkNavy,
            ),
            onPressed:
                loadDetentionData,
          ),
        ],
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: primaryBlue,
              ),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [
                _buildFilterCard(),

                const SizedBox(
                    height: 15),

                _buildDetentionSummary(),

                const SizedBox(
                    height: 15),

                _buildSearch(),

                const SizedBox(
                    height: 15),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      'Detained Students',
                      style: TextStyle(
                        color: darkNavy,
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${filteredDetainedStudents.length} Students',
                      style:
                          const TextStyle(
                        color:
                            primaryBlue,
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                    height: 10),

                if (selectedBranch == null ||
                    selectedYear == null ||
                    selectedCourse == null)
                  _buildInitialMessage()
                else if (students.isEmpty)
                  _empty()
                else if (filteredDetainedStudents
                    .isEmpty)
                  _empty()
                else
                  ...filteredDetainedStudents
                      .asMap()
                      .entries
                      .map(
                    (entry) {
                      return _studentCard(
                        entry.key + 1,
                        entry.value,
                      );
                    },
                  ),

                const SizedBox(
                    height: 15),

                _buildNotifyButton(),

                const SizedBox(
                    height: 10),

                _buildPrintButton(),

                const SizedBox(
                    height: 10),

              ],
            ),
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _buildFilterCard() {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              const Color(0xFFE1E8F0),
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Color(0x10000000),
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
                Icons.filter_alt_rounded,
                color: primaryBlue,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Detention Filters',
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
              height: 15),

          _dropdown(
            label: 'Branch',
            value: selectedBranch,
            items: branches,
            icon:
                Icons.account_balance_rounded,
            onChanged: (value) {
              setState(() {
                selectedBranch =
                    value;
                students = [];
              });
            },
          ),

          const SizedBox(
              height: 11),

          _dropdown(
            label: 'Year',
            value: selectedYear,
            items: years,
            icon:
                Icons.calendar_today_rounded,
            labelBuilder: (value) =>
                '$value Year',
            onChanged: (value) {
              setState(() {
                selectedYear =
                    value;
                students = [];
              });
            },
          ),

          const SizedBox(
              height: 11),

          _dropdown(
            label: 'Course',
            value: selectedCourse,
            items: courses,
            icon: Icons.school_rounded,
            onChanged: (value) {
              setState(() {
                selectedCourse =
                    value;
                students = [];
              });
            },
          ),

          const SizedBox(
              height: 11),

          // THRESHOLD
          TextField(
            controller:
                thresholdController,

            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),

            decoration:
                InputDecoration(
              labelText:
                  'Detention Threshold (%)',
              prefixIcon:
                  const Icon(
                Icons.percent_rounded,
                color: Color(0xFF18A8C8)
                ,
              ),
              suffixText: '%',

              filled: true,

              fillColor:
                  const Color(
                0xFFF9FBFD,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFE0E7EF),
                ),
              ),

              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFE0E7EF),
                ),
              ),

              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFF18A8C8),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(
              height: 12),

          SizedBox(
            width:
                double.infinity,
            height: 46,

            child:
                ElevatedButton.icon(
              onPressed:
                  loading
                      ? null
                      : loadDetentionData,

              icon: const Icon(
                Icons.search_rounded,
              ),

              label: const Text(
                'GENERATE DETENTION LIST',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryBlue,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    String Function(String)?
        labelBuilder,
    required ValueChanged<String?>
        onChanged,
  }) {
    return DropdownButtonFormField<
        String>(
      initialValue: value,

      isExpanded: true,

      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: primaryNavy,
      ),

      decoration:
          InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          icon,
          color: primaryBlue,
          size: 21,
        ),

        filled: true,

        fillColor:
            const Color(0xFFF9FBFD),

        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 12,
          vertical: 14,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE0E7EF),
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              const BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),
      ),

      items: items.map(
        (item) {
          return DropdownMenuItem<
              String>(
            value: item,
            child: Text(
              labelBuilder != null
                  ? labelBuilder(
                      item,
                    )
                  : item,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: darkNavy,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          );
        },
      ).toList(),

      onChanged: onChanged,
    );
  }

  // ============================================================
  // DETENTION SUMMARY
  // ============================================================

  Widget _buildDetentionSummary() {
    final count =
        detainedStudents.length;

    return Container(
      padding:
          const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color:
            const Color(0xFFFFF7ED),

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              const Color(0xFFFFE0BF),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Detention Summary',
                  style: TextStyle(
                    color: darkNavy,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),

              Container(
                width: 40,
                height: 40,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFFFE6D1),
                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons.warning_amber,
                  color:
                     Color(0xFF18A8C8),
                ),
              ),
            ],
          ),

          const SizedBox(
              height: 6),

          Text(
            'Students below ${threshold.toStringAsFixed(0)}% attendance',
            style:
                const TextStyle(
              color: textGrey,
              fontSize: 11,
            ),
          ),

          const SizedBox(
              height: 16),

          Row(
            children: [
              _summaryValue(
                '$count',
                'Detained Students',
                red,
              ),

              _summaryValue(
                '${threshold.toStringAsFixed(0)}%',
                'Required Attendance',
                warningOrange,
              ),

              _summaryValue(
                students.isEmpty
                    ? '-'
                    : '${students.length}',
                'Total Students',
                primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY VALUE
  // ============================================================

  Widget _summaryValue(
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
              height: 3),

          Text(
            label,
            style:
                const TextStyle(
              color: textGrey,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          searchController,

      onChanged: (_) {
        setState(() {});
      },

      decoration:
          InputDecoration(
        prefixIcon:
            const Icon(
          Icons.search,
          color: primaryBlue,
        ),

        hintText:
            'Search student or roll no.',

        filled: true,

        fillColor:
            Colors.white,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _studentCard(
    int index,
    AttendanceSummaryModel student,
  ) {
    final percentage =
        student.attendancePercentage;

    final deficit =
        threshold - percentage;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),

      padding:
          const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(13),

        border: Border.all(
          color:
              const Color(0xFFE4ECF3),
        ),
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 19,

            backgroundColor:
                const Color(
              0xFFEAF2F8,
            ),

            child: Text(
              index
                  .toString()
                  .padLeft(2, '0'),

              style:
                  const TextStyle(
                color:
                    primaryBlue,
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(
              width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  student.studentName,
                  style:
                      const TextStyle(
                    color:
                        darkNavy,
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                    height: 3),

                Text(
                  'Roll No. ${student.rollNo}',
                  style:
                      const TextStyle(
                    color:
                        textGrey,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(
                    height: 3),

                Text(
                  'Short by ${deficit.toStringAsFixed(1)}%',
                  style:
                      const TextStyle(
                    color:
                        red,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .end,

            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style:
                    const TextStyle(
                  color: red,
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 15,
                ),
              ),

              const Text(
                'DETAINED',
                style:
                    TextStyle(
                  color: red,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          IconButton(
            onPressed:
                () => notifyStudent(
              student,
            ),

            icon:
                const Icon(
              Icons
                  .notifications_none,
              color:
                  Color(0xFF18A8C8),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFY BUTTON
  // ============================================================

  Widget _buildNotifyButton() {
    return SizedBox(
      height: 48,
      width:
          double.infinity,

      child:
          ElevatedButton.icon(
        onPressed:
            notifying
                ? null
                : notifyAll,

        icon: notifying
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      Colors.white,
                ),
              )
            : const Icon(
                Icons
                    .notifications_active,
              ),

        label: Text(
          notifying
              ? 'SENDING NOTIFICATIONS...'
              : 'NOTIFY ALL DETAINED STUDENTS',
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              Color(0xFF18A8C8),
          foregroundColor:
              Colors.white,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRINT BUTTON
  // ============================================================

  Widget _buildPrintButton() {
    return SizedBox(
      height: 48,
      width:
          double.infinity,

      child:
          OutlinedButton.icon(
        onPressed:
            printing
                ? null
                : printDetentionList,

        icon: printing
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                     Color(0xFF18A8C8),
                ),
              )
            : const Icon(
                Icons.print,
                color:
                    Color(0xFF18A8C8),
              ),

        label: Text(
          printing
              ? 'PREPARING PRINT...'
              : 'PRINT DETENTION LIST',

          style:
              const TextStyle(
            color: darkNavy,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        style:
            OutlinedButton.styleFrom(
          side:
              const BorderSide(
            color:
                Color(0xFF18A8C8),
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      ),
    );
  }


  // ============================================================
  // CURRENT MONTH
  // ============================================================

  String _currentMonth() {
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

    return months[
        DateTime.now().month - 1];
  }

  // ============================================================
  // INITIAL MESSAGE
  // ============================================================

  Widget _buildInitialMessage() {
    return Container(
      padding:
          const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
      ),

      child: const Center(
        child: Text(
          'Select Branch, Year and Course,\nthen generate the detention list.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color: textGrey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _empty() {
    return Container(
      padding:
          const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
      ),

      child: const Center(
        child: Text(
          'No detained students for the selected filters.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color: textGrey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
