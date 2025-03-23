import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../theme/brand_colors.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/header.dart';

class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({super.key});

  @override
  State<RemoveAdsScreen> createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> {
  bool _isPurchasing = false;
  bool _showSuccessMessage = false;
  bool _hasAdsRemoved = false;

  // In a real app, this would be tied to payment processor
  static const double removeAdsPrice = 5.00;

  @override
  void initState() {
    super.initState();
    _checkAdStatus();
  }

  Future<void> _checkAdStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.appUser;

    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            _hasAdsRemoved = userDoc.data()!['adsRemoved'] ?? false;
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _purchaseAdRemoval() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // In a real app, you would integrate with in-app purchases
      // For iOS: StoreKit/In-App Purchase API
      // For Android: Google Play Billing Library
      // Or use a cross-platform solution like 'in_app_purchase' package

      // Get current user
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.appUser;

      if (user == null) {
        throw Exception('You must be logged in to purchase ad removal');
      }

      // Update Firestore record
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'adsRemoved': true,
        'adRemovalPurchaseDate': FieldValue.serverTimestamp(),
        'adRemovalPaymentAmount': removeAdsPrice,
      });

      // Update local state
      setState(() {
        _hasAdsRemoved = true;
        _isPurchasing = false;
        _showSuccessMessage = true;
      });
    } catch (e) {
      setState(() {
        _isPurchasing = false;
      });
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Error processing payment: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(
            title: 'Remove Ads',
            showDropdown: false,
          ),
          Expanded(
            child: _showSuccessMessage
                ? _buildSuccessView()
                : _hasAdsRemoved
                    ? _buildAlreadyPurchasedView()
                    : _buildPurchaseView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ads Removed Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'ve successfully removed ads from the app. Enjoy an ad-free experience!',
              style: TextStyle(
                fontSize: 16,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Return to Home',
              onPressed: () {
                Navigator.of(context).pop();
              },
              variant: CustomButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyPurchasedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.verified,
                color: Colors.blue[700],
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'You Already Have Ad-Free Access',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'ve already purchased the ad-free experience. Enjoy browsing without ads!',
              style: TextStyle(
                fontSize: 16,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Return to Home',
              onPressed: () {
                Navigator.of(context).pop();
              },
              variant: CustomButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ad-free graphic
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.ad_units,
                    size: 100,
                    color: Colors.grey,
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 5,
                        color: Colors.red,
                        transform: Matrix4.rotationZ(0.785), // 45 degrees
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Remove All Ads',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Price
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: BrandColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                '\$5.00',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Benefits
            const Text(
              'Enjoy a completely ad-free experience',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Benefits list
            ..._buildBenefitItems(),
            const SizedBox(height: 32),

            // Purchase button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _isPurchasing
                    ? 'Processing Payment...'
                    : 'Remove Ads for \$5.00',
                onPressed: _isPurchasing ? null : _purchaseAdRemoval,
                isLoading: _isPurchasing,
                variant: CustomButtonVariant.primary,
                size: CustomButtonSize.large,
              ),
            ),
            const SizedBox(height: 16),

            // Fine print
            const Text(
              'One-time payment, no recurring subscription.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ad removal is linked to your account and will be available on all your devices.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBenefitItems() {
    final benefits = [
      'No banner ads at the top and bottom of screens',
      'No ads between news articles',
      'No sponsored content in your feed',
      'Faster loading times and less data usage',
      'Support local journalism',
    ];

    return benefits.map((benefit) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle,
              color: BrandColors.gold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                benefit,
                style: const TextStyle(
                  fontSize: 16,
                  color: BrandColors.darkGray,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
