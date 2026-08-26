import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String branch;
  final String year;
  final String rollNo;
  final DateTime? createdAt;
  final Map<String, dynamic> starredNotices;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.branch,
    required this.year,
    required this.rollNo,
    this.createdAt,
    this.starredNotices = const {},
  });

  // Firestore → User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      branch: map['branch'] ?? '',
      year: map['year'] ?? '',
      rollNo: map['rollNo'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      starredNotices: Map<String, dynamic>.from(map['starredNotices'] ?? {}),
    );
  }

  // User → Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'branch': branch,
      'year': year,
      'rollNo': rollNo,
      'createdAt': createdAt,
      'starredNotices': starredNotices,
    };
  }
}
