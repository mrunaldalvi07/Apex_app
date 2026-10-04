import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notice_details_screen.dart';
import '../models/notice.dart';
import '../services/notice_service.dart';
import 'dart:async';

class StudentNoticeScreen extends StatefulWidget {
  const StudentNoticeScreen({super.key});

  @override
  State<StudentNoticeScreen> createState() => _StudentNoticeScreenState();
}

class _StudentNoticeScreenState extends State<StudentNoticeScreen> {
  static const Color primaryBlue = Color(0xFF0C447B);
  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color headingColor = Color(0xFF0F2C59);
  static const Color mutedColor = Color(0xFF708090);
  static const Color borderColor = Color(0xFFE1E8F0);

  final TextEditingController _searchController = TextEditingController();

  String searchQuery = "";
  Timer? _debounce;

  bool showPinnedOnly = false;
  bool showStarredOnly = false;

  final Map<String, bool> starredStatus = {};

  TextSpan highlightText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(text: text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final start = lowerText.indexOf(lowerQuery);

    if (start == -1) {
      return TextSpan(text: text);
    }

    final end = start + query.length;

    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, start)),
        TextSpan(
          text: text.substring(start, end),
          style: const TextStyle(
            backgroundColor: Color(0xFFDCEBFA),
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: text.substring(end)),
      ],
    );
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "";

    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hr ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }

  Future<void> loadStarredStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final starredNotices = await NoticeService.getStarredNotices(user.uid);

    if (!mounted) return;

    setState(() {
      starredStatus.clear();

      for (final noticeId in starredNotices.keys) {
        starredStatus[noticeId] = true;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadStarredStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Notices',
          style: TextStyle(
            color: headingColor,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: headingColor,
        ),
        actions: [
          // Starred filter
          IconButton(
            icon: Icon(
              showStarredOnly ? Icons.star : Icons.star_border,
              color: showStarredOnly ? primaryBlue : headingColor,
            ),
            tooltip:
                showStarredOnly ? "Show All Notices" : "Show Starred Notices",
            onPressed: () {
              setState(() {
                showStarredOnly = !showStarredOnly;
              });
            },
          ),

          // Pinned filter
          IconButton(
            icon: Icon(
              showPinnedOnly ? Icons.push_pin : Icons.push_pin_outlined,
              color: showPinnedOnly ? primaryBlue : headingColor,
            ),
            tooltip:
                showPinnedOnly ? "Show All Notices" : "Show Pinned Notices",
            onPressed: () {
              setState(() {
                showPinnedOnly = !showPinnedOnly;
              });
            },
          ),

          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 0,
            ),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(
                  color: borderColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    hintText: "Search notices...",
                    hintStyle: TextStyle(
                      color: mutedColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: primaryBlue,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) {
                      _debounce!.cancel();
                    }

                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    });
                  },
                ),
              ),
            ),
          ),

          // Filter heading
          if (showPinnedOnly || showStarredOnly)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 10,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Color(0xFFD6E0EC),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      showPinnedOnly && showStarredOnly
                          ? "Starred & Pinned Notices"
                          : showPinnedOnly
                              ? "Pinned Notices"
                              : "Starred Notices",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: headingColor,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Color(0xFFD6E0EC),
                    ),
                  ),
                ],
              ),
            ),

          // Notices
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: NoticeService.getNotices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryBlue,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notices found",
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                final notices = snapshot.data!
                    .where(
                      (notice) =>
                          (!showPinnedOnly || notice.pinned) &&
                          (!showStarredOnly ||
                              starredStatus[notice.id] == true) &&
                          (notice.title.toLowerCase().contains(searchQuery) ||
                              notice.description.toLowerCase().contains(
                                    searchQuery,
                                  )),
                    )
                    .toList();

                if (notices.isEmpty) {
                  return const Center(
                    child: Text(
                      "No matching notices found",
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: borderColor,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NoticeDetailsScreen(notice: notice),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Creator + pinned + star + date
                              Row(
                                children: [
                                  if (notice.pinned) ...[
                                    const Icon(
                                      Icons.push_pin,
                                      size: 16,
                                      color: primaryBlue,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    "Notice by: "
                                    "${notice.createdBy ?? 'Unknown'}",
                                    style: const TextStyle(
                                      color: mutedColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (starredStatus[notice.id] == true) ...[
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Color(0xFFE5A900),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    formatDateTime(notice.createdAt),
                                    style: const TextStyle(
                                      color: mutedColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // Title + popup menu
                              Row(
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: headingColor,
                                        ),
                                        children: [
                                          highlightText(
                                            notice.title,
                                            searchQuery,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Student can only
                                  // Star / Unstar.
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: mutedColor,
                                    ),
                                    onSelected: (String value) async {
                                      if (value == "star") {
                                        final user =
                                            FirebaseAuth.instance.currentUser;

                                        if (user == null) {
                                          return;
                                        }

                                        try {
                                          await NoticeService.toggleStarNotice(
                                            notice.id!,
                                            user.uid,
                                          );

                                          if (!mounted) return;

                                          setState(() {
                                            starredStatus[notice.id!] =
                                                !(starredStatus[notice.id!] ??
                                                    false);
                                          });
                                        } catch (e) {
                                          if (!mounted) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Failed to update star: $e",
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<String>(
                                        value: "star",
                                        child: Row(
                                          children: [
                                            Icon(
                                              (starredStatus[notice.id] ??
                                                      false)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color:
                                                  (starredStatus[notice.id] ??
                                                          false)
                                                      ? const Color(0xFFE5A900)
                                                      : headingColor,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              (starredStatus[notice.id] ??
                                                      false)
                                                  ? "Unstar"
                                                  : "Star",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 2),

                              // Description
                              Text(
                                notice.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: mutedColor,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Attachments
                              if (notice.attachmentUrls
                                  .where((file) => file.trim().isNotEmpty)
                                  .isNotEmpty)
                                ...notice.attachmentUrls.map(
                                  (file) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.attach_file,
                                          size: 18,
                                          color: primaryBlue,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            file,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: headingColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
