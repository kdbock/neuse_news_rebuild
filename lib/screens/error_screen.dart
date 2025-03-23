import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../widgets/custom_button.dart';
import '../utils/analytics_helper.dart';
import '../services/firebase_service.dart';
import '../providers/app_settings_provider.dart';

enum ErrorType {
  network,
  authentication,
  server,
  permission,
  notFound,
  maintenance,
  generic
}

class ErrorScreen extends StatefulWidget {
  final ErrorType errorType;
  final String? errorMessage;
  final String? errorCode;
  final dynamic exception;
  final String? detailedErrorMessage;
  final VoidCallback? onRetry;
  final bool showHomeButton;
  final bool showReportButton;

  const ErrorScreen({
    super.key,
    this.errorType = ErrorType.generic,
    this.errorMessage,
    this.errorCode,
    this.exception,
    this.detailedErrorMessage,
    this.onRetry,
    this.showHomeButton = true,
    this.showReportButton = true,
  });

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  final AnalyticsHelper _analytics = AnalyticsHelper();
  bool _showDetailedError = false;
  bool _isReporting = false;
  bool _reportSent = false;

  @override
  void initState() {
    super.initState();
    _logError();
  }

  void _logError() {
    final errorParams = {
      'error_type': widget.errorType.toString(),
      'error_message': widget.errorMessage ?? 'Unknown error',
      if (widget.errorCode != null) 'error_code': widget.errorCode!,
    };

    _analytics.logEvent('app_error_screen_viewed', parameters: errorParams);

    // Log to Crashlytics if available
    if (widget.exception != null) {
      FirebaseService().recordError(
        widget.exception,
        StackTrace.current,
        reason: widget.errorMessage ?? 'Error displayed on ErrorScreen',
      );
    }
  }

  Future<void> _reportIssue() async {
    if (_isReporting || _reportSent) return;

    setState(() {
      _isReporting = true;
    });

    try {
      await FirebaseService().logFeedback(
        'Error Report',
        widget.errorMessage ?? 'Unknown error',
        {
          'error_type': widget.errorType.toString(),
          if (widget.errorCode != null) 'error_code': widget.errorCode!,
          if (widget.detailedErrorMessage != null)
            'details': widget.detailedErrorMessage!,
          'timestamp': DateTime.now().toIso8601String(),
          'app_version':
              Provider.of<AppSettingsProvider>(context, listen: false)
                  .appVersion,
        },
      );

      setState(() {
        _isReporting = false;
        _reportSent = true;
      });

      _analytics.logEvent('error_report_submitted', parameters: {
        'error_type': widget.errorType.toString(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Thank you for reporting this issue. We\'ll look into it.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isReporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report issue: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildErrorImage(),
                const SizedBox(height: 32),
                Text(
                  _getErrorTitle(),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.errorMessage ?? _getDefaultErrorMessage(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (widget.errorCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Error code: ${widget.errorCode}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ),
                const SizedBox(height: 32),
                if (widget.onRetry != null)
                  CustomButton(
                    text: _getRetryButtonText(),
                    onPressed: widget.onRetry,
                    icon: Icons.refresh,
                  ),
                if (widget.onRetry != null && widget.showHomeButton)
                  const SizedBox(height: 16),
                if (widget.showHomeButton)
                  CustomButton(
                    text: 'Go to Home Page',
                    onPressed: () =>
                        Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.home,
                      (route) => false,
                    ),
                    isOutlined: true,
                    icon: Icons.home,
                  ),
                const SizedBox(height: 24),
                if (widget.showReportButton)
                  _reportSent
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Thanks for reporting this issue!',
                            style: TextStyle(color: Colors.green),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _isReporting ? null : _reportIssue,
                          icon: _isReporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('Report this issue'),
                        ),
                if (kDebugMode && widget.detailedErrorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailedErrorSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    String assetPath;
    double size = 150;

    switch (widget.errorType) {
      case ErrorType.network:
        assetPath = 'assets/icons/network_error.svg';
        break;
      case ErrorType.authentication:
        assetPath = 'assets/icons/auth_error.svg';
        break;
      case ErrorType.permission:
        assetPath = 'assets/icons/permission_error.svg';
        break;
      case ErrorType.notFound:
        assetPath = 'assets/icons/not_found_error.svg';
        break;
      case ErrorType.maintenance:
        assetPath = 'assets/icons/maintenance_error.svg';
        break;
      case ErrorType.server:
        assetPath = 'assets/icons/server_error.svg';
        break;
      case ErrorType.generic:
      default:
        assetPath = 'assets/icons/generic_error.svg';
    }

    try {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
      );
    } catch (e) {
      // Fallback to icon if SVG asset is not available
      IconData iconData;
      Color iconColor;

      switch (widget.errorType) {
        case ErrorType.network:
          iconData = Icons.wifi_off;
          iconColor = Colors.blue;
          break;
        case ErrorType.authentication:
          iconData = Icons.lock;
          iconColor = Colors.red;
          break;
        case ErrorType.permission:
          iconData = Icons.no_accounts;
          iconColor = Colors.orange;
          break;
        case ErrorType.notFound:
          iconData = Icons.search_off;
          iconColor = Colors.grey;
          break;
        case ErrorType.maintenance:
          iconData = Icons.engineering;
          iconColor = Colors.amber;
          break;
        case ErrorType.server:
          iconData = Icons.cloud_off;
          iconColor = Colors.purple;
          break;
        case ErrorType.generic:
        default:
          iconData = Icons.error_outline;
          iconColor = AppColors.primary;
      }

      return Icon(
        iconData,
        size: size,
        color: iconColor,
      );
    }
  }

  Widget _buildDetailedErrorSection() {
    return ExpansionTile(
      title: const Text(
        'Technical Details',
        style: TextStyle(fontSize: 14),
      ),
      initiallyExpanded: _showDetailedError,
      onExpansionChanged: (expanded) {
        setState(() {
          _showDetailedError = expanded;
        });
      },
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          width: double.infinity,
          child: SelectableText(
            widget.detailedErrorMessage ??
                'No detailed error information available',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _getErrorTitle() {
    switch (widget.errorType) {
      case ErrorType.network:
        return 'Connection Problem';
      case ErrorType.authentication:
        return 'Authentication Error';
      case ErrorType.permission:
        return 'Permission Denied';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.maintenance:
        return 'Under Maintenance';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.generic:
        return 'Something Went Wrong';
    }
  }

  String _getDefaultErrorMessage() {
    switch (widget.errorType) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.authentication:
        return 'You need to be logged in to access this feature. Please sign in and try again.';
      case ErrorType.permission:
        return 'You don\'t have permission to access this feature.';
      case ErrorType.notFound:
        return 'The resource you\'re looking for was not found.';
      case ErrorType.maintenance:
        return 'We\'re currently performing maintenance. Please try again later.';
      case ErrorType.server:
        return 'We\'re experiencing server issues. Please try again later.';
      case ErrorType.generic:
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }

  String _getRetryButtonText() {
    switch (widget.errorType) {
      case ErrorType.network:
        return 'Retry Connection';
      case ErrorType.authentication:
        return 'Sign In';
      case ErrorType.permission:
        return 'Go Back';
      case ErrorType.maintenance:
      case ErrorType.server:
        return 'Check Again';
      case ErrorType.notFound:
      case ErrorType.generic:
      default:
        return 'Try Again';
    }
  }
}
