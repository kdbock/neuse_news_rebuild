import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/brand_colors.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/header.dart';

class LogoutView extends StatefulWidget {
  const LogoutView({super.key});

  @override
  State<LogoutView> createState() => _LogoutViewState();
}

class _LogoutViewState extends State<LogoutView> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (!mounted) return;

      // Navigate to login screen and clear the navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Error logging out: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(
            title: 'Logout',
            showDropdown: false,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    size: 64,
                    color: BrandColors.darkGray,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Are you sure you want to log out?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You will need to sign in again to access your account.',
                    style: TextStyle(
                      fontSize: 16,
                      color: BrandColors.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  CustomButton(
                    text: _isLoggingOut ? 'Logging out...' : 'Log Out',
                    onPressed: _isLoggingOut ? null : _logout,
                    isLoading: _isLoggingOut,
                    variant: CustomButtonVariant.primary,
                    size: CustomButtonSize.large,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: CustomButtonVariant.secondary,
                    size: CustomButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
