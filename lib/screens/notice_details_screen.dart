import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notice.dart';
import '../services/notice_service.dart';
import 'create_notice_screen.dart';

class NoticeDetailsScreen extends StatefulWidget {
  final Notice notice;

  // Current filter states from the previous Notice screen.
  final bool showStarredOnly;
  final bool showPinnedOnly;

  const NoticeDetailsScreen({
    super.key,
    required this.notice,
    this.showStarredOnly = false,
    this.showPinnedOnly = false,
  });

  @override
  State<NoticeDetailsScreen> createState() => _NoticeDetailsScreenState();
}

class _NoticeDetailsScreenState extends State<NoticeDetailsScreen> {
  static const Color primaryBlue = Color(0xFF0C447B);
  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color headingColor = Color(0xFF0F2C59);
  static const Color mutedColor = Color(0xFF708090);
  static const Color borderColor = Color(0xFFE1E8F0);

  // Very light blue popup background.
  static const Color popupBackground = Color(0xFFF4F8FD);

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
      await NoticeService.toggleStarNotice(
        notice.id!,
        user.uid,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isStarred = oldStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to update star"),
        ),
      );
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
      await NoticeService.togglePinNotice(
        notice.id!,
        newPinnedStatus,
      );

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to update pin"),
        ),
      );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Notice",
            style: TextStyle(
              color: headingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this notice?",
            style: TextStyle(
              color: mutedColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: primaryBlue,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to delete notice"),
        ),
      );
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
            Icon(
              isStarred ? Icons.star : Icons.star_border,
              color: isStarred ? primaryBlue : headingColor,
            ),
            const SizedBox(width: 10),
            Text(
              isStarred ? "Unstar" : "Star",
              style: const TextStyle(
                color: headingColor,
              ),
            ),
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
              Icon(
                notice.pinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: primaryBlue,
              ),
              const SizedBox(width: 10),
              Text(
                notice.pinned ? "Unpin" : "Pin",
                style: const TextStyle(
                  color: headingColor,
                ),
              ),
            ],
          ),
        ),
      );

      items.add(
        const PopupMenuItem<String>(
          value: "edit",
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: primaryBlue,
              ),
              SizedBox(width: 10),
              Text(
                "Edit",
                style: TextStyle(
                  color: headingColor,
                ),
              ),
            ],
          ),
        ),
      );

      items.add(
        const PopupMenuItem<String>(
          value: "delete",
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text(
                "Delete",
                style: TextStyle(
                  color: headingColor,
                ),
              ),
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
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            "Notices",
            style: TextStyle(
              color: headingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          iconTheme: const IconThemeData(
            color: headingColor,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: primaryBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Notices",
          style: TextStyle(
            color: headingColor,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(
          color: headingColor,
        ),
        actions: [
          // ======================================================
          // ⭐ STARRED NOTICES
          // ======================================================
          IconButton(
            icon: Icon(
              widget.showStarredOnly ? Icons.star : Icons.star_border,
              color: primaryBlue,
            ),
            tooltip: "Starred Notices",
            onPressed: () {
              Navigator.pop(context, "starred");
            },
          ),

          // ======================================================
          // 📌 PINNED NOTICES
          // ======================================================
          IconButton(
            icon: Icon(
              widget.showPinnedOnly ? Icons.push_pin : Icons.push_pin_outlined,
              color: primaryBlue,
            ),
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
              icon: const Icon(
                Icons.add,
                color: primaryBlue,
              ),
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
            icon: const Icon(
              Icons.more_vert,
              color: mutedColor,
            ),
            color: popupBackground,
            surfaceTintColor: popupBackground,
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
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: borderColor,
                ),
              ),
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
                              fontWeight: FontWeight.w700,
                              color: headingColor,
                            ),
                          ),
                        ),
                        if (notice.pinned) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.push_pin,
                            size: 18,
                            color: primaryBlue,
                          ),
                        ],
                        if (isStarred) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            size: 18,
                            color: primaryBlue,
                          ),
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
                              color: mutedColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          formatDateTime(notice.createdAt),
                          style: const TextStyle(
                            color: mutedColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Divider(
                      color: borderColor,
                      thickness: 1,
                    ),

                    const SizedBox(height: 10),

                    // ------------------------------------------------
                    // DESCRIPTION
                    // ------------------------------------------------
                    Text(
                      notice.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: headingColor,
                      ),
                    ),

                    // ------------------------------------------------
                    // ATTACHMENTS
                    // ------------------------------------------------
                    if (notice.attachmentUrls
                        .where(
                          (file) => file.trim().isNotEmpty,
                        )
                        .isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(
                        color: borderColor,
                        thickness: 1,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Attachments",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: headingColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...notice.attachmentUrls.map(
                        (file) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.attach_file,
                            color: primaryBlue,
                          ),
                          title: Text(
                            file,
                            style: const TextStyle(
                              color: headingColor,
                            ),
                          ),
                          onTap: () {
                            // Open attachment later.
                          },
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: mutedColor,
                            ),
                            color: popupBackground,
                            surfaceTintColor: popupBackground,
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: "open",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.open_in_new,
                                      color: primaryBlue,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Open",
                                      style: TextStyle(
                                        color: headingColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: "download",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.download_outlined,
                                      color: primaryBlue,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Download",
                                      style: TextStyle(
                                        color: headingColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: "share",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.share_outlined,
                                      color: primaryBlue,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Share",
                                      style: TextStyle(
                                        color: headingColor,
                                      ),
                                    ),
                                  ],
                                ),
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

            const SizedBox(height: 12),

            // ====================================================
            // NOTICE INFO CARD
            // ====================================================
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: borderColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primaryBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Notice Info",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: headingColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(
                      color: borderColor,
                      thickness: 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Created By: "
                      "${notice.createdBy ?? "Unknown"}",
                      style: const TextStyle(
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Created At: "
                      "${formatDateTime(notice.createdAt)}",
                      style: const TextStyle(
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Last Updated: "
                      "${formatDateTime(notice.lastUpdated)}",
                      style: const TextStyle(
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Status: "
                      "${notice.pinned ? "Pinned" : "Not Pinned"}"
                      "${isStarred ? " • Starred" : ""}",
                      style: const TextStyle(
                        color: headingColor,
                      ),
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
