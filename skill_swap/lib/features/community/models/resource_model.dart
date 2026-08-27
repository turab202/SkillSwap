import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String url;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final List<String> savedByIds;

  const ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.url,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.savedByIds,
  });

  bool isSaved(String uid) => savedByIds.contains(uid);

  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ResourceModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? '',
      url: d['url'] ?? '',
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      savedByIds: List<String>.from(d['savedByIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'url': url,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
        'savedByIds': savedByIds,
      };
}
