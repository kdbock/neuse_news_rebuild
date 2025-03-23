import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class SnackBarHelper {
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration,
    );
  }

  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  static void showWarningSnackBar(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
    );
  }

  static void showInfoSnackBar(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: BrandColors.gold,
      icon: Icons.info,
      duration: duration,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration? duration,
  }) {
    // Ensure the previous SnackBar is removed
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
