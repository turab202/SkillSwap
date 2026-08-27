import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../collaborations/repositories/collaboration_repository.dart';
import '../../collaborations/models/collaboration_model.dart';

final collaborationRepositoryProvider = Provider<CollaborationRepository>(
  (_) => CollaborationRepository(),
);

final dailyImpactProvider = FutureProvider<Map<String, int>>((ref) {
  ref.keepAlive();
  return FirestoreService.getDailyImpact();
});

final activeCollaborationsProvider = StreamProvider<List<CollaborationModel>>((ref) {
  ref.keepAlive();
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(collaborationRepositoryProvider).watchUserCollaborations(user.uid);
});

final helpRequestsProvider = StreamProvider<QuerySnapshot>((ref) {
  ref.keepAlive();
  return FirestoreService.posts
      .where('type', isEqualTo: 'request_help')
      .limit(5)
      .snapshots();
});

final communityPulseProvider = StreamProvider<QuerySnapshot>((ref) {
  ref.keepAlive();
  return FirestoreService.posts
      .limit(1)
      .snapshots();
});

final recommendedMatchesProvider = FutureProvider<List<UserModel>>((ref) async {
  ref.keepAlive();
  final viewer = ref.watch(currentUserProvider).value;
  final repo = ref.watch(profileRepositoryProvider);
  final users = await repo.getUsers(limit: 30);
  if (viewer == null) return users;
  final filtered = users.where((u) => u.uid != viewer.uid).toList();
  filtered.sort((a, b) => b.matchScore(viewer).compareTo(a.matchScore(viewer)));
  return filtered;
});

final newMembersTodayProvider = FutureProvider<int>((ref) async {
  ref.keepAlive();
  final snap = await FirestoreService.users.count().get();
  return snap.count ?? 0;
});

final latestCompletedCollabProvider = FutureProvider<String>((ref) async {
  ref.keepAlive();
  try {
    final snap = await FirestoreService.collaborations
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return '';
    final d = snap.docs.first.data() as Map<String, dynamic>;
    return d['requesterName'] as String? ?? '';
  } catch (_) {
    return '';
  }
});
