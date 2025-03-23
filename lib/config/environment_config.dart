// filepath: /Users/kristybock/neuse_news_rebuild/lib/config/environment_config.dart
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Environment options for different build configurations
enum Environment { development, staging, production }

/// Configuration for different environment settings
class EnvironmentConfig {
  static Map<String, dynamic> _config = {};
  static Environment _environment =
      Environment.production; // Default to production

  /// Initialize the environment configuration
  static void initialize({
    required Environment environment,
    required Map<String, dynamic> config,
  }) {
    _environment = environment;
    _config = config;
  }

  /// Get Firebase options for the current environment
  static FirebaseOptions getFirebaseOptions() {
    return DefaultFirebaseOptions.currentPlatform;
  }

  /// Get a configuration value by key
  static T getValue<T>(String key, {T? defaultValue}) {
    if (_config.containsKey(key)) {
      return _config[key] as T;
    }
    if (defaultValue != null) {
      return defaultValue;
    }
    throw Exception('No value found for key: $key');
  }

  /// API base URL
  static String get apiBaseUrl => getValue<String>('apiBaseUrl');

  /// Whether verbose logging is enabled
  static bool get verboseLogging =>
      getValue<bool>('verboseLogging', defaultValue: false);

  /// Whether analytics tracking is enabled
  static bool get analyticsEnabled =>
      getValue<bool>('analyticsEnabled', defaultValue: false);

  /// Whether crashlytics is enabled
  static bool get crashlyticsEnabled =>
      getValue<bool>('crashlyticsEnabled', defaultValue: false);

  /// Whether ad tracking is enabled
  static bool get adTrackingEnabled =>
      getValue<bool>('adTrackingEnabled', defaultValue: false);

  /// Ad refresh interval in seconds
  static int get adRefreshInterval =>
      getValue<int>('adRefreshInterval', defaultValue: 30);

  /// Cache duration in minutes
  static int get cacheDuration =>
      getValue<int>('cacheDuration', defaultValue: 15);

  /// Check if we're in production environment
  static bool get isProduction => _environment == Environment.production;

  /// Current environment
  static Environment get environment => _environment;
}
