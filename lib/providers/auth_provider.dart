import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/analytics_helper.dart';
import '../utils/local_storage.dart';
import '../factories/user_factory.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  // Add firebaseCurrentUser property
  firebase_auth.User? get firebaseCurrentUser => _authService.currentUser;

  AuthProvider(this._authService);

  final AnalyticsHelper _analytics = AnalyticsHelper();
  final LocalStorage _localStorage = LocalStorage();

  // Authentication state
  AuthStatus _status = AuthStatus.initial;

  // Current user
  AppUser? _user;

  // Firebase user
  firebase_auth.User? _firebaseUser;

  // Auth errors
  String? _errorMessage;

  // Auth token
  String? _token;

  // Session timer for token refresh
  Timer? _sessionTimer;

  // Redirect path after login
  String? _redirectPath;

  // Purchased features
  Set<String> _purchasedFeatures = {};

  // Loading status for operations
  bool _isLoading = false;

  // Email verification sent status
  bool _verificationEmailSent = false;

  // Getters
  AuthStatus get status => _status;
  AppUser? get user => _user;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get redirectPath => _redirectPath;
  bool get isLoading => _isLoading;
  bool get verificationEmailSent => _verificationEmailSent;

  // Auth state convenience getters
  bool get isInitial => _status == AuthStatus.initial;
  bool get isAuthenticating => _status == AuthStatus.authenticating;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;
  bool get hasError => _status == AuthStatus.error;

  /// Initialize the provider
  Future<void> initialize() async {
    await _localStorage.initialize();

    // Load purchased features
    await _loadPurchasedFeatures();

    // Listen to Firebase auth state changes
    firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen(_handleAuthStateChanged);
  }

  /// Handle Firebase auth state changes
  Future<void> _handleAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _setUnauthenticated();
      return;
    }

    _firebaseUser = firebaseUser;

    try {
      // Get fresh token
      _token = await firebaseUser.getIdToken(true);

      // Fetch user profile from Firestore
      final userDoc = await _authService.getUserById(firebaseUser.uid);

      if (userDoc != null) {
        // User exists in Firestore
        _user = userDoc;
        _setAuthenticated();
      } else {
        // User exists in Firebase Auth but not in Firestore
        // Create a new user document
        final newUser = UserFactory.createBasicUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
        );

        await _authService.createUser(newUser);
        _user = newUser;
        _setAuthenticated();
      }

      // Setup token refresh
      _setupTokenRefresh();
    } catch (e) {
      _setError('Error loading user profile: ${e.toString()}');
    }
  }

  /// Set authenticated state
  void _setAuthenticated() {
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();

    // Log analytics
    _analytics.logEvent('user_authenticated', parameters: {
      'user_id': _user?.id ?? '',
      'user_role': 'unknown',
    });
  }

  /// Set unauthenticated state
  void _setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    _user = null;
    _firebaseUser = null;
    _token = null;
    _errorMessage = null;
    _sessionTimer?.cancel();
    notifyListeners();
  }

  /// Set error state
  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();

    // Log error
    _analytics.logEvent('auth_error', parameters: {
      'error_message': message,
    });
  }

  /// Set authenticating state
  void _setAuthenticating() {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    _setAuthenticating();
    _isLoading = true;
    notifyListeners();

    try {
      final result =
          await _authService.signInWithEmailPassword(email, password);
      _isLoading = false;
      return result;
    } catch (e) {
      _isLoading = false;
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    _setAuthenticating();
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signUpWithEmailPassword(
        email,
        password,
        displayName,
      );
      _isLoading = false;

      if (result) {
        // Send verification email
        await sendEmailVerification();
      }

      return result;
    } catch (e) {
      _isLoading = false;
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setAuthenticating();
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _isLoading = false;
        _setUnauthenticated();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _authService.signInWithCredential(credential);
      _isLoading = false;
      return result;
    } catch (e) {
      _isLoading = false;
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    _setAuthenticating();
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final result = await _authService.signInWithCredential(oauthCredential);
      _isLoading = false;
      return result;
    } catch (e) {
      _isLoading = false;
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();

      // Log analytics
      _analytics.logEvent('password_reset_email_sent', parameters: {
        'email': email,
      });

      return true;
    } catch (e) {
      _isLoading = false;
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    }
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    if (_firebaseUser == null) return false;

    _isLoading = true;
    _verificationEmailSent = false;
    notifyListeners();

    try {
      await _authService.sendEmailVerification();
      _isLoading = false;
      _verificationEmailSent = true;
      notifyListeners();

      // Log analytics
      _analytics.logEvent('verification_email_sent', parameters: {
        'user_id': _user?.id ?? '',
      });

      return true;
    } catch (e) {
      _isLoading = false;
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _user?.id;

      await _authService.signOut();
      _setUnauthenticated();
      _isLoading = false;

      // Log analytics
      if (userId != null) {
        _analytics.logEvent('user_signed_out', parameters: {
          'user_id': userId,
        });
      }
    } catch (e) {
      _isLoading = false;
      _setError('Error signing out: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? zipCode,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Update Firebase Auth profile if needed
      if (displayName != null || photoURL != null) {
        await _authService.updateFirebaseProfile(displayName, photoURL);
      }

      // Update Firestore user document
      final updatedUser = _user!.copyWith(
        displayName: displayName ?? _user!.displayName,
        photoURL: photoURL ?? _user!.photoURL,
        phone: phoneNumber ?? _user!.phone,
        zipCode: zipCode ?? _user!.zipCode,
      );

      final success = await _authService.updateUser(updatedUser);

      if (success) {
        _user = updatedUser;

        // Log analytics
        _analytics.logEvent('profile_updated', parameters: {
          'user_id': _user?.id ?? '',
        });
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _setError('Error updating profile: ${e.toString()}');
      return false;
    }
  }

  /// Update user newsletter preferences
  Future<bool> updateNewsletterPreferences(
      Map<String, bool> preferences) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _user!.updateNewsletterPreferences(preferences);
      final success = await _authService.updateUser(updatedUser);

      if (success) {
        _user = updatedUser;

        // Log analytics
        _analytics.logEvent('newsletter_preferences_updated', parameters: {
          'user_id': _user?.id ?? '',
          'preferences': preferences.toString(),
        });
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _setError('Error updating newsletter preferences: ${e.toString()}');
      return false;
    }
  }

  /// Update user notification preferences
  Future<bool> updateNotificationPreferences(
      Map<String, bool> preferences) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _user!.updateNotificationPreferences(preferences);
      final success = await _authService.updateUser(updatedUser);

      if (success) {
        _user = updatedUser;

        // Log analytics
        _analytics.logEvent('notification_preferences_updated', parameters: {
          'user_id': _user?.id ?? '',
          'preferences': preferences.toString(),
        });
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _setError('Error updating notification preferences: ${e.toString()}');
      return false;
    }
  }

  /// Promote user to advertiser role
  Future<bool> promoteToAdvertiser({
    required String companyName,
    String? website,
    String? companyAddress,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _user!.promoteToAdvertiser(
        companyName: companyName,
        website: website,
        companyAddress: companyAddress,
      );

      final success = await _authService.updateUser(updatedUser);

      if (success) {
        _user = updatedUser;

        // Log analytics
        _analytics.logEvent('user_promoted_to_advertiser', parameters: {
          'user_id': _user?.id ?? '',
          'company_name': companyName,
        });
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _setError('Error promoting to advertiser: ${e.toString()}');
      return false;
    }
  }

  /// Set redirect path after login
  void setRedirectPath(String? path) {
    _redirectPath = path;
  }

  /// Clear redirect path
  void clearRedirectPath() {
    _redirectPath = null;
  }

  /// Setup token refresh timer
  void _setupTokenRefresh() {
    _sessionTimer?.cancel();

    // Refresh token every hour
    _sessionTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) async {
        if (_firebaseUser != null) {
          try {
            _token = await _firebaseUser!.getIdToken(true);

            // Refresh user profile periodically
            final userDoc = await _authService.getUserById(_firebaseUser!.uid);
            if (userDoc != null) {
              _user = userDoc;
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Error refreshing token: $e');
          }
        }
      },
    );
  }

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    if (_user == null) return false;
    return _user!.hasPermission(permission);
  }

  /// Check if user is subscribed to a specific newsletter
  bool isSubscribedToNewsletter(String newsletterKey) {
    if (_user == null) return false;
    return _user!.isSubscribedToNewsletter(newsletterKey);
  }

  /// Check if user has enabled a specific notification type
  bool hasNotificationEnabled(String notificationType) {
    if (_user == null) return false;
    return _user!.hasNotificationEnabled(notificationType);
  }

  /// Add purchased feature
  Future<void> addPurchasedFeature(String feature) async {
    _purchasedFeatures.add(feature);
    await _savePurchasedFeatures();
    notifyListeners();

    // Log analytics
    _analytics.logEvent('feature_purchased', parameters: {
      'feature': feature,
      'user_id': _user?.id ?? 'anonymous',
    });
  }

  /// Check if user has purchased a specific feature
  bool hasFeature(String feature) {
    return _purchasedFeatures.contains(feature);
  }

  /// Load purchased features from local storage
  Future<void> _loadPurchasedFeatures() async {
    final features = await _localStorage.getPurchasedFeatures();
    if (features != null) {
      _purchasedFeatures = Set<String>.from(features);
      notifyListeners();
    }
  }

  /// Save purchased features to local storage
  Future<void> _savePurchasedFeatures() async {
    await _localStorage.savePurchasedFeatures(_purchasedFeatures.toList());
  }

  /// Get user-friendly error message for Firebase Auth errors
  String _getFirebaseAuthErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Wrong password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password is too weak. Please use a stronger password.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed login attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not allowed. Please contact support.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'Authentication error: ${error.toString()}';
  }

  /// Convert Firebase User to AppUser for the user provider
  AppUser? get currentUser {
    final user = _authService.currentUser;
    if (user == null) return null;

    // If you have the Firebase User but need an AppUser
    return _authService.appUser;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
