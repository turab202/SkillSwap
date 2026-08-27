import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';

// ── Profile save state ─────────────────────────────────────────────────────
class ProfileSaveState {
  final bool loading;
  final String? error;
  const ProfileSaveState({this.loading = false, this.error});
}

class ProfileNotifier extends StateNotifier<ProfileSaveState> {
  final ProfileRepository _repo;
  final Ref _ref;
  ProfileNotifier(this._repo, this._ref) : super(const ProfileSaveState());

  Future<bool> saveProfile({
    required String name,
    required String location,
    required List<String> skillsOffered,
    required List<String> skillsWanted,
    required String experienceLevel,
    required String availability,
    required String bio,
    File? photo,
  }) async {
    state = const ProfileSaveState(loading: true);
    try {
      final uid = _ref.read(authRepositoryProvider).currentFirebaseUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      // Upload photo first if provided
      String? photoUrl;
      if (photo != null) photoUrl = await _repo.uploadPhoto(uid, photo);

      // Use current cached user if available, avoid extra Firestore read
      final existing = _ref.read(currentUserProvider).value;
      final updated = (existing ?? UserModel(uid: uid, email: '', displayName: name, createdAt: DateTime.now())).copyWith(
        displayName: name,
        location: location.isEmpty ? null : location,
        skillsOffered: skillsOffered,
        skillsWanted: skillsWanted,
        experienceLevel: experienceLevel,
        availability: availability,
        bio: bio,
        profileComplete: true,
        photoUrl: photoUrl ?? existing?.photoUrl,
      );
      await _repo.updateProfile(updated);
      state = const ProfileSaveState();
      return true;
    } catch (e) {
      state = ProfileSaveState(error: e.toString());
      return false;
    }
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileSaveState>(
  (ref) => ProfileNotifier(ref.watch(profileRepositoryProvider), ref),
);

// ── Viewed user profile (passed via argument) ─────────────────────────────
final viewedUserProvider = FutureProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(profileRepositoryProvider).getUser(uid);
});
