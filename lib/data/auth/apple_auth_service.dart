import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> signInAndGetIdToken() async {
    if (!await SignInWithApple.isAvailable()) {
      throw UnsupportedError(
        'Sign in with Apple is not available on this device.',
      );
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256OfString(rawNonce);

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw StateError('Apple did not return an identityToken.');
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
    );

    final userCred = await _firebaseAuth.signInWithCredential(oauthCredential);
    return userCred.user?.getIdToken();
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<String?> signInAndGetIdTokenViaFirebase() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final userCred = await _firebaseAuth.signInWithProvider(provider);
    return userCred.user?.getIdToken();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
