import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  // ============================================================
  // COLOURS
  // ============================================================

  static const Color primaryNavy = Color(0xFF073B6F);
  static const Color darkNavy = Color(0xFF052B52);
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color cyan = Color(0xFF18A8C8);
  static const Color successGreen = Color(0xFF159957);
  static const Color warningOrange = Color(0xFFF39A23);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // DATA
  // ============================================================

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> sessions = [];

  // ============================================================
  // MONTH NUMBER
  // ============================================================

  int _monthNumber(String month) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };

    return months[month] ?? 0;
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // --------------------------------------------------------
      // STUDENTS
      // --------------------------------------------------------

      final studentsSnapshot = await _firestore
          .collection('users')
          .where(
            'role',
            isEqualTo: 'student',
          )
          .where(
            'branch',
            isEqualTo: widget.branch,
          )
          .where(
            'year',
            isEqualTo: widget.year,
          )
          .get();

      final loadedStudents =
          studentsSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // --------------------------------------------------------
      // SORT STUDENTS
      // --------------------------------------------------------

      loadedStudents.sort((a, b) {
        final rollA =
            (a['rollNo'] ?? '').toString();

        final rollB =
            (b['rollNo'] ?? '').toString();

        final numberA =
            int.tryParse(rollA);

        final numberB =
            int.tryParse(rollB);

        if (numberA != null &&
            numberB != null) {
          return numberA.compareTo(numberB);
        }

        return rollA.compareTo(rollB);
      });

      // --------------------------------------------------------
      // SESSIONS
      // --------------------------------------------------------

      final sessionsSnapshot = await _firestore
          .collection('live_sessions')
          .where(
            'branch',
            isEqualTo: widget.branch,
          )
          .where(
            'year',
            isEqualTo: widget.year,
          )
          .where(
            'course',
            isEqualTo: widget.course,
          )
          .where(
            'status',
            isEqualTo: 'ended',
          )
          .get();

      final monthNumber =
          _monthNumber(widget.month);

      final loadedSessions = <Map<String, dynamic>>[];

      for (final doc in sessionsSnapshot.docs) {
        final data = doc.data();

        final createdAt =
            data['createdAt'];

        if (createdAt is! Timestamp) {
          continue;
        }

        final date =
            createdAt.toDate();

        if (date.month != monthNumber) {
          continue;
        }

        loadedSessions.add({
          'id': doc.id,
          ...data,
        });
      }

      // --------------------------------------------------------
      // SORT SESSIONS BY DATE
      // --------------------------------------------------------

      loadedSessions.sort((a, b) {
        final dateA =
            a['createdAt'] as Timestamp;

        final dateB =
            b['createdAt'] as Timestamp;

        return dateA
            .toDate()
            .compareTo(dateB.toDate());
      });

      if (!mounted) return;

      setState(() {
        students = loadedStudents;
        sessions = loadedSessions;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load attendance preview.\n$e';
      });
    }
  }

  // ============================================================
  // ATTENDANCE FOR STUDENT
  // ============================================================

  Future<String> _getAttendanceMark(
    String sessionId,
    String studentId,
  ) async {
    try {
      final doc = await _firestore
          .collection('attendance')
          .doc(sessionId)
          .collection('students')
          .doc(studentId)
          .get();

      if (!doc.exists) {
        return 'A';
      }

      final data = doc.data();

      if (data?['status'] == 'Present') {
        return 'P';
      }

      return 'A';
    } catch (_) {
      return 'A';
    }
  }

  // ============================================================
  // STUDENT ROW
  // ============================================================

  Widget _buildStudentRow(
    int index,
    Map<String, dynamic> student,
  ) {
    final studentId =
        student['id'].toString();

    final rollNo =
        (student['rollNo'] ?? '').toString();

    final name =
        (student['name'] ?? '').toString();

    return FutureBuilder<List<String>>(
      future: Future.wait(
        sessions.map(
          (session) => _getAttendanceMark(
            session['id'].toString(),
            studentId,
          ),
        ),
      ),
      builder: (
        context,
        snapshot,
      ) {
        if (!snapshot.hasData) {
          return _buildLoadingRow(
            index,
            rollNo,
            name,
          );
        }

        final marks = snapshot.data!;

        int present = 0;
        int absent = 0;

        for (final mark in marks) {
          if (mark == 'P') {
            present++;
          } else {
            absent++;
          }
        }

        final total = marks.length;

        final percentage = total == 0
            ? 0.0
            : (present / total) * 100;

        final detained =
            percentage < 75;

        return Container(
          decoration: BoxDecoration(
            color: index.isEven
                ? Colors.white
                : const Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
          ),
          child: Row(
            children: [
              _cell(
                '${index + 1}',
                width: 55,
                center: true,
              ),

              _cell(
                rollNo,
                width: 75,
                center: true,
              ),

              _cell(
                name,
                width: 180,
              ),

              ...List.generate(
                marks.length,
                (i) {
                  return _attendanceCell(
                    marks[i],
                  );
                },
              ),

              _cell(
                '$present',
                width: 75,
                center: true,
              ),

              _cell(
                '$absent',
                width: 75,
                center: true,
              ),

              _cell(
                percentage.toStringAsFixed(1),
                width: 100,
                center: true,
              ),

              SizedBox(
                width: 95,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: detained
                          ? warningOrange
                              .withValues(alpha: 0.12)
                          : successGreen
                              .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      detained
                          ? 'Detained'
                          : 'Regular',
                      style: TextStyle(
                        color: detained
                            ? warningOrange
                            : successGreen,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // LOADING ROW
  // ============================================================

  Widget _buildLoadingRow(
    int index,
    String rollNo,
    String name,
  ) {
    return Container(
      height: 55,
      color: index.isEven
          ? Colors.white
          : const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _cell(
            '${index + 1}',
            width: 55,
            center: true,
          ),
          _cell(
            rollNo,
            width: 75,
            center: true,
          ),
          _cell(
            name,
            width: 180,
          ),
          ...List.generate(
            sessions.length,
            (_) => _cell(
              '...',
              width: 55,
              center: true,
            ),
          ),
          _cell(
            '...',
            width: 75,
            center: true,
          ),
          _cell(
            '...',
            width: 75,
            center: true,
          ),
          _cell(
            '...',
            width: 100,
            center: true,
          ),
          _cell(
            '...',
            width: 95,
            center: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NORMAL CELL
  // ============================================================

  Widget _cell(
    String text, {
    required double width,
    bool center = false,
  }) {
    return SizedBox(
      width: width,
      height: 55,
      child: Container(
        alignment: center
            ? Alignment.center
            : Alignment.centerLeft,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: center
              ? TextAlign.center
              : TextAlign.left,
          style: const TextStyle(
            fontSize: 12,
            color: darkNavy,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ATTENDANCE CELL
  // ============================================================

  Widget _attendanceCell(
    String mark,
  ) {
    final present = mark == 'P';

    return SizedBox(
      width: 55,
      height: 55,
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: present
                ? successGreen.withValues(
                    alpha: 0.12,
                  )
                : Colors.red.withValues(
                    alpha: 0.10,
                  ),
            borderRadius:
                BorderRadius.circular(7),
          ),
          child: Text(
            mark,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: present
                  ? successGreen
                  : Colors.red.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER CELL
  // ============================================================

  Widget _headerCell(
    String text, {
    required double width,
  }) {
    return Container(
      width: width,
      height: 60,
      alignment: Alignment.center,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      decoration: const BoxDecoration(
        color: primaryNavy,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Row(
            children: [
              _headerCell(
                'Sr No',
                width: 55,
              ),
              _headerCell(
                'Roll No',
                width: 75,
              ),
              _headerCell(
                'Student Name',
                width: 180,
              ),

              ...sessions.map(
                (session) {
                  final timestamp =
                      session['createdAt']
                          as Timestamp;

                  final date =
                      timestamp.toDate();

                  final formatted =
                      '${date.day.toString().padLeft(2, '0')}-'
                      '${date.month.toString().padLeft(2, '0')}';

                  return _headerCell(
                    formatted,
                    width: 55,
                  );
                },
              ),

              _headerCell(
                'Present',
                width: 75,
              ),

              _headerCell(
                'Absent',
                width: 75,
              ),

              _headerCell(
                'Attendance %',
                width: 100,
              ),

              _headerCell(
                'Status',
                width: 95,
              ),
            ],
          ),

          // ------------------------------------------------------
          // DATA
          // ------------------------------------------------------

          ...List.generate(
            students.length,
            (index) {
              return _buildStudentRow(
                index,
                students[index],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY BAR
  // ============================================================

  Widget _buildSummaryBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _summaryItem(
            'Students',
            '${students.length}',
            primaryBlue,
          ),
          _summaryItem(
            'Classes',
            '${sessions.length}',
            cyan,
          ),
          _summaryItem(
            'Threshold',
            '75%',
            warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 55,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadPreview,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Retry',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FA),

      appBar: AppBar(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Attendance Sheet Preview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                isLoading ? null : _loadPreview,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: primaryBlue,
              ),
            )
          : errorMessage != null
              ? _buildError()
              : Column(
                  children: [
                    // ------------------------------------------
                    // REPORT INFORMATION
                    // ------------------------------------------

                    Padding(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(
                              18,
                            ),
                            decoration:
                                BoxDecoration(
                              gradient:
                                  const LinearGradient(
                                colors: [
                                  darkNavy,
                                  primaryNavy,
                                  primaryBlue,
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Attendance Report',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  '${widget.branch} • '
                                  '${widget.year} Year • '
                                  '${widget.course} • '
                                  '${widget.month}',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _buildSummaryBar(),
                        ],
                      ),
                    ),

                    // ------------------------------------------
                    // TABLE
                    // ------------------------------------------

                    Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.05,
                              ),
                              blurRadius: 10,
                              offset:
                                  const Offset(
                                0,
                                3,
                              ),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          child: students.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No students found for the selected class.',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                                )
                              : _buildTable(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}