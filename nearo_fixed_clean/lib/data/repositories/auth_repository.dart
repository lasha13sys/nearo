import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/app_user.dart';

class AuthRepository {
  final bool firebaseReady;
  final firebase_auth.FirebaseAuth? _auth;

  AuthRepository({required this.firebaseReady})
      : _auth = firebaseReady ? firebase_auth.FirebaseAuth.instance : null;

  Stream<AppUser?> authStateChanges() {
    if (!firebaseReady || _auth == null) return Stream<AppUser?>.value(null);
    return _auth.authStateChanges().map(_mapFirebaseUser);
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    if (!firebaseReady || _auth == null) return AppUser.demo;
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = _mapFirebaseUser(credential.user);
    if (user == null) throw firebase_auth.FirebaseAuthException(code: 'no-user');
    return user;
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!firebaseReady || _auth == null) {
      return AppUser(
        uid: 'demo-user',
        email: email.trim(),
        displayName: displayName.trim().isEmpty ? 'Demo User' : displayName.trim(),
        isDemo: true,
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    final user = _mapFirebaseUser(credential.user);
    if (user == null) throw firebase_auth.FirebaseAuthException(code: 'no-user');
    return user;
  }

  Future<void> signOut() async {
    if (!firebaseReady || _auth == null) return;
    await _auth.signOut();
  }

  AppUser? _mapFirebaseUser(firebase_auth.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@').first ?? 'Nearo User',
    );
  }
}
