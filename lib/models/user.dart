import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for different user roles
enum UserRole {
  basic,
  advertiser,
  admin,
}

/// A model representing user preferences
class UserPreferences {
  final bool dailyDigestEnabled;
  final bool sportsUpdatesEnabled;
  final bool politicalUpdatesEnabled;
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final String fontSizePreference;
  final List<String> blockedCategories;

  UserPreferences({
    this.dailyDigestEnabled = true,
    this.sportsUpdatesEnabled = false,
    this.politicalUpdatesEnabled = false,
    this.darkModeEnabled = false,
    this.notificationsEnabled = true,
    this.fontSizePreference = 'medium',
    this.blockedCategories = const [],
  });

  /// Create a copy with some fields modified
  UserPreferences copyWith({
    bool? dailyDigestEnabled,
    bool? sportsUpdatesEnabled,
    bool? politicalUpdatesEnabled,
    bool? darkModeEnabled,
    bool? notificationsEnabled,
    String? fontSizePreference,
    List<String>? blockedCategories,
  }) {
    return UserPreferences(
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      sportsUpdatesEnabled: sportsUpdatesEnabled ?? this.sportsUpdatesEnabled,
      politicalUpdatesEnabled:
          politicalUpdatesEnabled ?? this.politicalUpdatesEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      fontSizePreference: fontSizePreference ?? this.fontSizePreference,
      blockedCategories: blockedCategories ?? this.blockedCategories,
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'dailyDigestEnabled': dailyDigestEnabled,
      'sportsUpdatesEnabled': sportsUpdatesEnabled,
      'politicalUpdatesEnabled': politicalUpdatesEnabled,
      'darkModeEnabled': darkModeEnabled,
      'notificationsEnabled': notificationsEnabled,
      'fontSizePreference': fontSizePreference,
      'blockedCategories': blockedCategories,
    };
  }

  /// Create from a Firestore map
  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      dailyDigestEnabled: map['dailyDigestEnabled'] ?? true,
      sportsUpdatesEnabled: map['sportsUpdatesEnabled'] ?? false,
      politicalUpdatesEnabled: map['politicalUpdatesEnabled'] ?? false,
      darkModeEnabled: map['darkModeEnabled'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      fontSizePreference: map['fontSizePreference'] ?? 'medium',
      blockedCategories: List<String>.from(map['blockedCategories'] ?? []),
    );
  }
}

