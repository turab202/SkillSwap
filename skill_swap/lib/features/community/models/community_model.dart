import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  final String? imageUrl;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
    this.imageUrl,
  });

  int get memberCount => memberIds.length;
  bool isMember(String uid) => memberIds.contains(uid);

  factory CommunityModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommunityModel(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? '',
      memberIds: List<String>.from(d['memberIds'] ?? []),
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: d['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'memberIds': memberIds,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'imageUrl': imageUrl,
      };
}
