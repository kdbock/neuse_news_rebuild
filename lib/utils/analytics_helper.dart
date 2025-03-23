// filepath: /Users/kristybock/neuse_news_rebuild/lib/utils/analytics_helper.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Helper class for tracking analytics events
class AnalyticsHelper {
  static final AnalyticsHelper _instance = AnalyticsHelper._internal();
  factory AnalyticsHelper() => _instance;

  AnalyticsHelper._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _isTestMode = false;

  /// Initialize analytics with optional test mode
  Future<void> initialize({bool testMode = false}) async {
    try {
      _isTestMode = testMode;

      // Set analytics collection enabled based on test mode
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!testMode);

      if (kDebugMode) {
        print('Analytics initialized. Test mode: $testMode');
      }
    } catch (e) {
      debugPrint('Error initializing analytics: $e');
    }
  }

  /// Log a custom event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      if (_isTestMode) {
        if (kDebugMode) {
          print('Test Analytics Event: $name, params: $parameters');
        }
        return;
      }

      if (kDebugMode) {
        print('Analytics Event: $name, params: $parameters');
      }
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  /// Log a screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      if (_isTestMode) {
        if (kDebugMode) {
          print('Test Screen View: $screenName, class: $screenClass');
        }
        return;
      }

      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }
}

/// Navigator observer for automatically tracking screen views
class AnalyticsNavigatorObserver extends NavigatorObserver {
  final AnalyticsHelper analytics;

  AnalyticsNavigatorObserver(this.analytics);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sendScreenView(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _sendScreenView(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _sendScreenView(Route<dynamic> route) {
    if (route.settings.name != null) {
      analytics.logScreenView(route.settings.name!);
    }
  }
}
