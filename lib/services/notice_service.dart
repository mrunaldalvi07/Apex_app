import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';
import '../models/user.dart';

class NoticeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // CREATE NOTICE
  // ============================================================

  static Future<void> createNotice(Notice notice) async {
    await _db.collection("notices").add({
      ...notice.toMap(),
      "createdAt": FieldValue.serverTimestamp(),
      "lastUpdated": FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // GET NOTICES
  // ============================================================

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

  // ============================================================
  // GET STARRED NOTICES
  // ============================================================

  static Future<Map<String, dynamic>> getStarredNotices(String userId) async {
    final userDoc = await _db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      return {};
    }

    final data = userDoc.data();

    if (data == null || data["starredNotices"] == null) {
      return {};
    }

    return Map<String, dynamic>.from(data["starredNotices"]);
  }

  // ============================================================
  // CHECK WHETHER NOTICE IS STARRED
  // ============================================================

  static Future<bool> isNoticeStarred(String noticeId, String userId) async {
    final doc = await _db.collection("users").doc(userId).get();

    if (!doc.exists) {
      return false;
    }

    final data = doc.data();

    if (data == null || data["starredNotices"] == null) {
      return false;
    }

    final starredNotices = Map<String, dynamic>.from(data["starredNotices"]);

    return starredNotices.containsKey(noticeId);
  }

  // ============================================================
  // STAR / UNSTAR NOTICE
  // ============================================================

  static Future<void> toggleStarNotice(String noticeId, String userId) async {
    final userRef = _db.collection("users").doc(userId);

    final userDoc = await userRef.get();

    Map<String, dynamic> starredNotices = {};

    if (userDoc.exists) {
      final data = userDoc.data();

      if (data != null && data["starredNotices"] != null) {
        starredNotices = Map<String, dynamic>.from(data["starredNotices"]);
      }
    }

    if (starredNotices.containsKey(noticeId)) {
      // --------------------------------------------------------
      // UNSTAR
      // --------------------------------------------------------

      starredNotices.remove(noticeId);
    } else {
      // --------------------------------------------------------
      // STAR
      // --------------------------------------------------------

      starredNotices[noticeId] = FieldValue.serverTimestamp();
    }

    await userRef.update({"starredNotices": starredNotices});
  }

  // ============================================================
  // UPDATE NOTICE
  // ============================================================

  static Future<void> updateNotice(String noticeId, Notice notice) async {
    await _db.collection("notices").doc(noticeId).update({
      ...notice.toMap(),
      "lastUpdated": FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // PIN / UNPIN NOTICE
  // ============================================================

  static Future<void> togglePinNotice(String noticeId, bool pinned) async {
    await _db.collection("notices").doc(noticeId).update({
      "pinned": pinned,
      "lastUpdated": FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELETE NOTICE
  // ============================================================

  static Future<void> deleteNotice(String noticeId) async {
    await _db.collection("notices").doc(noticeId).delete();
  }
}
