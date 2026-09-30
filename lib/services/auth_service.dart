 // lib/services/auth_service.dart
// Firebase Authentication — wraps all sign-in, sign-up, and sign-out flows.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '947108910301-rgjj051fhmkt082jv7l9l3quckbni3ga.apps.googleusercontent.com'
        : null,
  );
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream & current user ────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Email / Password ─────────────────────────────────────────────────────
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(displayName.trim());
    await cred.user!.reload();

    final model = UserModel(
      uid: cred.user!.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await _upsertUser(model);
    return model;
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _touchLastLogin(cred.user!.uid);
    return await _fetchUser(cred.user!) ??
        _toDefaultModel(cred.user!);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in was cancelled.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user!;

    final existing = await _fetchUser(user);
    if (existing == null) {
      final model = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Google User',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await _upsertUser(model);
      return model;
    }
    await _touchLastLogin(user.uid);
    return existing.copyWith(lastLoginAt: DateTime.now());
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() => Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

  // ── Firestore helpers ────────────────────────────────────────────────────
  Future<void> _upsertUser(UserModel u) =>
      _db.collection('users').doc(u.uid).set(u.toFirestore());

  Future<UserModel?> _fetchUser(User u) async {
    final doc = await _db.collection('users').doc(u.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!);
  }

  Future<void> _touchLastLogin(String uid) =>
      _db.collection('users').doc(uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

  UserModel _toDefaultModel(User u) => UserModel(
        uid: u.uid,
        email: u.email ?? '',
        displayName: u.displayName ?? 'AstraFlix User',
        photoUrl: u.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

  // ── Human-readable error messages ────────────────────────────────────────
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
