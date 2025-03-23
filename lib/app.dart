import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/environment_config.dart';
import 'constants/app_routes.dart';
import 'navigation/route_generator.dart';
import 'providers/ad_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/rss_provider.dart';
import 'providers/user_provider.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/rss_service.dart';
import 'theme/app_theme.dart';
import 'utils/analytics_helper.dart';
import 'utils/local_storage.dart';
import 'firebase_options.dart'; // Add this line

/// Main application widget that configures providers, theme, and Firebase
class App extends StatefulWidget {
  final Environment environment;

  const App({
    super.key,
    required this.environment,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final FirebaseAnalytics _analytics;
  late final LocalStorage _localStorage;
  late final AuthService _authService;
  late final RssService _rssService;
  late final AdService _adService;
  late final NotificationService _notificationService;
  late final FirebaseService _firebaseService;

  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize all services, Firebase, and other dependencies
  Future<void> _initializeApp() async {
    try {
      // Force orientation to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize environment config
      EnvironmentConfig.initialize(
        environment: widget.environment,
        config: _getEnvironmentConfig(widget.environment),
      );

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firebase services
      _analytics = FirebaseAnalytics.instance;

      // Initialize Crashlytics
      if (EnvironmentConfig.crashlyticsEnabled && !kDebugMode) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      }

      // Initialize local storage
      _localStorage = LocalStorage();
      await _localStorage.initialize();

      // Initialize services
      _firebaseService = FirebaseService();
      await _firebaseService.initializeFirebase();
      _authService = AuthService(_firebaseService);
      _rssService = RssService();
      _adService = AdService(_firebaseService);

      // Initialize notification service
      _notificationService = NotificationService();
      await _notificationService.initialize();

      // Set up Firebase Messaging
      await _setupFirebaseMessaging();

      // Initialize analytics
      await AnalyticsHelper().initialize(
        testMode: !EnvironmentConfig.analyticsEnabled,
      );

      setState(() {
        _initialized = true;
      });
    } catch (e, stackTrace) {
      debugPrint('Error initializing app: $e');
      if (EnvironmentConfig.crashlyticsEnabled && !kDebugMode) {
        await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
      setState(() {
        _error = true;
      });
    }
  }

  /// Setup Firebase Cloud Messaging for push notifications
  Future<void> _setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission for iOS
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await messaging.getToken();

      // Save FCM token to local storage
      if (token != null) {
        await _localStorage.setString('fcm_token', token);
      }

      // Configure messaging handlers
      FirebaseMessaging.onMessage
          .listen(_notificationService.handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp
          .listen(_notificationService.handleMessageOpenedApp);

      // Check for initial message
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _notificationService.handleInitialMessage(initialMessage);
      }
    }
  }

  /// Get environment-specific configuration
  Map<String, dynamic> _getEnvironmentConfig(Environment env) {
    switch (env) {
      case Environment.development:
        return {
          'apiBaseUrl': 'https://dev-api.neusenews.com',
          'verboseLogging': true,
          'analyticsEnabled': false,
          'crashlyticsEnabled': false,
          'adTrackingEnabled': false,
          'adRefreshInterval': 60,
          'cacheDuration': 5,
        };
      case Environment.staging:
        return {
          'apiBaseUrl': 'https://staging-api.neusenews.com',
          'verboseLogging': true,
          'analyticsEnabled': true,
          'crashlyticsEnabled': true,
          'adTrackingEnabled': true,
          'adRefreshInterval': 30,
          'cacheDuration': 10,
        };
      case Environment.production:
        return {
          'apiBaseUrl': 'https://api.neusenews.com',
          'verboseLogging': false,
          'analyticsEnabled': true,
          'crashlyticsEnabled': true,
          'adTrackingEnabled': true,
          'adRefreshInterval': 30,
          'cacheDuration': 15,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading or error screens if not initialized
    if (_error) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Failed to initialize the app'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeApp,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFd2982a)),
                ),
                SizedBox(height: 16),
                Text('Initializing...'),
              ],
            ),
          ),
        ),
      );
    }

    // Configure the main app with providers once initialized
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>.value(value: _authService),
        Provider<RssService>.value(value: _rssService),
        Provider<AdService>.value(value: _adService),
        Provider<FirebaseService>.value(value: _firebaseService),
        Provider<NotificationService>.value(value: _notificationService),

        // App state providers
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (_) => AppSettingsProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(_authService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(_firebaseService),
          update: (_, authProvider, previousUserProvider) =>
              previousUserProvider!..update(authProvider.currentUser),
        ),
        ChangeNotifierProvider<RssProvider>(
          create: (_) => RssProvider(_rssService),
        ),
        ChangeNotifierProvider<AdProvider>(
          create: (_) => AdProvider(_adService),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, appSettings, _) {
          return MaterialApp(
            scaffoldMessengerKey: NotificationService.messengerKey,
            title: 'Neuse News',
            debugShowCheckedModeBanner: !EnvironmentConfig.isProduction,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appSettings.themeMode,
            navigatorKey: _navigatorKey,
            onGenerateRoute: RouteGenerator.generateRoute,
            initialRoute: AppRoutes.splash,
            navigatorObservers: [
              // Analytics observer for screen tracking
              AnalyticsNavigatorObserver(AnalyticsHelper()),
              FirebaseAnalyticsObserver(analytics: _analytics),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Restore orientation settings when app is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
