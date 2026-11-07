import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  static const String _keySessionUser = 'ghost_session_user';
  static const String _keyIsLoggedIn = 'ghost_is_logged_in';

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Saves persistent session to SharedPreferences
  Future<void> _saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionUser, jsonEncode(user.toMap()));
      await prefs.setBool(_keyIsLoggedIn, true);
      // Synchronize legacy keys used by dio_client & mock rooms
      await prefs.setString('mock_auth_uid', user.id);
      await prefs.setString('mock_auth_name', user.name);
      await prefs.setString('mock_auth_email', user.email);
      await prefs.setBool('mock_auth_verified', user.isEmailVerified);
      if (user.photoUrl != null) {
        await prefs.setString('mock_auth_photo', user.photoUrl!);
      }
      await prefs.setBool('has_completed_onboarding', true);
    } catch (_) {}
  }

  /// Retrieves cached persistent session from local storage
  Future<UserModel?> _getCachedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final userJson = prefs.getString(_keySessionUser);

      if (userJson != null && (isLoggedIn || prefs.getString('mock_auth_uid') != null)) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromMap(map);
      }

      // Fallback from legacy keys
      final uid = prefs.getString('mock_auth_uid');
      if (uid != null && uid.isNotEmpty) {
        return UserModel(
          id: uid,
          name: prefs.getString('mock_auth_name') ?? 'Ghost User',
          email: prefs.getString('mock_auth_email') ?? '',
          photoUrl: prefs.getString('mock_auth_photo'),
          isEmailVerified: prefs.getBool('mock_auth_verified') ?? false,
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Clears persistent session on explicit user logout or delete
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySessionUser);
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove('mock_auth_uid');
      await prefs.remove('mock_auth_name');
      await prefs.remove('mock_auth_email');
      await prefs.remove('mock_auth_photo');
      await prefs.remove('mock_auth_verified');
    } catch (_) {}
  }

  // Stream of authenticated user state
  Stream<UserModel?> get authStateChanges {
    final auth = _auth;
    if (auth != null) {
      return auth.authStateChanges().asyncMap((user) async {
        if (user == null) {
          return await _getCachedSession();
        }
        final mapped = _mapFirebaseUser(user);
        await _saveSession(mapped);
        return mapped;
      });
    }

    // Fallback stream from local session
    return Stream.fromFuture(getCurrentUser());
  }

  Future<UserModel?> getCurrentUser() async {
    // 1. Immediately read cached local session
    final cached = await _getCachedSession();

    final auth = _auth;
    if (auth != null) {
      User? user = auth.currentUser;

      // If Firebase currentUser hasn't restored into memory yet, wait briefly
      if (user == null) {
        try {
          user = await auth.authStateChanges().first.timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () => null,
          );
        } catch (_) {}
      }

      if (user != null) {
        final mapped = _mapFirebaseUser(user);
        await _saveSession(mapped);
        return mapped;
      } else if (cached != null) {
        return cached;
      }
      return null;
    }

    return cached;
  }

  UserModel _mapFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'Ghost User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth != null) {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      await user.sendEmailVerification();

      // Store in Firestore users/{uid}
      try {
        final firestore = _firestore;
        if (firestore != null) {
          await firestore.collection('users').doc(user.uid).set({
            'name': name.trim(),
            'email': email.trim(),
            'photoUrl': null,
            'fcmToken': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}

      final mapped = _mapFirebaseUser(user);
      await _saveSession(mapped);
      return mapped;
    }

    // Mock fallback when Firebase is not yet initialized
    final mockUid = 'ghost_${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      id: mockUid,
      name: name.trim(),
      email: email.trim(),
      isEmailVerified: false,
      createdAt: DateTime.now(),
    );
    await _saveSession(user);
    return user;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth != null) {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final mapped = _mapFirebaseUser(credential.user!);
      await _saveSession(mapped);
      return mapped;
    }

    // Mock fallback
    final cached = await _getCachedSession();
    if (cached != null && cached.email.toLowerCase() == email.trim().toLowerCase()) {
      await _saveSession(cached);
      return cached;
    }

    // Fallback: create mock session
    final mockUid = 'ghost_${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      id: mockUid,
      name: email.split('@').first,
      email: email.trim(),
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
    await _saveSession(user);
    return user;
  }

  Future<UserModel> updateProfile({String? name, String? photoUrl}) async {
    final auth = _auth;
    if (auth != null && auth.currentUser != null) {
      final user = auth.currentUser!;
      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      final uid = user.uid;
      try {
        final Map<String, dynamic> updates = {};
        if (name != null) updates['name'] = name.trim();
        if (photoUrl != null) updates['photoUrl'] = photoUrl;
        if (updates.isNotEmpty) {
          await _firestore?.collection('users').doc(uid).update(updates);
        }
      } catch (_) {}

      final mapped = _mapFirebaseUser(user);
      await _saveSession(mapped);
      return mapped;
    }

    final cached = await _getCachedSession();
    final updated = (cached ?? UserModel(
      id: 'ghost_user',
      name: 'Ghost User',
      email: '',
      createdAt: DateTime.now(),
    )).copyWith(
      name: name,
      photoUrl: photoUrl,
    );
    await _saveSession(updated);
    return updated;
  }

  Future<void> sendEmailVerification() async {
    final auth = _auth;
    if (auth != null && auth.currentUser != null) {
      await auth.currentUser!.sendEmailVerification();
      return;
    }
  }

  Future<bool> checkEmailVerified() async {
    final auth = _auth;
    if (auth != null && auth.currentUser != null) {
      await auth.currentUser!.reload();
      final isVerified = auth.currentUser!.emailVerified;
      final cached = await _getCachedSession();
      if (cached != null) {
        await _saveSession(cached.copyWith(isEmailVerified: isVerified));
      }
      return isVerified;
    }

    // Mock fallback: auto-verifies
    final cached = await _getCachedSession();
    if (cached != null) {
      await _saveSession(cached.copyWith(isEmailVerified: true));
    }
    return true;
  }

  Future<void> sendPasswordReset(String email) async {
    final auth = _auth;
    if (auth != null) {
      await auth.sendPasswordResetEmail(email: email.trim());
      return;
    }
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    }
    await _clearSession();
  }

  Future<void> deleteAccount() async {
    final auth = _auth;
    if (auth != null && auth.currentUser != null) {
      final uid = auth.currentUser!.uid;
      try {
        await _firestore?.collection('users').doc(uid).delete();
      } catch (_) {}
      await auth.currentUser!.delete();
    }
    await _clearSession();
  }
}
