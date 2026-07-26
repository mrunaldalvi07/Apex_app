import 'package:flutter/material.dart';

import '../models/attendance_summary_model.dart';
import '../services/notification_service.dart';

class AttendanceSummaryService {
  Future<List<AttendanceSummaryModel>> getAttendanceSummary({
    required String branch,
    required String year,
    required String course,
    required String month,
  }) async {
    return [];
  }
}

class DetentionListScreen extends StatefulWidget {
  final String branch;
  final String year;
  final String course;
  final String month;

  const DetentionListScreen({
    super.key,
    required this.branch,
    required this.year,
    required this.course,
    required this.month,
  });

  @override
  State<DetentionListScreen> createState() =>
      _DetentionListScreenState();
}

class _DetentionListScreenState
    extends State<DetentionListScreen> {
  bool loading = true;

  List<AttendanceSummaryModel> allStudents = [];

  List<AttendanceSummaryModel> detainedStudents = [];

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDetentionList();
  }

  Future<void> loadDetentionList() async {
    setState(() {
      loading = true;
    });

    final data =  await AttendanceSummaryService().getAttendanceSummary(
      branch: widget.branch,
      year: widget.year,
      course: widget.course,
      month: widget.month,
    );

    allStudents = data;

    detainedStudents = data
        .where(
          (student) =>
              student.attendancePercentage < 75,
        )
        .toList();

    setState(() {
      loading = false;
    });
  }

  void searchStudent(String value) {
    final query = value.toLowerCase();

    setState(() {
      detainedStudents = allStudents.where((student) {
        return student.attendancePercentage < 75 &&
            (student.studentName
                    .toLowerCase()
                    .contains(query) ||
                student.rollNo
                    .toLowerCase()
                    .contains(query));
      }).toList();
    });
  }

  Future<void> notifyAllStudents() async {
    for (final student in detainedStudents) {
      await NotificationService().sendAttendanceWarning(
        studentId: student.studentId,
        course: widget.course,
        percentage: student.attendancePercentage,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Notification sent to all detained students",
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detention List"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search by Roll No or Name",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: searchStudent,
                  ),

                  const SizedBox(height: 15),

                  // Total Detained Card
                  Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.warning,
                          color: Colors.white,
                        ),
                      ),
                      title: const Text(
                        "Detained Students",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${detainedStudents.length} Students",
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Notify All Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.notifications_active,
                      ),
                      label: const Text(
                        "Notify All Detained Students",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: notifyAllStudents,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: detainedStudents.isEmpty
                        ? const Center(
                            child: Text(
                              "No Detained Students",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount:
                                detainedStudents.length,
                            itemBuilder: (context, index) {
                              final student =
                                  detainedStudents[index];

                              return Card(
                                margin:
                                    const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.red,
                                    child: Text(
                                      "${index + 1}",
                                      style:
                                          const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  title: Text(
                                    student.studentName,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [

                                      Text(
                                        "Roll No : ${student.rollNo}",
                                      ),

                                      Text(
                                        "Attendance : ${student.attendancePercentage.toStringAsFixed(2)} %",
                                      ),

                                      const SizedBox(
                                          height: 5),

                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .red
                                              .shade100,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          "DETAINED",
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.red,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons
                                          .notifications_active,
                                      color: Colors.blue,
                                    ),
                                    tooltip:
                                        "Notify Student",
                                    onPressed: () async {

                                      await NotificationService()
                                          .sendAttendanceWarning(
                                        studentId: student
                                            .studentId,
                                        course: widget.course,
                                        percentage: student
                                            .attendancePercentage,
                                      );

                                      if (!mounted)
                                        return;

                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Notification sent to ${student.studentName}",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
