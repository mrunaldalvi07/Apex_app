import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';

class NoticeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> createNotice(Notice notice) async {
    await _db.collection("notices").add({
      ...notice.toMap(),
      "createdAt": FieldValue.serverTimestamp(),
      "lastUpdated": FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Notice>> getNotices() {
    return _db
        .collection("notices")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Notice.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  static Future<void> updateNotice(String noticeId, Notice notice) async {
    await _db.collection("notices").doc(noticeId).update({
      ...notice.toMap(),
      "lastUpdated": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteNotice(String noticeId) async {
    await _db.collection("notices").doc(noticeId).delete();
  }
}
