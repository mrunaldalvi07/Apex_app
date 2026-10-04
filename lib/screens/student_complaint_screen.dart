import 'package:flutter/material.dart';

import 'complaint_form_screen.dart';
import 'complaint_list_screen.dart';
import '../theme/complaint_theme.dart';

class StudentComplaintScreen extends StatelessWidget {
  const StudentComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ComplaintPalette.theme(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ComplaintPalette.white,
          foregroundColor: ComplaintPalette.darkNavy,
          title: const Text("Complaint Management"),
        ),
        body: ColoredBox(
          color: ComplaintPalette.background,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      height: 64,
                      decoration: const BoxDecoration(
                        gradient: ComplaintPalette.attendanceActionGradient,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ComplaintFormScreen(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: Colors.white),
                              SizedBox(width: 14),
                              Text('Register Complaint',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                              Spacer(),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      height: 64,
                      decoration: const BoxDecoration(
                        gradient: ComplaintPalette.attendanceActionGradient,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ComplaintListScreen(
                                showOnlyMyComplaints: true,
                                isFaculty: false,
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(Icons.list_alt_outlined,
                                  color: Colors.white),
                              SizedBox(width: 14),
                              Text('View My Complaints',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                              Spacer(),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
