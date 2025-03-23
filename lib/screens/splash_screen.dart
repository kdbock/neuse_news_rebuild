import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_routes.dart';
// relative import, since login_screen.dart is in the same directory

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/neusenewslogo.png',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.gold,
                foregroundColor: BrandColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Removed const since AppStrings.getStarted must be a compile-time constant.
              child: const Text(AppStrings.getStarted),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: BrandColors.gold),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                AppStrings.sponsoredBy,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandColors.gold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
