import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Safely convert Firestore timestamps or DateTime values.
  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // Safely convert Firestore list values into string lists.
  static List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .where((item) => item != null)
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  factory Notice.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return Notice(
      id: documentId,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      createdBy: map['createdBy']?.toString(),
      createdByUid: map['createdByUid']?.toString(),
      createdAt: _parseDateTime(map['createdAt']),
      lastUpdated: _parseDateTime(map['lastUpdated']),
      recipients: _parseStringList(map['recipients']),
      attachmentUrls: _parseStringList(map['attachmentUrls']),
      pinned: map['pinned'] == true,
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
