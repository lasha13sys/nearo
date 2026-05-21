import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/app_user.dart';

class PhoneVerificationSession {
  final String verificationId;
  final int? resendToken;

  const PhoneVerificationSession({
    required this.verificationId,
    this.resendToken,
  });
}

class AuthRepository {
  final bool firebaseReady;
  final firebase_auth.FirebaseAuth? _auth;

  AuthRepository({required this.firebaseReady})
      : _auth = firebaseReady ? firebase_auth.FirebaseAuth.instance : null;

  Stream<AppUser?> authStateChanges() {
    if (!firebaseReady || _auth == null) return Stream<AppUser?>.value(null);
    return _auth.authStateChanges().map(_mapFirebaseUser);
  }

  Future<PhoneVerificationSession> requestSmsCode({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    final normalizedPhone = phoneNumber.trim();
    if (normalizedPhone.length < 8) {
      throw firebase_auth.FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'Enter a valid phone number.',
      );
    }

    if (!firebaseReady || _auth == null) {
      return const PhoneVerificationSession(verificationId: 'demo-verification');
    }

    final completer = Completer<PhoneVerificationSession>();
    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {
          // The OTP screen still handles manual code entry if auto verification fails.
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(PhoneVerificationSession(verificationId: verificationId));
        }
      },
    );

    return completer.future;
  }

  Future<AppUser> verifySmsCode({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final cleanCode = smsCode.trim();
    if (cleanCode.length < 4) {
      throw firebase_auth.FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'Enter the SMS code.',
      );
    }

    if (!firebaseReady || _auth == null || verificationId == 'demo-verification') {
      return AppUser(
        uid: phoneNumber.trim().isEmpty ? 'demo-user' : 'demo-${phoneNumber.trim().replaceAll(RegExp(r'[^0-9]'), '')}',
        phoneNumber: phoneNumber.trim().isEmpty ? '+995555000000' : phoneNumber.trim(),
        displayName: 'Nearo User',
        isDemo: true,
      );
    }

    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: cleanCode,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = _mapFirebaseUser(result.user);
    if (user == null) throw firebase_auth.FirebaseAuthException(code: 'no-user');
    return user;
  }

  Future<void> signOut() async {
    if (!firebaseReady || _auth == null) return;
    await _auth.signOut();
  }

  AppUser? _mapFirebaseUser(firebase_auth.User? user) {
    if (user == null) return null;
    final phone = user.phoneNumber ?? '';
    return AppUser(
      uid: user.uid,
      phoneNumber: phone,
      displayName: user.displayName ?? (phone.isEmpty ? 'Nearo User' : phone),
    );
  }
}
