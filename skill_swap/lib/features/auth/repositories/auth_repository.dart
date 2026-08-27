import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn(
    serverClientId:
        '352867316217-idp08ep32lalce14v7ld0c8e98l0mki9.apps.googleusercontent.com',
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  // ── Email / Password ───────────────────────────────────────────────────────
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUp(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    await _ensureUserDoc(
      uid: cred.user!.uid,
      email: email,
      name: name,
      photoUrl: null,
    );
  }

  // ── Google ─────────────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled.');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _ensureUserDoc(
      uid: result.user!.uid,
      email: result.user!.email ?? '',
      name: result.user!.displayName ?? googleUser.displayName ?? 'User',
      photoUrl: result.user!.photoURL,
    );
  }

  // ── Apple ──────────────────────────────────────────────────────────────────
  Future<void> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    final result = await _auth.signInWithCredential(oauthCredential);
    final name = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].where((s) => s != null && s.isNotEmpty).join(' ').trim();

    await _ensureUserDoc(
      uid: result.user!.uid,
      email: result.user!.email ?? appleCredential.email ?? '',
      name: name.isNotEmpty ? name : result.user!.displayName ?? 'User',
      photoUrl: result.user!.photoURL,
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    // Best-effort sign out: try Google sign-out but don't fail the whole
    // operation if it times out or errors. Ensure Firebase signOut is
    // attempted and surfaced to callers if it fails.
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 6));
    } catch (e) {
      // Log and continue; Google sign-out sometimes times out on device.
      print('AuthRepository.signOut: Google signOut failed: $e');
    }

    // FirebaseAuth signOut is the primary sign-out action. If a timeout
    // occurs, retry once without a timeout to give the platform a second
    // chance before surfacing an error to the UI.
    try {
      await _auth.signOut().timeout(const Duration(seconds: 6));
    } on TimeoutException catch (e) {
      try {
        await _auth.signOut();
      } catch (e2) {
        throw Exception(
          'Firebase signOut failed (timeout then retry): $e; $e2',
        );
      }
    }
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Creates the Firestore user doc only if it doesn't already exist,
  /// so returning users don't lose their profile data.
  Future<void> _ensureUserDoc({
    required String uid,
    required String email,
    required String name,
    required String? photoUrl,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) {
      final user = UserModel(
        uid: uid,
        email: email,
        displayName: name,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );
      await ref.set(user.toMap());
    }
  }

  String _generateNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
