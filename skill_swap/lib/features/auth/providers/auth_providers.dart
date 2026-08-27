import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../profile/repositories/profile_repository.dart';

// ── Raw Firebase auth stream ───────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── Current UserModel (null when signed out) ───────────────────────────────
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authUser = await ref.watch(authStateProvider.future);
  if (authUser == null) {
    yield null;
    return;
  }
  yield* ref.watch(profileRepositoryProvider).watchUser(authUser.uid);
});

// ── Repository providers ───────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

// ── Auth actions notifier ──────────────────────────────────────────────────
enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  const AuthState({this.status = AuthStatus.idle, this.error});
  AuthState copyWith({AuthStatus? status, String? error}) =>
      AuthState(status: status ?? this.status, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.signIn(email, password);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _friendly(e));
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.signUp(email, password, name);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _friendly(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.signInWithGoogle();
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _friendly(e));
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.signInWithApple();
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _friendly(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }

  Future<bool> resetPassword(String email) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.resetPassword(email);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _friendly(e));
      return false;
    }
  }

  void clearError() => state = const AuthState();

  String _friendly(Object e) {
    final msg = e.toString();
    if (e is FirebaseAuthException) {
      if (e.code == 'account-exists-with-different-credential') {
        return 'This email is already linked to another sign-in method.';
      }
      if (e.code == 'credential-already-in-use') {
        return 'This Google account is already linked to another user.';
      }
    }
    if (msg.contains('cancelled') || msg.contains('canceled'))
      return 'Sign-in was cancelled.';
    if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential'))
      return 'Invalid email or password.';
    if (msg.contains('email-already-in-use')) return 'Email already in use.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('network-request-failed'))
      return 'Network error. Check your connection.';
    if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
      return 'Google Sign-In configuration is invalid. Check the Android package name and SHA-1 in Firebase Console.';
    }
    if (msg.contains('GoogleSignInApi') || msg.contains('channel-error')) {
      return 'Google Sign-In is unavailable on this device. Use an emulator with Google Play services.';
    }
    return msg;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
