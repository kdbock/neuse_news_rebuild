import 'dart:io'; // Add this import for File class
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';
import '../models/user.dart' as app_user;

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthService with ChangeNotifier {
  final FirebaseService _firebaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  app_user.AppUser? _appUser;
  String? _errorMessage;

  AuthService(this._firebaseService) {
    _init();
  }

  Future<void> _init() async {
    await _firebaseService.initializeFirebase();

    // Listen for auth state changes
    _firebaseService.auth.authStateChanges().listen((User? user) async {
      _user = user;

      if (user != null) {
        // User is signed in
        await _fetchUserData();
        _status = AuthStatus.authenticated;
      } else {
        // User is signed out
        _appUser = null;
        _status = AuthStatus.unauthenticated;
      }

      notifyListeners();
    });
  }

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _user;
  app_user.AppUser? get appUser => _appUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _appUser?.role == app_user.UserRole.admin;
  bool get isAdvertiser => _appUser?.role == app_user.UserRole.advertiser;

  // Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _errorMessage = null;

      final userCredential =
          await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      if (_user != null) {
        await _fetchUserData();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _errorMessage = null;

      final userCredential =
          await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      if (_user != null) {
        // Update user profile
        await _user!.updateDisplayName(displayName);

        // Create user document in Firestore
        final newUser = app_user.AppUser(
          id: _user!.uid,
          email: email,
          displayName: displayName,
          role: app_user.UserRole.basic,
          createdAt: DateTime.now(),
          preferences: app_user.UserPreferences(),
        );

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set(newUser.toJson());

        _appUser = newUser;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sign in with credential (Google, Apple)
  Future<bool> signInWithCredential(AuthCredential credential) async {
    try {
      _errorMessage = null;

      final userCredential =
          await _firebaseService.auth.signInWithCredential(credential);
      _user = userCredential.user;

      if (_user != null) {
        await _fetchUserData();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseService.auth.signOut();
      await GoogleSignIn().signOut();
      _user = null;
      _appUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _errorMessage = null;
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      if (_user != null) {
        await _user!.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  // Update Firebase Auth profile
  Future<void> updateFirebaseProfile(
      String? displayName, String? photoURL) async {
    try {
      if (_user != null) {
        if (displayName != null) {
          await _user!.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await _user!.updatePhotoURL(photoURL);
        }
      }
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
    }
  }

  // Get user by ID
  Future<app_user.AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return app_user.AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return null;
    }
  }

  // Create user
  Future<bool> createUser(app_user.AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
      return true;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  // Update user
  Future<bool> updateUser(app_user.AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      return true;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();

      if (doc.exists && doc.data() != null) {
        _appUser = app_user.AppUser.fromJson(doc.data()!);
      } else {
        // Create basic user profile if it doesn't exist
        final newUser = app_user.AppUser(
          id: _user!.uid,
          email: _user!.email ?? '',
          displayName: _user!.displayName ?? '',
          photoURL: _user!.photoURL,
          role: app_user.UserRole.basic,
          createdAt: DateTime.now(),
          preferences: app_user.UserPreferences(),
        );

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set(newUser.toJson());
        _appUser = newUser;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  // Upgrade user to advertiser
  Future<bool> upgradeToAdvertiser() async {
    try {
      if (_user == null || _appUser == null) return false;

      await _firestore.collection('users').doc(_user!.uid).update({
        'role': app_user.UserRole.advertiser.toString().split('.').last,
      });

      // Update local app user object
      _appUser = _appUser!.copyWith(role: app_user.UserRole.advertiser);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  // Add this method to convert Firebase User to AppUser
  app_user.AppUser? getCurrentAppUser() {
    final user = _firebaseService.auth.currentUser;
    if (user == null) return null;
    return _appUser;
  }

  /// Update the user's profile information
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? zipCode,
    String? biography,
  }) async {
    try {
      // Update Firebase Auth profile if needed
      if (displayName != null || photoURL != null) {
        await updateFirebaseProfile(displayName, photoURL);
      }

      if (_appUser == null) {
        _errorMessage = 'No authenticated user found';
        notifyListeners();
        throw Exception('No authenticated user found');
      }

      // Create updated user model
      final updatedUser = _appUser!.copyWith(
        displayName: displayName ?? _appUser!.displayName,
        photoURL: photoURL ?? _appUser!.photoURL,
        phone: phoneNumber ?? _appUser!.phone,
        zipCode: zipCode ?? _appUser!.zipCode,
        biography: biography ?? _appUser!.biography,
      );

      // Update in Firestore
      await updateUser(updatedUser);

      // Update local user state
      _appUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      throw Exception('Failed to update profile: $_errorMessage');
    }
  }

  /// Upload a profile photo to Firebase Storage and get the download URL
  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      if (_user == null) {
        throw Exception('No authenticated user found');
      }

      final ref = _firebaseService.storage
          .ref()
          .child('profile_photos')
          .child('${_user!.uid}.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();

      // Update Firebase Auth profile
      await _user!.updatePhotoURL(downloadURL);

      // Update Firestore profile
      if (_appUser != null) {
        final updatedUser = _appUser!.copyWith(photoURL: downloadURL);
        await updateUser(updatedUser);
        _appUser = updatedUser;
        notifyListeners();
      }

      return downloadURL;
    } catch (e) {
      _errorMessage = _firebaseService.handleFirebaseError(e);
      notifyListeners();
      return null;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth == null) {
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseService.auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }
}
