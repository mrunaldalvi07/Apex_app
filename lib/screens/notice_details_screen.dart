import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/notice_service.dart';
import 'create_notice_screen.dart';

class NoticeDetailsScreen extends StatelessWidget {
  final Notice notice;

  const NoticeDetailsScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateNoticeScreen()),
              );
            },
          ),

          PopupMenuButton(
            onSelected: (value) async {
              if (value == "delete") {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Delete Notice"),
                      content: const Text(
                        "Are you sure you want to delete this notice?",
                      ),
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

                if (confirm == true) {
                  await NoticeService.deleteNotice(notice.id!);
                }
              } else if (value == "edit") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateNoticeScreen(notice: notice),
                  ),
                );
              }
            },

            itemBuilder: (context) => const [
              PopupMenuItem(value: "pin", child: Text("Pin")),
              PopupMenuItem(value: "edit", child: Text("Edit")),
              PopupMenuItem(value: "delete", child: Text("Delete")),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // NOTICE CONTENT CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Divider(thickness: 0),

                    const SizedBox(height: 10),
                    Text(
                      notice.description,
                      style: const TextStyle(fontSize: 16),
                    ),

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
                            // Open attachment later
                          },

                          trailing: PopupMenuButton(
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: "open", child: Text("Open")),
                              PopupMenuItem(
                                value: "download",
                                child: Text("Download"),
                              ),
                              PopupMenuItem(
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

            // NOTICE INFO CARD
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

                    const Text("Created By: Faculty"),

                    SizedBox(height: 10),

                    const Text("Created At: Not Available"),

                    SizedBox(height: 10),

                    const Text("Last Updated: Not Available"),
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
