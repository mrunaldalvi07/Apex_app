import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/notice.dart';
import '../services/notice_service.dart';

class CreateNoticeScreen extends StatefulWidget {
  final Notice? notice;

  const CreateNoticeScreen({super.key, this.notice});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _noticeformkey = GlobalKey<FormState>();
  bool faculty = false;
  bool students = false;
  bool ifStudent = false;
  bool cmStudent = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<PlatformFile> selectedFiles = [];

  @override
  @override
  void initState() {
    super.initState();

    _titleController.text = widget.notice?.title ?? "";
    _descController.text = widget.notice?.description ?? "";

    if (widget.notice != null) {
      final r = widget.notice!.recipients;

      faculty = r.contains("Faculty");
      ifStudent = r.contains("IF");
      cmStudent = r.contains("CM");
      students = ifStudent || cmStudent;
    }
  }

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      print(result.files.length);
      setState(() {
        selectedFiles.addAll(result.files);
      });
    }

    if (widget.notice != null) {
      selectedFiles = widget.notice!.attachmentUrls
          .map((name) => PlatformFile(name: name, size: 0))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create Notice'),
      ),

      body: Container(
        color: Colors.grey.shade100,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _noticeformkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TITLE CARD
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Title",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  hintText: "Enter notice title",
                                  border: UnderlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Title is required";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // DESCRIPTION CARD
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _descController,
                                minLines: 1,
                                maxLines: 15,
                                decoration: const InputDecoration(
                                  hintText: "Enter notice description",
                                  border: UnderlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Description is required";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Recipients",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 12),

                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text("Faculty"),
                                value: faculty,
                                onChanged: (bool? value) {
                                  setState(() {
                                    faculty = value ?? false;
                                  });
                                },
                              ),

                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text("Students"),
                                value: students,
                                onChanged: (bool? value) {
                                  setState(() {
                                    students = value ?? false;
                                  });
                                },
                              ),

                              if (students)
                                Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        title: const Text("IF"),
                                        value: ifStudent,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            ifStudent = value ?? false;
                                          });
                                        },
                                      ),

                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        title: const Text("CM"),
                                        value: cmStudent,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            cmStudent = value ?? false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Attachments",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 16),

                              selectedFiles.isEmpty
                                  ? const Text(
                                      "No files selected",
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  : Column(
                                      children: selectedFiles.map((file) {
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.attach_file,
                                          ),

                                          title: Text(file.name),

                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.visibility,
                                                ),
                                                tooltip: "View File",
                                                onPressed: () async {
                                                  print(file.name);
                                                  print(file.path);
                                                },
                                              ),

                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                tooltip: "Remove File",
                                                onPressed: () {
                                                  setState(() {
                                                    selectedFiles.remove(file);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),

                              const SizedBox(height: 16),

                              OutlinedButton.icon(
                                onPressed: pickFiles,
                                icon: const Icon(Icons.attach_file),
                                label: const Text("Add Files"),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_noticeformkey.currentState!.validate()) {
                              List<String> recipients = [];

                              if (faculty) recipients.add("Faculty");
                              if (ifStudent) recipients.add("IF");
                              if (cmStudent) recipients.add("CM");

                              List<String> attachmentUrls = selectedFiles
                                  .map((file) => file.name)
                                  .toList();

                              final noticeData = Notice(
                                title: _titleController.text.trim(),
                                description: _descController.text.trim(),
                                recipients: recipients,
                                attachmentUrls: attachmentUrls,
                              );

                              if (widget.notice == null) {
                                // CREATE MODE
                                await NoticeService.createNotice(noticeData);
                              } else {
                                // EDIT MODE
                                await NoticeService.updateNotice(
                                  widget.notice!.id!,
                                  noticeData,
                                );
                              }
                              if (!mounted) return;
                              Navigator.pop(context);
                            }
                          },

                          child: Text(
                            widget.notice == null
                                ? "Send Notice"
                                : "Update Notice",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
