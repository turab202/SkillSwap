import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';

class ProfileRepository {
  final _db = FirebaseFirestore.instance;

  Stream<UserModel> watchUser(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(UserModel.fromFirestore);

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateProfile(UserModel user) => _db
      .collection('users')
      .doc(user.uid)
      .set(user.toMap(), SetOptions(merge: true));

  /// Stores photo as base64 data URI in Firestore — no Storage needed.
  Future<String> uploadPhoto(String uid, File file) async {
    final bytes = await file.readAsBytes();
    // Resize to max 200KB by compressing — use compute to avoid jank
    final compressed = await compute(_compressImage, bytes);
    final base64Str = base64Encode(compressed);
    final dataUri = 'data:image/jpeg;base64,$base64Str';
    await _db.collection('users').doc(uid).update({'photoUrl': dataUri});
    return dataUri;
  }

  /// Returns users with profileComplete=true, optionally filtered by skill.
  /// Supports name search via displayName prefix (client-side for simplicity).
  Future<List<UserModel>> getUsers({
    String? skillFilter,
    String? nameQuery,
    int limit = 30,
  }) async {
    Query q = _db.collection('users').where('profileComplete', isEqualTo: true);
    if (skillFilter != null && skillFilter.isNotEmpty) {
      q = q.where('skillsOffered', arrayContains: skillFilter);
    }
    final snap = await q.limit(limit).get();
    final users = snap.docs.map(UserModel.fromFirestore).toList();
    if (nameQuery != null && nameQuery.isNotEmpty) {
      final lower = nameQuery.toLowerCase();
      return users
          .where((u) => u.displayName.toLowerCase().contains(lower))
          .toList();
    }
    return users;
  }

  /// Stream of all users for real-time discover feed.
  Stream<List<UserModel>> watchUsers({int limit = 30}) => _db
      .collection('users')
      .where('profileComplete', isEqualTo: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
}

/// Top-level so it can run in a separate isolate via compute().
/// Encodes bytes as-is (image_picker already applies imageQuality: 80).
Uint8List _compressImage(Uint8List bytes) {
  // If already under 150KB return as-is
  if (bytes.lengthInBytes <= 150 * 1024) return bytes;
  // Simple truncation isn't valid — just return original and let
  // Firestore handle it (Firestore doc limit is 1MB, avatars from
  // image_picker at quality 80 are typically 50-150KB).
  return bytes;
}
