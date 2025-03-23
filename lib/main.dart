import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'config/environment_config.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print("Flutter binding initialized");

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

// Create a simple fallback app for when Firebase fails
class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error initializing app. Please try again later.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Code to retry initialization
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
