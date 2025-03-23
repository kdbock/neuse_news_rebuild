import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/environment_config.dart';
import 'navigation/route_generator.dart';
import 'providers/auth_provider.dart' as provider;
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'widgets/bottom_navigation.dart';

class App extends StatelessWidget {
  final Environment environment;

  const App({Key? key, required this.environment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Create FirebaseService first
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),

        // If AuthService extends ChangeNotifier
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(context.read<FirebaseService>()),
        ),
        // OR if it uses Stream
        // StreamProvider<AuthService>(
        //   create: (context) => AuthService(context.read<FirebaseService>()).asStream(),
        //   initialData: AuthService(context.read<FirebaseService>()),
        // ),

        // Use the AuthService to create AuthProvider
        ChangeNotifierProxyProvider<AuthService, provider.AuthProvider>(
          create: (context) =>
              provider.AuthProvider(context.read<AuthService>()),
          update: (context, authService, previous) =>
              previous ?? provider.AuthProvider(authService),
        ),
      ],
      child: MaterialApp(
        title: 'Neuse News',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        onGenerateRoute: RouteGenerator.generateRoute,
        home: const BottomNavigation(initialIndex: 0),
      ),
    );
  }
}

// Optional: You can keep this or remove it if you're not using it
class YourHomePage extends StatelessWidget {
  const YourHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<provider.AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Neuse News')),
      body: Center(
        child: authProvider.isAuthenticated
            ? Text('Welcome, ${authProvider.user?.displayName ?? "User"}')
            : const Text('Please sign in to continue'),
      ),
    );
  }
}
