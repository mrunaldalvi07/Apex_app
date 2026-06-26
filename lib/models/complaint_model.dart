import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String complaintId;
  final String title;
  final String description;
  final String category;
  final String complaintType;
  final String status;
  final DateTime createdAt;
  final String userId;
  final String facultyRemark;

  Complaint({
    required this.complaintId,
    required this.title,
    required this.description,
    required this.category,
    required this.complaintType,
    required this.status,
    required this.createdAt,
    required this.userId,
    required this.facultyRemark,
  });

  factory Complaint.fromMap(Map<String, dynamic> map) {
  return Complaint(
    complaintId: map['complaintId'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    category: map['category'] ?? '',
    complaintType: map['complaintType'] ?? '',
    status: map['status'] ?? '',
    createdAt: map['createdAt'] is Timestamp
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.parse(map['createdAt'].toString()),
    userId: map['userId'] ?? '',
    facultyRemark: map['facultyRemark'] ?? '',
  );
}

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'title': title,
      'description': description,
      'category': category,
      'complaintType': complaintType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'facultyRemark': facultyRemark,
    };
  }
}