import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AuthController {
  AuthController(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = cred.user?.uid;
    if (uid != null) {
      await _db.doc('users/$uid').set(
        {'lastLogin': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    return cred;
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final cred =
        await _auth.createUserWithEmailAndPassword(email: email, password: password);

    // Production rule: users do NOT choose role during signup.
    // Default role is 'parent'. Admin can later change to 'provider' / 'admin'.
    final uid = cred.user!.uid;
    await _db.doc('users/$uid').set(
      {
        'userId': uid,
        'email': email,
        'role': 'parent',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'parentProfile': {
          'firstName': null,
          'lastName': null,
          'phone': null,
          'city': null,
          'preferredLanguage': null,
        },
      },
      SetOptions(merge: true),
    );

    // Email verification is optional for now (no verification gate in router).
    // You can re-enable later if needed.
    // await cred.user?.sendEmailVerification();
    return cred;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(FirebaseAuth.instance, FirebaseFirestore.instance);
});

