import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/notice.dart';

class NoticeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // RECIPIENT NORMALIZATION
  // ============================================================

  static List<String> _normalizeRecipients(List<String> recipients) {
    final Set<String> normalized = {};

    for (final recipient in recipients) {
      final value = recipient.trim().toLowerCase();

      if (value == 'faculty') {
        normalized.add('faculty');
      } else if (value == 'if' || value == 'it') {
        normalized.add('IT');
      } else if (value == 'cm') {
        normalized.add('CM');
      }
    }

    return normalized.toList();
  }

  // ============================================================
  // UPLOAD ATTACHMENTS
  // ============================================================

  static Future<List<String>> uploadNoticeAttachments(
    String noticeId,
    List<PlatformFile> files,
  ) async {
    final List<String> uploadedUrls = [];

    for (final file in files) {
      final bytes = file.bytes;

      if (bytes == null) {
        throw Exception(
          'Unable to read ${file.name}. Please select the file again.',
        );
      }

      final safeFileName =
          '${DateTime.now().microsecondsSinceEpoch}_${file.name}';

      final reference = _storage
          .ref()
          .child('notice_attachments')
          .child(noticeId)
          .child(safeFileName);

      final metadata = SettableMetadata(
        contentType: file.extension == null ? 'application/octet-stream' : null,
      );

      final uploadTask = await reference.putData(
        bytes,
        metadata,
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      uploadedUrls.add(downloadUrl);
    }

    return uploadedUrls;
  }

  // ============================================================
  // CREATE NOTICE
  // ============================================================

  static Future<String> createNotice(
    Notice notice,
    List<PlatformFile> files,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final normalizedRecipients = _normalizeRecipients(notice.recipients);

    final noticeReference = _firestore.collection('notices').doc();

    final attachmentUrls = <String>[
      ...notice.attachmentUrls,
    ];

    // Upload attachments, if any.
    if (files.isNotEmpty) {
      final uploadedUrls = await uploadNoticeAttachments(
        noticeReference.id,
        files,
      );

      attachmentUrls.addAll(uploadedUrls);
    }

    final noticeData = <String, dynamic>{
      'title': notice.title,
      'description': notice.description,
      'createdBy': notice.createdBy,
      'createdByUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'recipients': normalizedRecipients,
      'attachmentUrls': attachmentUrls,
      'pinned': notice.pinned,
    };

    await noticeReference.set(noticeData);

    // Notification errors should not undo a successfully
    // published notice.
    try {
      await _createNoticeNotifications(
        noticeReference.id,
        notice.title,
        normalizedRecipients,
        user.uid,
      );
    } catch (e) {
      debugPrint('Notice notification error: $e');
    }

    return noticeReference.id;
  }

  // ============================================================
  // CREATE NOTICE NOTIFICATIONS
  // ============================================================

  static Future<void> _createNoticeNotifications(
    String noticeId,
    String noticeTitle,
    List<String> recipients,
    String creatorUid,
  ) async {
    final usersSnapshot = await _firestore.collection('users').get();

    final Set<String> recipientUids = {};

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();

      final uid = (userData['uid'] ?? userDoc.id).toString();

      // The creator should not receive their own notification.
      if (uid == creatorUid) {
        continue;
      }

      final role = (userData['role'] ?? '').toString().trim().toLowerCase();

      final branch = (userData['branch'] ?? '').toString().trim().toUpperCase();

      bool shouldNotify = false;

      // Faculty notices go to all faculty members.
      if (recipients.contains('faculty') && role == 'faculty') {
        shouldNotify = true;
      }

      // IT notices go to IT students and the IT CR.
      if (recipients.contains('IT') &&
          branch == 'IT' &&
          (role == 'student' || role == 'cr')) {
        shouldNotify = true;
      }

      // CM notices go to CM students and the CM CR.
      if (recipients.contains('CM') &&
          branch == 'CM' &&
          (role == 'student' || role == 'cr')) {
        shouldNotify = true;
      }

      // Admin receives all notices.
      if (role == 'admin') {
        shouldNotify = true;
      }

      if (shouldNotify && uid.isNotEmpty) {
        recipientUids.add(uid);
      }
    }

    // Firestore batches support up to 500 writes.
    // Use 450 to leave a safety margin.
    final recipientList = recipientUids.toList();

    for (int i = 0; i < recipientList.length; i += 450) {
      final batch = _firestore.batch();

      final end =
          (i + 450 < recipientList.length) ? i + 450 : recipientList.length;

      for (final uid in recipientList.sublist(i, end)) {
        final notificationReference =
            _firestore.collection('notifications').doc();

        batch.set(notificationReference, {
          'studentId': uid,
          'facultyId': creatorUid,
          'title': 'New Notice',
          'message': 'A new notice has been published: $noticeTitle',
          'type': 'notice',
          'noticeId': noticeId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }
  }

  // ============================================================
  // GET NOTICES
  // ============================================================

  static Stream<List<Notice>> getNotices() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return <Notice>[];
      }

      final userData = userDoc.data() ?? {};

      final role = (userData['role'] ?? '').toString().trim().toLowerCase();

      final branch = (userData['branch'] ?? '').toString().trim().toUpperCase();

      if (!['admin', 'faculty', 'cr', 'student'].contains(role)) {
        return <Notice>[];
      }

      final List<Notice> visibleNotices = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final recipients = _normalizeRecipients(
          List<String>.from(data['recipients'] ?? []),
        );

        final createdByUid = (data['createdByUid'] ?? '').toString();

        bool isVisible = false;

        // Admin can see every notice.
        if (role == 'admin') {
          isVisible = true;
        }

        // Faculty can see faculty notices.
        if (role == 'faculty' && recipients.contains('faculty')) {
          isVisible = true;
        }

        // Students and CRs can see notices for their branch.
        if ((role == 'student' || role == 'cr') &&
            branch.isNotEmpty &&
            recipients.contains(branch)) {
          isVisible = true;
        }

        // Faculty and CRs can always see notices they created.
        if ((role == 'faculty' || role == 'cr') && createdByUid == user.uid) {
          isVisible = true;
        }

        if (isVisible) {
          visibleNotices.add(Notice.fromMap(
            data,
            doc.id,
          ));
        }
      }

      return visibleNotices;
    });
  }

  // ============================================================
  // GET STARRED NOTICES
  // ============================================================

  static Future<List<String>> getStarredNotices(
    String uid,
  ) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return [];
    }

    final data = userDoc.data() ?? {};

    final starredNotices = data['starredNotices'] as List<dynamic>? ?? [];

    return starredNotices.map((id) => id.toString()).toList();
  }

  static Future<bool> isNoticeStarred(
    String noticeId,
    String uid,
  ) async {
    final starredNotices = await getStarredNotices(uid);
    return starredNotices.contains(noticeId);
  }
  // ============================================================
  // STAR / UNSTAR NOTICE
  // ============================================================

  static Future<void> toggleStarNotice(
    String noticeId,
    String uid,
  ) async {
    final userReference = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userReference);

      if (!userSnapshot.exists) {
        throw Exception('User document not found.');
      }

      final data = userSnapshot.data() ?? {};

      final starredNotices = List<String>.from(
        data['starredNotices'] ?? [],
      );

      if (starredNotices.contains(noticeId)) {
        starredNotices.remove(noticeId);
      } else {
        starredNotices.add(noticeId);
      }

      transaction.set(
        userReference,
        {
          'starredNotices': starredNotices,
        },
        SetOptions(merge: true),
      );
    });
  }

  // ============================================================
  // UPDATE NOTICE
  // ============================================================

  static Future<void> updateNotice(
    String noticeId,
    Notice notice, [
    List<PlatformFile> files = const [],
  ]) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final noticeReference = _firestore.collection('notices').doc(noticeId);

    final existingDoc = await noticeReference.get();

    if (!existingDoc.exists) {
      throw Exception('Notice not found.');
    }

    final existingData = existingDoc.data() ?? {};

    final attachmentUrls = <String>[
      ...List<String>.from(
        existingData['attachmentUrls'] ?? [],
      ),
    ];

    if (files.isNotEmpty) {
      final uploadedUrls = await uploadNoticeAttachments(
        noticeId,
        files,
      );

      attachmentUrls.addAll(uploadedUrls);
    }

    await noticeReference.update({
      'title': notice.title,
      'description': notice.description,
      'recipients': _normalizeRecipients(notice.recipients),
      'attachmentUrls': attachmentUrls,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // PIN / UNPIN NOTICE
  // ============================================================

  static Future<void> togglePinNotice(
    String noticeId,
    bool pinned,
  ) async {
    await _firestore.collection('notices').doc(noticeId).update({
      'pinned': pinned,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELETE NOTICE
  // ============================================================

  static Future<void> deleteNotice(
    String noticeId,
  ) async {
    final noticeReference = _firestore.collection('notices').doc(noticeId);

    final noticeDoc = await noticeReference.get();

    if (!noticeDoc.exists) {
      return;
    }

    final data = noticeDoc.data() ?? {};

    // Delete the notice document.
    await noticeReference.delete();

    // Delete its attachment folder from Firebase Storage.
    try {
      final folderReference =
          _storage.ref().child('notice_attachments').child(noticeId);

      await folderReference.delete();
    } catch (e) {
      debugPrint('Attachment folder deletion error: $e');
    }

    // Remove this notice from users' starred lists.
    final usersSnapshot = await _firestore.collection('users').get();

    for (int i = 0; i < usersSnapshot.docs.length; i += 450) {
      final batch = _firestore.batch();

      final end = (i + 450 < usersSnapshot.docs.length)
          ? i + 450
          : usersSnapshot.docs.length;

      for (final userDoc in usersSnapshot.docs.sublist(i, end)) {
        final userData = userDoc.data();

        final starredNotices = List<String>.from(
          userData['starredNotices'] ?? [],
        );

        if (starredNotices.contains(noticeId)) {
          starredNotices.remove(noticeId);

          batch.set(
            userDoc.reference,
            {
              'starredNotices': starredNotices,
            },
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();
    }

    // Remove notifications associated with this notice.
    final notificationsSnapshot = await _firestore
        .collection('notifications')
        .where('noticeId', isEqualTo: noticeId)
        .get();

    for (int i = 0; i < notificationsSnapshot.docs.length; i += 450) {
      final batch = _firestore.batch();

      final end = (i + 450 < notificationsSnapshot.docs.length)
          ? i + 450
          : notificationsSnapshot.docs.length;

      for (final notification in notificationsSnapshot.docs.sublist(i, end)) {
        batch.delete(notification.reference);
      }

      await batch.commit();
    }
  }
}
