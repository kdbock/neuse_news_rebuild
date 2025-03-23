import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

/// Provider for user data and profile management
class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  AppUser? _user;
  bool _isLoading = false;

  UserProvider(this._firebaseService);

  /// Current user information
  AppUser? get user => _user;

  /// Whether user data is loading
  bool get isLoading => _isLoading;

  /// Whether user is authenticated
  bool get isAuthenticated => _user != null;

  /// Update user data
  void update(AppUser? user) {
    _user = user;
    notifyListeners();
  }

  /// Get user's saved articles
  Future<List<String>> getSavedArticles() async {
    if (_user == null) return [];

    try {
      return await _firebaseService.getSavedArticles(_user!.id);
    } catch (e) {
      debugPrint('Error getting saved articles: $e');
      return [];
    }
  }

  /// Update user profile information
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    String? phone,
    String? zipCode,
    String? biography,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Create updated user with new information
      final updatedUser = _user!.copyWith(
        displayName: displayName ?? _user!.displayName,
        photoURL: photoURL ?? _user!.photoURL,
        phone: phone ?? _user!.phone,
        zipCode: zipCode ?? _user!.zipCode,
        biography: biography,
      );

      // Update in Firestore
      final success = await _firebaseService.updateUserProfile(updatedUser);

      if (success) {
        _user = updatedUser;
      }

      return success;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user notification preferences
  Future<bool> updateNotificationPreferences({
    bool? dailyDigest,
    bool? sportUpdates,
    bool? politicalUpdates,
  }) async {
    if (_user == null || _user!.preferences == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Create updated preferences
      final updatedPreferences = _user!.preferences!.copyWith(
        dailyDigestEnabled:
            dailyDigest ?? _user!.preferences!.dailyDigestEnabled,
        sportsUpdatesEnabled:
            sportUpdates ?? _user!.preferences!.sportsUpdatesEnabled,
        politicalUpdatesEnabled:
            politicalUpdates ?? _user!.preferences!.politicalUpdatesEnabled,
      );

      // Create updated user with new preferences
      final updatedUser = _user!.copyWith(
        preferences: updatedPreferences,
      );

      // Update in Firestore
      final success = await _firebaseService.updateUserProfile(updatedUser);

      if (success) {
        _user = updatedUser;
      }

      return success;
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if user is an advertiser
  bool get isAdvertiser =>
      _user?.role == UserRole.advertiser || _user?.role == UserRole.admin;

  /// Check if user is an admin
  bool get isAdmin => _user?.role == UserRole.admin;

  void updateUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }

  void setUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }
}
