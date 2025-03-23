import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/ad.dart';
import '../models/user.dart'; // Import the AppUser class
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Base service for Firebase functionality
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  bool _initialized = false;
  FirebaseApp? _app;

  // Firebase instances
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get usersCollection => firestore.collection('users');
  CollectionReference get articlesCollection =>
      firestore.collection('articles');
  CollectionReference get adsCollection => firestore.collection('ads');
  CollectionReference get eventsCollection => firestore.collection('events');
  CollectionReference get notificationsCollection =>
      firestore.collection('notifications');
  CollectionReference get analyticsCollection =>
      firestore.collection('analytics');

  // Document references
  DocumentReference getUserDoc(String uid) => usersCollection.doc(uid);

  // Storage references
  Reference getProfileImageRef(String uid) =>
      storage.ref().child('profile_images').child('$uid.jpg');

  Reference getArticleImageRef(String articleId) =>
      storage.ref().child('article_images').child(articleId);

  Reference getAdImageRef(String adId) =>
      storage.ref().child('ad_images').child(adId);

  Reference getEventImageRef(String eventId) =>
      storage.ref().child('event_images').child(eventId);

  // Auth state
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Current user
  User? get currentUser => auth.currentUser;

  /// Initialize Firebase if not already initialized
  Future<void> initializeFirebase() async {
    if (_initialized) return;

    try {
      _app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      if (e is FirebaseException &&
          e.message != null &&
          e.message!.contains('already initialized')) {
        debugPrint('Firebase already initialized');
        _initialized = true;
      } else {
        debugPrint('Error initializing Firebase: $e');
        rethrow;
      }
    }
  }

  /// Check if user has purchased ad removal
  Future<bool> hasUserRemovedAds() async {
    try {
      if (currentUser == null) return false;

      final doc =
          await firestore.collection('users').doc(currentUser!.uid).get();
      return doc.exists && doc.data()?['hasRemovedAds'] == true;
    } catch (e) {
      debugPrint('Error checking ad removal status: $e');
      return false;
    }
  }

  /// Track an ad click
  Future<void> trackAdClick(String adId) async {
    try {
      final clickRef = firestore
          .collection('adMetrics')
          .doc(adId)
          .collection('clicks')
          .doc();
      await clickRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser?.uid ?? 'anonymous',
        'deviceInfo': await _getDeviceInfo(),
      });

      // Also update the total count
      await firestore.collection('adMetrics').doc(adId).set({
        'clicks': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error tracking ad click: $e');
    }
  }

  /// Track an ad impression
  Future<void> trackAdImpression(String adId) async {
    try {
      final impressionRef = firestore
          .collection('adMetrics')
          .doc(adId)
          .collection('impressions')
          .doc();
      await impressionRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser?.uid ?? 'anonymous',
        'deviceInfo': await _getDeviceInfo(),
      });

      // Also update the total count
      await firestore.collection('adMetrics').doc(adId).set({
        'impressions': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error tracking ad impression: $e');
    }
  }

  /// Get active ads from Firestore
  Future<List<Ad>> getActiveAds() async {
    try {
      final querySnapshot = await firestore
          .collection('ads')
          .where('isActive', isEqualTo: true)
          .where('expiryDate', isGreaterThan: DateTime.now())
          .get();

      return querySnapshot.docs.map((doc) => Ad.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting active ads: $e');
      return [];
    }
  }

  /// Helper method to get device info for analytics
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if Firebase is initialized
  bool get isInitialized => _initialized;

  /// Get the Firebase App instance
  FirebaseApp? get app => _app;

  /// Initialize
  Future<void> initialize() async {
    try {
      // Set Firestore settings for cache
      firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);

      if (kDebugMode) {
        print('Firebase service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase service: $e');
      }
    }
  }

  /// Handle Firebase error messages
  String handleFirebaseError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'This email is already in use by another account.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'invalid-credential':
          return 'The login credentials are invalid.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        case 'requires-recent-login':
          return 'This operation requires re-authentication. Please log in again.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    } else {
      return error.toString();
    }
  }

  // Utility method to batch write
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = firestore.batch();

    for (final op in operations) {
      final type = op['type'] as String;
      final ref = op['ref'] as DocumentReference;
      final data = op['data'] as Map<String, dynamic>?;

      switch (type) {
        case 'set':
          batch.set(ref, data!, SetOptions(merge: op['merge'] ?? false));
          break;
        case 'update':
          batch.update(ref, data!);
          break;
        case 'delete':
          batch.delete(ref);
          break;
      }
    }

    await batch.commit();
  }

  // Utility methods
  String generateId() {
    return firestore.collection('temp').doc().id;
  }

  // Error handling
  void handleError(dynamic error, {String? methodName}) {
    if (kDebugMode) {
      print(
          'FirebaseService ${methodName != null ? '($methodName)' : ''} error: $error');
    }
  }

  // Firestore batch processing
  Future<void> runBatch(void Function(WriteBatch batch) actions) async {
    final batch = firestore.batch();
    actions(batch);
    await batch.commit();
  }

  // Transaction processing
  Future<T> runTransaction<T>(
      Future<T> Function(Transaction transaction) actions) async {
    return await firestore.runTransaction(actions);
  }

  // Dispose method
  void dispose() {
    // Nothing to dispose for now, but might be needed in the future
  }

  /// Get saved articles for a user
  Future<List<String>> getSavedArticles(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists || !doc.data()!.containsKey('savedArticles')) {
        return [];
      }

      return List<String>.from(doc.data()!['savedArticles'] ?? []);
    } catch (e) {
      debugPrint('Error fetching saved articles: $e');
      return [];
    }
  }

  /// Update user profile in Firestore
  Future<bool> updateUserProfile(AppUser user) async {
    try {
      await firestore.collection('users').doc(user.id).update(user.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  /// Record error to Firebase Crashlytics
  Future<void> recordError(dynamic exception, StackTrace stack,
      {String? reason}) async {
    try {
      if (kDebugMode) {
        print('Error recorded: $reason');
        print('Exception: $exception');
        print('Stack trace: $stack');
        return;
      }

      // Use Firebase Crashlytics to record the error
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        fatal: false,
        printDetails: true,
      );
    } catch (e) {
      // Failsafe - at least print to console if Crashlytics fails
      debugPrint('Failed to record error to Crashlytics: $e');
      debugPrint('Original error: $exception');
    }
  }

  /// Log user feedback about errors or issues
  Future<void> logFeedback(
      String topic, String message, Map<String, dynamic> metadata) async {
    try {
      // Add timestamp if not already included
      final data = {
        ...metadata,
        'timestamp': metadata['timestamp'] ?? DateTime.now().toIso8601String(),
        'topic': topic,
        'message': message,
      };

      // Store feedback in Firestore
      await firestore.collection('userFeedback').add(data);

      // Also log to Crashlytics as a non-fatal issue
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.recordError(
          'User Feedback: $topic',
          StackTrace.current,
          reason: message,
          fatal: false,
          information: data.entries.map((e) => '${e.key}: ${e.value}').toList(),
        );
      }
    } catch (e) {
      debugPrint('Failed to log feedback: $e');
      // Don't throw - this is a non-critical operation
    }
  }
}
