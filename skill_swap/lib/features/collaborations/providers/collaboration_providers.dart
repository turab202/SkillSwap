import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collaboration_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../home/providers/home_providers.dart';

export '../../home/providers/home_providers.dart' show collaborationRepositoryProvider;

final userCollaborationsProvider = StreamProvider<List<CollaborationModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(collaborationRepositoryProvider).watchUserCollaborations(user.uid);
});
