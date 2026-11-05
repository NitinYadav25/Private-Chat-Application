import 'dart:async';
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

  // Stream of authenticated user state
  Stream<UserModel?> get authStateChanges {
    final auth = _auth;
    if (auth != null) {
      return auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        return _mapFirebaseUser(user);
      });
    }

    // Fallback stream from local SharedPreferences
    return Stream.fromFuture(getCurrentUser());
  }

  Future<UserModel?> getCurrentUser() async {
    final auth = _auth;
    if (auth != null) {
      final user = auth.currentUser;
      if (user == null) return null;
      return _mapFirebaseUser(user);
    }

    // Local storage fallback
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('mock_auth_uid');
    if (uid == null) return null;

    return UserModel(
      id: uid,
      name: prefs.getString('mock_auth_name') ?? 'Ghost User',
      email: prefs.getString('mock_auth_email') ?? '',
      photoUrl: prefs.getString('mock_auth_photo'),
      isEmailVerified: prefs.getBool('mock_auth_verified') ?? false,
      createdAt: DateTime.now(),
    );
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

      return _mapFirebaseUser(user);
    }

    // Mock fallback when Firebase is not yet initialized
    final prefs = await SharedPreferences.getInstance();
    final mockUid = 'ghost_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('mock_auth_uid', mockUid);
    await prefs.setString('mock_auth_name', name.trim());
    await prefs.setString('mock_auth_email', email.trim());
    await prefs.setBool('mock_auth_verified', false);

    return UserModel(
      id: mockUid,
      name: name.trim(),
      email: email.trim(),
      isEmailVerified: false,
      createdAt: DateTime.now(),
    );
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
      return _mapFirebaseUser(credential.user!);
    }

    // Mock fallback
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('mock_auth_email');
    if (storedEmail != null && storedEmail.toLowerCase() == email.trim().toLowerCase()) {
      final uid = prefs.getString('mock_auth_uid') ?? 'ghost_user';
      final name = prefs.getString('mock_auth_name') ?? 'Ghost User';
      final verified = prefs.getBool('mock_auth_verified') ?? false;
      return UserModel(
        id: uid,
        name: name,
        email: email.trim(),
        photoUrl: prefs.getString('mock_auth_photo'),
        isEmailVerified: verified,
        createdAt: DateTime.now(),
      );
    }

    // Fallback: create mock session
    final mockUid = 'ghost_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('mock_auth_uid', mockUid);
    await prefs.setString('mock_auth_name', email.split('@').first);
    await prefs.setString('mock_auth_email', email.trim());
    await prefs.setBool('mock_auth_verified', true);

    return UserModel(
      id: mockUid,
      name: email.split('@').first,
      email: email.trim(),
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
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

      return _mapFirebaseUser(user);
    }

    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString('mock_auth_name', name.trim());
    }
    if (photoUrl != null) {
      await prefs.setString('mock_auth_photo', photoUrl);
    }

    final current = await getCurrentUser();
    return current ??
        UserModel(
          id: prefs.getString('mock_auth_uid') ?? 'ghost_user',
          name: name ?? 'Ghost User',
          email: prefs.getString('mock_auth_email') ?? '',
          photoUrl: photoUrl,
          isEmailVerified: true,
          createdAt: DateTime.now(),
        );
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
      return auth.currentUser!.emailVerified;
    }

    // Mock fallback: auto-verifies
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mock_auth_verified', true);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mock_auth_uid');
    await prefs.remove('mock_auth_verified');
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
