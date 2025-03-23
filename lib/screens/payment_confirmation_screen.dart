import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/brand_colors.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/header.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final String? purchaseType;
  final double? amount;
  final String? transactionId;
  final DateTime? purchaseDate;
  final Map<String, dynamic>? additionalDetails;

  const PaymentConfirmationScreen({
    super.key,
    this.purchaseType,
    this.amount,
    this.transactionId,
    this.purchaseDate,
    this.additionalDetails,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.appUser;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    // Default values if not provided
    final type = purchaseType ?? 'Item';
    final paymentAmount = amount ?? 0.00;
    final date = purchaseDate ?? DateTime.now();
    final formattedDate = dateFormat.format(date);
    final id = transactionId ?? 'TX-${date.millisecondsSinceEpoch}';

    // Generate receipt number
    final receiptNumber =
        'NN-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${id.substring(id.length - 6)}';

    return Scaffold(
      body: Column(
        children: [
          const Header(
            title: 'Payment Confirmation',
            showDropdown: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Success checkmark
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

                    // Success message
                    Text(
                      'Payment Successful!',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: BrandColors.darkGray,
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSuccessMessage(type),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: BrandColors.darkGray,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Receipt card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Receipt',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: BrandColors.darkGray,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                      text: 'Receipt: $receiptNumber\n'
                                          'Date: $formattedDate\n'
                                          'Amount: \$${paymentAmount.toStringAsFixed(2)}\n'
                                          'Type: $type\n'
                                          'Transaction ID: $id',
                                    ));
                                    SnackBarHelper.showSuccessSnackBar(
                                      context,
                                      message: 'Receipt copied to clipboard',
                                    );
                                  },
                                  tooltip: 'Copy receipt',
                                ),
                              ],
                            ),
                            const Divider(),
                            _buildReceiptRow('Receipt Number', receiptNumber),
                            _buildReceiptRow('Date', formattedDate),
                            _buildReceiptRow(
                                'Purchase Type', _getPurchaseTypeDisplay(type)),
                            if (additionalDetails != null &&
                                additionalDetails!['title'] != null)
                              _buildReceiptRow(
                                  'Item', additionalDetails!['title']),
                            _buildReceiptRow('Amount',
                                '\$${paymentAmount.toStringAsFixed(2)}'),
                            _buildReceiptRow(
                                'Payment Method', 'App Store / Play Store'),
                            _buildReceiptRow('Status', 'Paid'),
                            const Divider(),
                            _buildReceiptRow(
                                'Customer', user?.displayName ?? 'Guest User'),
                            _buildReceiptRow(
                                'Email', user?.email ?? 'No email provided'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Support info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'A copy of this receipt has been sent to your email. '
                              'For support, please contact info@neusenews.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    CustomButton(
                      text: _getNextActionButton(type),
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          _getNextActionRoute(type),
                          (route) => route.settings.name == '/feed',
                        );
                      },
                      variant: CustomButtonVariant.primary,
                      size: CustomButtonSize.large,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Return to Home',
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/feed',
                          (route) => false,
                        );
                      },
                      variant: CustomButtonVariant.secondary,
                      size: CustomButtonSize.large,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSuccessMessage(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return 'Your sponsored article has been submitted for review. Our team will review your submission and publish it soon.';
      case 'event':
        return 'Your community event has been submitted for review. Once approved, it will appear in our community calendar.';
      case 'ad_removal':
        return 'You\'ve successfully removed ads from the app. Enjoy your ad-free experience!';
      default:
        return 'Thank you for your purchase! Your transaction has been completed successfully.';
    }
  }

  String _getPurchaseTypeDisplay(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return 'Sponsored Article';
      case 'event':
        return 'Community Event';
      case 'ad_removal':
        return 'Ad Removal';
      default:
        return type;
    }
  }

  String _getNextActionButton(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return 'Submit Another Article';
      case 'event':
        return 'Add Another Event';
      case 'ad_removal':
        return 'Explore More Features';
      default:
        return 'Continue Shopping';
    }
  }

  String _getNextActionRoute(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return '/submit-article';
      case 'event':
        return '/add-event';
      case 'ad_removal':
        return '/profile';
      default:
        return '/feed';
    }
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: BrandColors.darkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: BrandColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
