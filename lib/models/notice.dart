class Notice {
  String? id;
  String title;
  String description;
  String? createdBy;
  String? createdByUid;
  DateTime? createdAt;
  DateTime? lastUpdated;
  List<String> recipients;
  List<String> attachmentUrls;
  bool pinned;

  Notice({
    this.id,
    required this.title,
    required this.description,
    this.createdBy,
    this.createdByUid,
    this.createdAt,
    this.lastUpdated,
    required this.recipients,
    required this.attachmentUrls,
    this.pinned = false,
  });

  factory Notice.fromMap(Map<String, dynamic> map, String documentId) {
    return Notice(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'],
      createdByUid: map['createdByUid'],
      createdAt: map['createdAt']?.toDate(),
      lastUpdated: map['lastUpdated']?.toDate(),
      recipients: List<String>.from(map['recipients'] ?? []),
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      pinned: map['pinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdByUid': createdByUid,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
      'recipients': recipients,
      'attachmentUrls': attachmentUrls,
      'pinned': pinned,
    };
  }
}
