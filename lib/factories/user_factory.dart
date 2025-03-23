import '../models/user.dart';

/// Factory for creating different types of users
class UserFactory {
  /// Create a new basic user
  static AppUser createBasicUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) {
    return AppUser(
      id: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      role: UserRole.basic,
      createdAt: DateTime.now(),
      preferences: UserPreferences(
        dailyDigestEnabled: false,
        sportsUpdatesEnabled: false,
        politicalUpdatesEnabled: false,
      ),
    );
  }

  /// Create a new advertiser user
  static AppUser createAdvertiserUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) {
    return AppUser(
      id: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      role: UserRole.advertiser,
      createdAt: DateTime.now(),
      preferences: UserPreferences(
        dailyDigestEnabled: false,
        sportsUpdatesEnabled: false,
        politicalUpdatesEnabled: false,
      ),
    );
  }

  /// Create a new admin user
  static AppUser createAdminUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) {
    return AppUser(
      id: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      role: UserRole.admin,
      createdAt: DateTime.now(),
      preferences: UserPreferences(),
    );
  }
}
