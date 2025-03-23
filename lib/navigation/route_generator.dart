import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/add_event.dart';
import '../screens/admin_dashboard.dart';
import '../screens/advertiser_dashboard.dart';
import '../article_detail_screen.dart';
import '../screens/community_calendar.dart';
import '../screens/edit_profile_view.dart';
import '../screens/error_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/login_screen.dart';
import '../screens/logout_view.dart';
import '../screens/notification_center.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/profile_view.dart';
import '../screens/register_screen.dart';
import '../screens/remove_ads.dart';
import '../screens/rss_feed_screen.dart';
import '../screens/search_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/submit_article.dart';
import '../screens/submit_news_tip_view.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/weather_screen.dart';
import '../models/rss_item.dart';

class RouteGenerator {
  // Define route names as constants for easy reference
  static const String initialRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String feedRoute = '/feed';
  static const String articleDetailRoute = '/article-detail';
  static const String profileRoute = '/profile';
  static const String editProfileRoute = '/edit-profile';
  static const String submitArticleRoute = '/submit-article';
  static const String addEventRoute = '/add-event';
  static const String removeAdsRoute = '/remove-ads';
  static const String logoutRoute = '/logout';
  static const String submitNewsTipRoute = '/submit-news-tip';
  static const String communityCalendarRoute = '/community-calendar';
  static const String weatherRoute = '/weather';
  static const String searchRoute = '/search';
  static const String advertiserDashboardRoute = '/advertiser-dashboard';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String termsOfServiceRoute = '/terms-of-service';
  static const String privacyPolicyRoute = '/privacy-policy';
  static const String paymentConfirmationRoute = '/payment-confirmation';
  static const String notificationCenterRoute = '/notifications';
  static const String errorRoute = '/error';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case initialRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case feedRoute:
        // Pass RSS feed URL if provided
        if (args is String) {
          return MaterialPageRoute(
            // Fixed: Use RSSFeedScreen instead of NewsScreen
            builder: (_) => RSSFeedScreen(
              feedURL: args,
              title: 'Neuse News',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const RSSFeedScreen(
            feedURL: 'https://www.neusenews.com/index?format=rss',
            title: 'Neuse News',
          ),
        );

      case articleDetailRoute:
        // Pass article URL for detail
        if (args is Map<String, dynamic> && args.containsKey('articleURL')) {
          return MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(articleURL: args['articleURL']),
          );
        } else if (args is RssItem) {
          return MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(articleURL: args.link ?? ''),
          );
        }
        return _errorRoute();

      case profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfileView());

      case editProfileRoute:
        return MaterialPageRoute(builder: (_) => const EditProfileView());

      case submitArticleRoute:
        return _authenticatedRoute(const SubmitArticleScreen());

      case addEventRoute:
        return _authenticatedRoute(const AddEventScreen());

      case removeAdsRoute:
        return _authenticatedRoute(const RemoveAdsScreen());

      case logoutRoute:
        return MaterialPageRoute(builder: (_) => const LogoutView());

      case submitNewsTipRoute:
        return _authenticatedRoute(const SubmitNewsTipView());

      case communityCalendarRoute:
        return MaterialPageRoute(builder: (_) => const CommunityCalendar());

      case weatherRoute:
        return MaterialPageRoute(builder: (_) => const WeatherScreen());

      case searchRoute:
        // Fixed: SearchScreen doesn't have a query parameter
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case advertiserDashboardRoute:
        return _authenticatedRoute(const AdvertiserDashboard());

      case adminDashboardRoute:
        // Fixed: Use AdminDashboardScreen instead of AdminScreen
        return _authenticatedRoute(const AdminDashboardScreen());

      case termsOfServiceRoute:
        return MaterialPageRoute(builder: (_) => const TermsOfServiceScreen());

      case privacyPolicyRoute:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());

      case paymentConfirmationRoute:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => PaymentConfirmationScreen(
              paymentData: args,
            ),
          );
        }
        return _errorRoute();

      case notificationCenterRoute:
        return _authenticatedRoute(const NotificationCenter());

      case errorRoute:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ErrorScreen(
              errorMessage: args['errorMessage'] as String?,
              errorType: args['errorType'],
              onRetry: args['onRetry'] as VoidCallback?,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const ErrorScreen());

      default:
        return _errorRoute();
    }
  }

  // Return an error page route when navigation fails
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const ErrorScreen(
        errorMessage: 'Page not found. The requested route is unavailable.',
      ),
    );
  }

  // Create a route that checks for authentication
  static Route<dynamic> _authenticatedRoute(Widget page) {
    return MaterialPageRoute(builder: (context) {
      final authProvider = Provider.of<AuthProvider>(context);

      // If not authenticated, redirect to login
      if (!authProvider.isAuthenticated) {
        // Use a delayed navigator to avoid build issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Store the path they were trying to access for redirect after login
          authProvider.setRedirectPath(page.runtimeType.toString());
          Navigator.of(context).pushReplacementNamed(loginRoute);
        });

        // Return a loading indicator while redirecting
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // User is authenticated, return the requested page
      return page;
    });
  }
}

class PaymentConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> paymentData;

  const PaymentConfirmationScreen({Key? key, required this.paymentData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paymentType = paymentData['paymentType'] ?? 'default';
    final amount = paymentData['amount'];
    final transactionId = paymentData['transactionId'] ?? '';

    // Rest of your implementation

    // Ensure a widget is always returned
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
      ),
      body: Center(
        child: Text(
            'Payment Type: $paymentType\nAmount: $amount\nTransaction ID: $transactionId'),
      ),
    );
  }
}
