import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'config/environment_config.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print("Flutter binding initialized");

    // Initialize config BEFORE Firebase
    EnvironmentConfig.initialize(
      environment: Environment.production,
      config: {
        'apiBaseUrl': 'https://api.neusenews.com',
        'verboseLogging': false,
        'analyticsEnabled': true,
        'crashlyticsEnabled': true,
        'adTrackingEnabled': true,
        'adRefreshInterval': 30,
        'cacheDuration': 15,
      },
    );

    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully");
    } catch (e) {
      print("Firebase initialization error: $e");
      // If Firebase fails, use the fallback app
      runApp(const FallbackApp());
      return;
    }

    // Use the App class from app.dart with required environment parameter
    runApp(const App(environment: Environment.production));
    print("App started successfully");
  } catch (e, stackTrace) {
    print("Error in main: $e");
    print("Stack trace: $stackTrace");
    // If any error occurs, show the fallback app
    runApp(const FallbackApp());
  }
}

// Simple fallback app for when initialization fails
class FallbackApp extends StatelessWidget {
  const FallbackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Failed to initialize the app',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Retry initialization
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
