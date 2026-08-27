import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collaboration_model.dart';
import '../../../core/services/firestore_service.dart';

class CollaborationRepository {
  Stream<List<CollaborationModel>> watchUserCollaborations(String userId) {
    return FirestoreService.collaborations
        .where(Filter.or(
          Filter('requesterId', isEqualTo: userId),
          Filter('targetId', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CollaborationModel.fromFirestore).toList());
  }

  Future<void> createCollaboration(CollaborationModel c) =>
      FirestoreService.collaborations.doc(c.id.isEmpty ? null : c.id).set(c.toMap());

  Future<void> updateStatus(String id, CollaborationStatus status, {DateTime? scheduledAt}) =>
      FirestoreService.collaborations.doc(id).update({
        'status': status.value,
        if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt),
        if (status == CollaborationStatus.completed) 'completedAt': FieldValue.serverTimestamp(),
      });

  Future<List<CollaborationModel>> getByStatus(String userId, CollaborationStatus status) async {
    final snap = await FirestoreService.collaborations
        .where(Filter.or(
          Filter('requesterId', isEqualTo: userId),
          Filter('targetId', isEqualTo: userId),
        ))
        .where('status', isEqualTo: status.value)
        .get();
    return snap.docs.map(CollaborationModel.fromFirestore).toList();
  }
}
