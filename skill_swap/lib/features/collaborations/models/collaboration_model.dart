import 'package:cloud_firestore/cloud_firestore.dart';

enum CollaborationStatus { pending, accepted, inProgress, completed, cancelled }

extension CollaborationStatusX on CollaborationStatus {
  String get value => name;
  static CollaborationStatus from(String v) =>
      CollaborationStatus.values.firstWhere((e) => e.name == v, orElse: () => CollaborationStatus.pending);
}

class CollaborationModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterPhoto;
  final String targetId;
  final String targetName;
  final String? targetPhoto;
  final String skillOffered;
  final String skillWanted;
  final CollaborationStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;

  const CollaborationModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhoto,
    required this.targetId,
    required this.targetName,
    this.targetPhoto,
    required this.skillOffered,
    required this.skillWanted,
    required this.status,
    this.message,
    required this.createdAt,
    this.scheduledAt,
    this.completedAt,
  });

  factory CollaborationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CollaborationModel(
      id: doc.id,
      requesterId: d['requesterId'] ?? '',
      requesterName: d['requesterName'] ?? '',
      requesterPhoto: d['requesterPhoto'],
      targetId: d['targetId'] ?? '',
      targetName: d['targetName'] ?? '',
      targetPhoto: d['targetPhoto'],
      skillOffered: d['skillOffered'] ?? '',
      skillWanted: d['skillWanted'] ?? '',
      status: CollaborationStatusX.from(d['status'] ?? 'pending'),
      message: d['message'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'requesterId': requesterId,
        'requesterName': requesterName,
        'requesterPhoto': requesterPhoto,
        'targetId': targetId,
        'targetName': targetName,
        'targetPhoto': targetPhoto,
        'skillOffered': skillOffered,
        'skillWanted': skillWanted,
        'status': status.value,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
        if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      };

  String otherPersonName(String currentUserId) => currentUserId == requesterId ? targetName : requesterName;
}
