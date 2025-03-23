import 'package:flutter/material.dart';
import '../constants/app_colors.dart'; // Changed from theme/brand_colors.dart to use your constants
import '../widgets/custom_button.dart';
import '../widgets/header.dart';

class TermsOfServiceScreen extends StatelessWidget {
  final bool showAcceptButton;
  final Function()? onAccept;

  const TermsOfServiceScreen({
    super.key,
    this.showAcceptButton = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(
            title: 'Terms of Service',
            showDropdown: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terms of Service',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors
                          .darkGray, // Changed from BrandColors to AppColors
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Last Updated: March 15, 2025',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Introduction
                  _buildSectionTitle('1. Introduction'),
                  _buildParagraph(
                      'Welcome to the Neuse News app. These Terms of Service ("Terms") govern your use of the Neuse News mobile application (the "App"), operated by Magic Mile Media, LLC ("we," "us," or "our"). By accessing or using the App, you agree to be bound by these Terms. If you disagree with any part of the Terms, you may not access the App.'),

                  // User Accounts
                  _buildSectionTitle('2. User Accounts'),
                  _buildParagraph(
                      'When you create an account with us, you must provide accurate, complete, and current information. You are responsible for safeguarding the password that you use to access the App and for any activities or actions under your password.'),
                  _buildParagraph(
                      'You agree not to disclose your password to any third party. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.'),

                  // Content
                  _buildSectionTitle('3. Content'),
                  _buildParagraph(
                      'Our App allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material ("Content"). You are responsible for the Content that you post on or through the App, including its legality, reliability, and appropriateness.'),
                  _buildParagraph(
                      'By posting Content on or through the App, you represent and warrant that: (i) the Content is yours (you own it) or you have the right to use it and grant us the rights and license as provided in these Terms, and (ii) the posting of your Content on or through the App does not violate the privacy rights, publicity rights, copyrights, contract rights or any other rights of any person.'),

                  // Sponsored Content
                  _buildSectionTitle('4. Sponsored Content and Advertising'),
                  _buildParagraph(
                      'The App offers the ability to publish sponsored articles and community events for a fee. All sponsored content will be reviewed by our editorial team before publication and must comply with our content guidelines. We reserve the right to reject any sponsored content at our sole discretion.'),
                  _buildParagraph(
                      'Sponsored content will be clearly marked as such in the App. Payment for sponsored content does not guarantee approval or publication. If your content is rejected, you may be eligible for a refund according to our refund policy.'),

                  // Subscriptions and Purchases
                  _buildSectionTitle('5. Subscriptions and In-App Purchases'),
                  _buildParagraph(
                      'Some features of the App require payment, including sponsored articles (\$75), community events (\$25), and ad removal (\$5). All purchases are final and non-refundable unless otherwise specified or required by applicable law.'),
                  _buildParagraph(
                      'Payments are processed through the Apple App Store or Google Play Store, and are subject to their respective terms and conditions. We are not responsible for any payment processing errors or fees imposed by these platforms.'),

                  // Intellectual Property
                  _buildSectionTitle('6. Intellectual Property'),
                  _buildParagraph(
                      'The App and its original content (excluding Content provided by users), features, and functionality are and will remain the exclusive property of Magic Mile Media, LLC and its licensors. The App is protected by copyright, trademark, and other laws of both the United States and foreign countries.'),
                  _buildParagraph(
                      'Our trademarks and trade dress may not be used in connection with any product or service without the prior written consent of Magic Mile Media, LLC.'),

                  // Links To Other Web Sites
                  _buildSectionTitle('7. Links To Other Websites'),
                  _buildParagraph(
                      'Our App may contain links to third-party websites or services that are not owned or controlled by Magic Mile Media, LLC.'),
                  _buildParagraph(
                      'Magic Mile Media, LLC has no control over, and assumes no responsibility for, the content, privacy policies, or practices of any third-party websites or services. You further acknowledge and agree that Magic Mile Media, LLC shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with the use of or reliance on any such content, goods, or services available on or through any such websites or services.'),

                  // Termination
                  _buildSectionTitle('8. Termination'),
                  _buildParagraph(
                      'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.'),
                  _buildParagraph(
                      'Upon termination, your right to use the App will immediately cease. If you wish to terminate your account, you may simply discontinue using the App or contact us to request account deletion.'),

                  // Limitation Of Liability
                  _buildSectionTitle('9. Limitation Of Liability'),
                  _buildParagraph(
                      'In no event shall Magic Mile Media, LLC, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from (i) your access to or use of or inability to access or use the App; (ii) any conduct or content of any third party on the App; (iii) any content obtained from the App; and (iv) unauthorized access, use or alteration of your transmissions or content, whether based on warranty, contract, tort (including negligence) or any other legal theory, whether or not we have been informed of the possibility of such damage.'),

                  // Disclaimers
                  _buildSectionTitle('10. Disclaimers'),
                  _buildParagraph(
                      'Your use of the App is at your sole risk. The App is provided on an "AS IS" and "AS AVAILABLE" basis. The App is provided without warranties of any kind, whether express or implied, including, but not limited to, implied warranties of merchantability, fitness for a particular purpose, non-infringement or course of performance.'),
                  _buildParagraph(
                      'Magic Mile Media, LLC does not warrant that a) the App will function uninterrupted, secure or available at any particular time or location; b) any errors or defects will be corrected; c) the App is free of viruses or other harmful components; or d) the results of using the App will meet your requirements.'),

                  // Governing Law
                  _buildSectionTitle('11. Governing Law'),
                  _buildParagraph(
                      'These Terms shall be governed and construed in accordance with the laws of North Carolina, United States, without regard to its conflict of law provisions.'),
                  _buildParagraph(
                      'Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights. If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions of these Terms will remain in effect.'),

                  // Changes
                  _buildSectionTitle('12. Changes'),
                  _buildParagraph(
                      'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days\' notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.'),
                  _buildParagraph(
                      'By continuing to access or use our App after those revisions become effective, you agree to be bound by the revised terms. If you do not agree to the new terms, please stop using the App.'),

                  // Contact Us
                  _buildSectionTitle('13. Contact Us'),
                  _buildParagraph(
                      'If you have any questions about these Terms, please contact us at:'),
                  _buildParagraph('Magic Mile Media, LLC\n'
                      '123 News Lane\n'
                      'Kinston, NC 28504\n'
                      'Email: info@neusenews.com'),

                  const SizedBox(height: 32),

                  // Accept button
                  if (showAcceptButton)
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Accept Terms',
                        onPressed: onAccept,
                        variant: CustomButtonVariant.primary,
                        size: CustomButtonSize.large,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Back button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      variant: showAcceptButton
                          ? CustomButtonVariant.secondary
                          : CustomButtonVariant.primary,
                      size: CustomButtonSize.large,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 24.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGray, // Changed from BrandColors to AppColors
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.darkGray, // Changed from BrandColors to AppColors
          height: 1.5,
        ),
      ),
    );
  }
}
