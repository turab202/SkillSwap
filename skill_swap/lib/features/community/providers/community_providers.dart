import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_model.dart';
import '../models/event_model.dart';
import '../models/resource_model.dart';
import '../repositories/community_repository.dart';
import '../../auth/providers/auth_providers.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (_) => CommunityRepository(),
);

final allCommunitiesProvider = StreamProvider<List<CommunityModel>>(
  (ref) => ref.watch(communityRepositoryProvider).watchCommunities(),
);

final userCommunitiesProvider = StreamProvider<List<CommunityModel>>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value([]);
  return ref
      .watch(communityRepositoryProvider)
      .watchUserCommunities(authUser.uid);
});

final upcomingEventsProvider = StreamProvider<List<EventModel>>(
  (ref) => ref.watch(communityRepositoryProvider).watchUpcomingEvents(),
);

final resourceCategoryProvider = StateProvider<String>((_) => 'All');

final resourcesProvider = StreamProvider<List<ResourceModel>>((ref) {
  final category = ref.watch(resourceCategoryProvider);
  return ref
      .watch(communityRepositoryProvider)
      .watchResources(category: category);
});
