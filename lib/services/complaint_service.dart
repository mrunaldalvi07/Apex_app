import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String createComplaintId() => _firestore.collection('complaints').doc().id;

  Future<void> _requireStaffRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in before managing complaints.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final role = userDoc.data()?['role'];
    if (role != 'faculty' && role != 'admin') {
      throw StateError('Only faculty or administrators can manage complaints.');
    }
  }

  Future<void> addComplaint(Complaint complaint) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in before submitting a complaint.');
    }

    await _firestore.collection('complaints').doc(complaint.complaintId).set({
      'complaintId': complaint.complaintId,
      'title': complaint.title,
      'description': complaint.description,
      'category': complaint.category,
      'complaintType': complaint.complaintType,
      'status': complaint.status,
      'createdAt': complaint.createdAt.toIso8601String(),
      'userId': user.uid,
      'facultyRemark': complaint.facultyRemark,
    });
  }

  Future<List<Complaint>> getComplaints() async {
    final snapshot = await _firestore.collection('complaints').get();

    return snapshot.docs.map((doc) {
      return Complaint.fromMap(doc.data());
    }).toList();
  }

  Future<List<Complaint>> getMyComplaints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in to view your complaints.');
    }

    final snapshot = await _firestore
        .collection('complaints')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) {
      return Complaint.fromMap(doc.data());
    }).toList();
  }

  Future<void> updateComplaint({
    required String complaintId,
    required String status,
    required String facultyRemark,
  }) async {
    await _requireStaffRole();
    await _firestore.collection('complaints').doc(complaintId).update({
      'status': status,
      'facultyRemark': facultyRemark,
    });
  }

  Future<void> deleteComplaint(
    String complaintId,
  ) async {
    await _requireStaffRole();
    await _firestore.collection('complaints').doc(complaintId).delete();
  }

  Stream<List<Complaint>> getComplaintsStream() {
    return _firestore.collection('complaints').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Complaint.fromMap(doc.data());
      }).toList();
    });
  }

  Stream<List<Complaint>> getMyComplaintsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<Complaint>>.error(
        StateError('Please sign in to view your complaints.'),
      );
    }

    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Complaint.fromMap(doc.data());
      }).toList();
    });
  }
}