/// A model representing an app user
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phone;
  final String? zipCode;
  final String? biography;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final UserPreferences? preferences;
  final List<String> favoriteArticles;
  final Map<String, dynamic>? businessInfo;
  final List<String> purchasedFeatures;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phone,
    this.zipCode,
    this.biography,
    this.role = UserRole.basic,
    this.createdAt,
    this.lastLogin,
    this.preferences,
    this.favoriteArticles = const [],
    this.businessInfo,
    this.purchasedFeatures = const [],
  });

  /// Create a copy with some fields modified
  AppUser copyWith({
    String? displayName,
    String? photoURL,
    String? phone,
    String? zipCode,
    String? biography,
    UserRole? role,
    UserPreferences? preferences,
    DateTime? lastLogin,
    List<String>? favoriteArticles,
    Map<String, dynamic>? businessInfo,
    List<String>? purchasedFeatures,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phone: phone ?? this.phone,
      zipCode: zipCode ?? this.zipCode,
      biography: biography ?? this.biography,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      preferences: preferences ?? this.preferences,
      favoriteArticles: favoriteArticles ?? this.favoriteArticles,
      businessInfo: businessInfo ?? this.businessInfo,
      purchasedFeatures: purchasedFeatures ?? this.purchasedFeatures,
    );
  }

  /// Update last login time
  AppUser updateLastLogin() {
    return copyWith(lastLogin: DateTime.now());
  }

  /// Create from a Firebase User and additional Firestore data
  factory AppUser.fromFirebaseUser(
    Map<String, dynamic> userData,
    String uid, {
    bool? isEmailVerified,
    Map<String, dynamic>? additionalData,
  }) {
    final userPrefs =
        additionalData != null && additionalData['preferences'] != null
            ? UserPreferences.fromMap(additionalData['preferences'])
            : UserPreferences();

    return AppUser(
      id: uid,
      email: userData['email'] ?? '',
      displayName: userData['displayName'],
      photoURL: userData['photoURL'],
      phone: additionalData?['phone'],
      zipCode: additionalData?['zipCode'],
      biography: additionalData?['biography'],
      role: _parseRole(additionalData?['role']),
      createdAt: additionalData?['createdAt'] != null
          ? (additionalData!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: DateTime.now(),
      preferences: userPrefs,
      favoriteArticles: additionalData?['favoriteArticles'] != null
          ? List<String>.from(additionalData!['favoriteArticles'])
          : [],
      businessInfo: additionalData?['businessInfo'],
      purchasedFeatures: additionalData?['purchasedFeatures'] != null
          ? List<String>.from(additionalData!['purchasedFeatures'])
          : [],
    );
  }

  /// Create from Firestore data
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final prefsMap = json['preferences'] as Map<String, dynamic>?;
    final userPrefs =
        prefsMap != null ? UserPreferences.fromMap(prefsMap) : null;

    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      phone: json['phone'],
      zipCode: json['zipCode'],
      biography: json['biography'],
      role: _parseRole(json['role']),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? (json['lastLogin'] as Timestamp).toDate()
          : DateTime.now(),
      preferences: userPrefs,
      favoriteArticles: json['favoriteArticles'] != null
          ? List<String>.from(json['favoriteArticles'])
          : [],
      businessInfo: json['businessInfo'],
      purchasedFeatures: json['purchasedFeatures'] != null
          ? List<String>.from(json['purchasedFeatures'])
          : [],
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phone': phone,
      'zipCode': zipCode,
      'biography': biography,
      'role': _roleToString(role),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'preferences': preferences?.toMap(),
      'favoriteArticles': favoriteArticles,
      'businessInfo': businessInfo,
      'purchasedFeatures': purchasedFeatures,
    };
  }

  /// Parse UserRole from string
  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'advertiser':
        return UserRole.advertiser;
      default:
        return UserRole.basic;
    }
  }

  /// Convert UserRole to string
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.advertiser:
        return 'advertiser';
      case UserRole.basic:
        return 'basic';
    }
  }

  /// Check if user has purchased a specific feature
  bool hasPurchased(String feature) {
    return purchasedFeatures.contains(feature);
  }

  /// Add a purchased feature
  AppUser addPurchasedFeature(String feature) {
    if (hasPurchased(feature)) return this;

    final updatedFeatures = List<String>.from(purchasedFeatures)..add(feature);
    return copyWith(purchasedFeatures: updatedFeatures);
  }

  /// Check if user has admin privileges
  bool get isAdmin => role == UserRole.admin;

  /// Check if user has advertiser privileges
  bool get isAdvertiser =>
      role == UserRole.advertiser || role == UserRole.admin;

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    // Basic implementation - can be expanded with more sophisticated permission system
    if (role == UserRole.admin) return true;

    if (role == UserRole.advertiser &&
        (permission == 'submit_sponsored_content' ||
            permission == 'view_analytics')) {
      return true;
    }

    return false;
  }

  /// Check if user is subscribed to a specific newsletter
  bool isSubscribedToNewsletter(String newsletterKey) {
    if (preferences == null) return false;

    switch (newsletterKey) {
      case 'daily_digest':
        return preferences!.dailyDigestEnabled;
      case 'sports_updates':
        return preferences!.sportsUpdatesEnabled;
      case 'political_updates':
        return preferences!.politicalUpdatesEnabled;
      default:
        return false;
    }
  }

  /// Check if user has enabled a specific notification type
  bool hasNotificationEnabled(String notificationType) {
    if (preferences == null) return false;

    // Basic implementation
    return preferences!.notificationsEnabled;
  }

  /// Update newsletter preferences
  AppUser updateNewsletterPreferences(Map<String, bool> preferences) {
    if (this.preferences == null) return this;

    return copyWith(
      preferences: this.preferences!.copyWith(
            dailyDigestEnabled: preferences['daily_digest'] ??
                this.preferences!.dailyDigestEnabled,
            sportsUpdatesEnabled: preferences['sports_updates'] ??
                this.preferences!.sportsUpdatesEnabled,
            politicalUpdatesEnabled: preferences['political_updates'] ??
                this.preferences!.politicalUpdatesEnabled,
          ),
    );
  }

  /// Update notification preferences
  AppUser updateNotificationPreferences(Map<String, bool> preferences) {
    if (this.preferences == null) return this;

    return copyWith(
      preferences: this.preferences!.copyWith(
            notificationsEnabled: preferences['notifications_enabled'] ??
                this.preferences!.notificationsEnabled,
          ),
    );
  }

  /// Promote user to advertiser
  AppUser promoteToAdvertiser({
    required String companyName,
    String? website,
    String? companyAddress,
  }) {
    final businessInfo = {
      'companyName': companyName,
      'website': website,
      'companyAddress': companyAddress,
    };

    return copyWith(
      role: UserRole.advertiser,
      businessInfo: businessInfo,
    );
  }
}
