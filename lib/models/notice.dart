class Notice {
  final String? id;
  final String title;
  final String description;
  final List<String> recipients;
  final List<String> attachmentUrls;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  Notice({
    this.id,
    required this.title,
    required this.description,
    required this.recipients,
    required this.attachmentUrls,
    this.createdBy,
    this.createdAt,
    this.lastUpdated,
  });

  // Firestore → Notice
  factory Notice.fromMap(Map<String, dynamic> map, String docId) {
    return Notice(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      recipients: List<String>.from(map['recipients'] ?? []),
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      createdBy: map['createdBy'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as dynamic).toDate()
          : null,
    );
  }

  // Notice → Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'recipients': recipients,
      'attachmentUrls': attachmentUrls,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }
}
