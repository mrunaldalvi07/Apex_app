class AttendanceSummaryModel {
  final String studentId;

  final String rollNo;

  final String studentName;

  final int present;

  final int absent;

  final int totalClasses;

  final double attendancePercentage;

  final String status;

  AttendanceSummaryModel({
    required this.studentId,
    required this.rollNo,
    required this.studentName,
    required this.present,
    required this.absent,
    required this.totalClasses,
    required this.attendancePercentage,
    required this.status,
  });

  factory AttendanceSummaryModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AttendanceSummaryModel(
      studentId: map['studentId'] ?? '',
      rollNo: map['rollNo'] ?? '',
      studentName: map['studentName'] ?? '',
      present: map['present'] ?? 0,
      absent: map['absent'] ?? 0,
      totalClasses: map['totalClasses'] ?? 0,
      attendancePercentage:
          (map['attendancePercentage'] ?? 0)
              .toDouble(),
      status: map['status'] ?? 'Regular',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'rollNo': rollNo,
      'studentName': studentName,
      'present': present,
      'absent': absent,
      'totalClasses': totalClasses,
      'attendancePercentage':
          attendancePercentage,
      'status': status,
    };
  }

  bool get detained =>
      attendancePercentage < 75;
}