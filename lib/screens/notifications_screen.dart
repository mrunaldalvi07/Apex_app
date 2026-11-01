import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/notice.dart';
import 'notice_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notice module's standard colour palette
  static const Color primaryBlue = Color(0xFF0C447B);
  static const Color headingColor = Color(0xFF0F2C59);
  static const Color mutedColor = Color(0xFF708090);
  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color borderColor = Color(0xFFE1E8F0);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // ------------------------------------------------------------
  // MARK NOTIFICATION AS READ
  // ------------------------------------------------------------

  Future<void> _markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  // ------------------------------------------------------------
  // OPEN NOTICE NOTIFICATION
  // ------------------------------------------------------------

  Future<void> _openNotification(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _markAsRead(notificationId);

      if (!mounted) return;

      final noticeId = data['noticeId']?.toString();

      if (noticeId == null || noticeId.isEmpty) {
        _showMessage('Notice details are unavailable.');
        return;
      }

      final noticeDoc = await _db.collection('notices').doc(noticeId).get();

      if (!mounted) return;

      if (!noticeDoc.exists || noticeDoc.data() == null) {
        _showMessage('This notice may have been deleted.');
        return;
      }

      final notice = Notice.fromMap(
        noticeDoc.data()!,
        noticeDoc.id,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoticeDetailsScreen(notice: notice),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not open notification: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ------------------------------------------------------------
  // TIME FORMAT
  // ------------------------------------------------------------

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return 'Just now';

    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Just now';

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ------------------------------------------------------------
  // NOTIFICATION CARD
  // ------------------------------------------------------------

  Widget _buildNotificationCard(
    String notificationId,
    Map<String, dynamic> data,
  ) {
    return InkWell(
      onTap: () => _openNotification(notificationId, data),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: primaryBlue,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title']?.toString() ?? 'New Notice',
                          style: const TextStyle(
                            color: headingColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['message']?.toString() ?? '',
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _formatDate(data['createdAt']),
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view notifications.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: headingColor,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('notifications')
            .where('studentId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load notifications.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          // Only unread NOTICE notifications are displayed.
          // Attendance notifications are deliberately excluded.
          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data();

            return data['type']?.toString() == 'notice' && data['read'] != true;
          }).toList();

          docs.sort((a, b) {
            final aTime = a.data()['createdAt'];
            final bTime = b.data()['createdAt'];

            final aDate = aTime is Timestamp
                ? aTime.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);

            final bDate = bTime is Timestamp
                ? bTime.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);

            return bDate.compareTo(aDate);
          });

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 65,
                      color: mutedColor.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No new notifications',
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'You are all caught up!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              return _buildNotificationCard(
                doc.id,
                doc.data(),
              );
            },
          );
        },
      ),
    );
  }
}
