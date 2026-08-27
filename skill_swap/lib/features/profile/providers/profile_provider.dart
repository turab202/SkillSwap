import 'dart:io';
import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final _repo = ProfileRepository();
  final AuthProvider _auth;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get user => _auth.user;

  ProfileProvider(this._auth);

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
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      String? photoUrl = user?.photoUrl;
      if (photo != null) {
        photoUrl = await _repo.uploadPhoto(user!.uid, photo);
      }
      final updated = user!.copyWith(
        displayName: name,
        location: location,
        skillsOffered: skillsOffered,
        skillsWanted: skillsWanted,
        experienceLevel: experienceLevel,
        availability: availability,
        bio: bio,
        photoUrl: photoUrl,
        profileComplete: true,
      );
      await _repo.updateProfile(updated);
      _auth.updateUser(updated);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
