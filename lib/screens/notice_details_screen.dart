import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notice.dart';
import '../services/notice_service.dart';
import 'create_notice_screen.dart';

class NoticeDetailsScreen extends StatefulWidget {
  final Notice notice;

  const NoticeDetailsScreen({super.key, required this.notice});

  @override
  State<NoticeDetailsScreen> createState() => _NoticeDetailsScreenState();
}

class _NoticeDetailsScreenState extends State<NoticeDetailsScreen> {
  late Notice notice;

  String? currentUserRole;

  bool isStarred = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    notice = widget.notice;

    loadUserData();
  }

  // ============================================================
  // LOAD USER ROLE
  // ============================================================

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        currentUserRole = data?["role"];
      }

      await loadStarredStatus();
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // LOAD STARRED STATUS
  // ============================================================

  Future<void> loadStarredStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || notice.id == null) {
      return;
    }

    final result = await NoticeService.isNoticeStarred(notice.id!, user.uid);

    isStarred = result;
  }

  // ============================================================
  // ROLE CHECKS
  // ============================================================

  bool get isAdmin {
    return currentUserRole?.toLowerCase() == "admin";
  }

  bool get isFaculty {
    return currentUserRole?.toLowerCase() == "faculty";
  }

  bool get isCR {
    return currentUserRole?.toLowerCase() == "cr";
  }

  // ============================================================
  // NOTICE MAKER CHECK
  // ============================================================

  bool get isNoticeMaker {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    if (notice.createdByUid == null) {
      return false;
    }

    return user.uid == notice.createdByUid;
  }

  // ============================================================
  // CREATE PERMISSION
  // ============================================================

  bool get canCreate {
    return isAdmin || isFaculty || isCR;
  }

  // ============================================================
  // MANAGE PERMISSION
  // ============================================================

  bool get canManageNotice {
    // Admin can manage every notice.
    if (isAdmin) {
      return true;
    }

    // Faculty and CR can manage only their own notices.
    if ((isFaculty || isCR) && isNoticeMaker) {
      return true;
    }

    return false;
  }

  // ============================================================
  // STAR / UNSTAR
  // ============================================================

  Future<void> toggleStar() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || notice.id == null) {
      return;
    }

    final oldStatus = isStarred;

    setState(() {
      isStarred = !oldStatus;
    });

    try {
      await NoticeService.toggleStarNotice(notice.id!, user.uid);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isStarred = oldStatus;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to update star")));
    }
  }

  // ============================================================
  // PIN / UNPIN
  // ============================================================

  Future<void> togglePin() async {
    if (notice.id == null) {
      return;
    }

    final newPinnedStatus = !notice.pinned;

    try {
      await NoticeService.togglePinNotice(notice.id!, newPinnedStatus);

      if (!mounted) return;

      setState(() {
        notice = Notice(
          id: notice.id,
          title: notice.title,
          description: notice.description,
          createdBy: notice.createdBy,
          createdByUid: notice.createdByUid,
          createdAt: notice.createdAt,
          lastUpdated: notice.lastUpdated,
          recipients: notice.recipients,
          attachmentUrls: notice.attachmentUrls,
          pinned: newPinnedStatus,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to update pin")));
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteNotice() async {
    if (notice.id == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Notice"),
          content: const Text("Are you sure you want to delete this notice?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await NoticeService.deleteNotice(notice.id!);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to delete notice")));
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> editNotice() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNoticeScreen(notice: notice),
      ),
    );
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return "Not Available";
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "$hour:$minute";
  }

  // ============================================================
  // APP BAR MENU
  // ============================================================

  List<PopupMenuEntry<String>> buildPopupMenu() {
    final items = <PopupMenuEntry<String>>[];

    // EVERYONE CAN STAR
    items.add(
      PopupMenuItem<String>(
        value: "star",
        child: Row(
          children: [
            Icon(isStarred ? Icons.star : Icons.star_border),
            const SizedBox(width: 10),
            Text(isStarred ? "Unstar" : "Star"),
          ],
        ),
      ),
    );

    // ADMIN OR NOTICE MAKER
    if (canManageNotice) {
      items.add(
        PopupMenuItem<String>(
          value: "pin",
          child: Row(
            children: [
              Icon(notice.pinned ? Icons.push_pin_outlined : Icons.push_pin),
              const SizedBox(width: 10),
              Text(notice.pinned ? "Unpin" : "Pin"),
            ],
          ),
        ),
      );

      items.add(
        const PopupMenuItem<String>(
          value: "edit",
          child: Row(
            children: [Icon(Icons.edit), SizedBox(width: 10), Text("Edit")],
          ),
        ),
      );

      items.add(
        const PopupMenuItem<String>(
          value: "delete",
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 10),
              Text("Delete"),
            ],
          ),
        ),
      );
    }

    return items;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Notices"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notices"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        actions: [
          // ======================================================
          // ⭐ STARRED NOTICES
          // ======================================================
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: "Starred Notices",
            onPressed: () {
              Navigator.pop(context, "starred");
            },
          ),

          // ======================================================
          // 📌 PINNED NOTICES
          // ======================================================
          IconButton(
            icon: const Icon(Icons.push_pin),
            tooltip: "Pinned Notices",
            onPressed: () {
              Navigator.pop(context, "pinned");
            },
          ),

          // ======================================================
          // ➕ CREATE NOTICE
          // ======================================================
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Create Notice",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateNoticeScreen(),
                  ),
                );
              },
            ),

          // ======================================================
          // ⋮ CURRENT NOTICE ACTIONS
          // ======================================================
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "star") {
                await toggleStar();
              } else if (value == "pin") {
                await togglePin();
              } else if (value == "edit") {
                await editNotice();
              } else if (value == "delete") {
                await deleteNotice();
              }
            },
            itemBuilder: (context) {
              return buildPopupMenu();
            },
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ====================================================
            // NOTICE CONTENT CARD
            // ====================================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // PINNED / STARRED INDICATION
                    // ------------------------------------------------
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        if (notice.pinned) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.push_pin, size: 18),
                        ],

                        if (isStarred) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star, size: 18),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ------------------------------------------------
                    // CREATOR + TIME
                    // ------------------------------------------------
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Notice by: "
                            "${notice.createdBy ?? "Unknown"}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        Text(
                          formatDateTime(notice.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Divider(thickness: 0),

                    const SizedBox(height: 10),

                    // ------------------------------------------------
                    // DESCRIPTION
                    // ------------------------------------------------
                    Text(
                      notice.description,
                      style: const TextStyle(fontSize: 16),
                    ),

                    // ------------------------------------------------
                    // ATTACHMENTS
                    // ------------------------------------------------
                    if (notice.attachmentUrls
                        .where((file) => file.trim().isNotEmpty)
                        .isNotEmpty) ...[
                      const SizedBox(height: 10),

                      const Divider(thickness: 0),

                      const SizedBox(height: 10),

                      const Text(
                        "Attachments",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      ...notice.attachmentUrls.map(
                        (file) => ListTile(
                          contentPadding: EdgeInsets.zero,

                          leading: const Icon(Icons.attach_file),

                          title: Text(file),

                          onTap: () {
                            // Open attachment later.
                          },

                          trailing: PopupMenuButton<String>(
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: "open",
                                child: Text("Open"),
                              ),
                              PopupMenuItem<String>(
                                value: "download",
                                child: Text("Download"),
                              ),
                              PopupMenuItem<String>(
                                value: "share",
                                child: Text("Share"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 5),

            // ====================================================
            // NOTICE INFO CARD
            // ====================================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text(
                          "Notice Info",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    const Divider(thickness: 0),

                    const SizedBox(height: 5),

                    Text(
                      "Created By: "
                      "${notice.createdBy ?? "Unknown"}",
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Created At: "
                      "${formatDateTime(notice.createdAt)}",
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Last Updated: "
                      "${formatDateTime(notice.lastUpdated)}",
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Status: "
                      "${notice.pinned ? "Pinned" : "Not Pinned"}"
                      "${isStarred ? " • Starred" : ""}",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
