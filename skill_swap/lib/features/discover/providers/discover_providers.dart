import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';

final discoverSearchQueryProvider = StateProvider<String>((_) => '');
final discoverSkillFilterProvider = StateProvider<String>((_) => 'All');

final discoverPeopleProvider = FutureProvider<List<UserModel>>((ref) {
  final query = ref.watch(discoverSearchQueryProvider);
  final skill = ref.watch(discoverSkillFilterProvider);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUsers(
    skillFilter: skill == 'All' ? null : skill,
    nameQuery: query.isEmpty ? null : query,
  );
});

/// Sorted by match score against the current viewer.
final aiMatchesProvider = FutureProvider<List<UserModel>>((ref) async {
  final viewer = ref.watch(currentUserProvider).value;
  final repo = ref.watch(profileRepositoryProvider);
  final users = await repo.getUsers();
  if (viewer == null) return users;
  final filtered = users.where((u) => u.uid != viewer.uid).toList();
  filtered.sort((a, b) => b.matchScore(viewer).compareTo(a.matchScore(viewer)));
  return filtered;
});
