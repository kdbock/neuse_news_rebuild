import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool showAcceptButton;
  final Function()? onAccept;

  const PrivacyPolicyScreen({
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
            title: 'Privacy Policy',
            showDropdown: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.darkGray,
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
                  _buildParagraph(
                      'Magic Mile Media, LLC ("we," "us," or "our") operates the Neuse News mobile application (the "App"). This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our App and the choices you have associated with that data.'),
                  _buildParagraph(
                      'We use your data to provide and improve the App. By using the App, you agree to the collection and use of information in accordance with this policy.'),

                  // Information Collection and Use
                  _buildSectionTitle('Information Collection and Use'),
                  _buildParagraph(
                      'We collect several different types of information for various purposes to provide and improve our App to you.'),

                  // Types of Data Collected
                  _buildSectionTitle('Types of Data Collected'),

                  // Personal Data
                  _buildSubsectionTitle('Personal Data'),
                  _buildParagraph(
                      'While using our App, we may ask you to provide us with certain personally identifiable information that can be used to contact or identify you ("Personal Data"). Personally identifiable information may include, but is not limited to:'),
                  _buildBulletPoint('Email address'),
                  _buildBulletPoint('First name and last name'),
                  _buildBulletPoint('Phone number'),
                  _buildBulletPoint('ZIP code'),
                  _buildBulletPoint('Cookies and Usage Data'),

                  // Usage Data
                  _buildSubsectionTitle('Usage Data'),
                  _buildParagraph(
                      'When you access the App with a mobile device, we may collect certain information automatically, including, but not limited to, the type of mobile device you use, your mobile device unique ID, the IP address of your mobile device, your mobile operating system, the type of mobile Internet browser you use, unique device identifiers and other diagnostic data ("Usage Data").'),

                  // Tracking & Cookies Data
                  _buildSubsectionTitle('Tracking & Cookies Data'),
                  _buildParagraph(
                      'We use cookies and similar tracking technologies to track the activity on our App and hold certain information.'),
                  _buildParagraph(
                      'Cookies are files with a small amount of data which may include an anonymous unique identifier. Cookies are sent to your browser from a website and stored on your device. Tracking technologies also used are beacons, tags, and scripts to collect and track information and to improve and analyze our App.'),
                  _buildParagraph(
                      'You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent. However, if you do not accept cookies, you may not be able to use some portions of our App.'),
                  _buildParagraph('Examples of Cookies we use:'),
                  _buildBulletPoint(
                      'Session Cookies: We use Session Cookies to operate our App.'),
                  _buildBulletPoint(
                      'Preference Cookies: We use Preference Cookies to remember your preferences and various settings.'),
                  _buildBulletPoint(
                      'Security Cookies: We use Security Cookies for security purposes.'),

                  // Use of Data
                  _buildSectionTitle('Use of Data'),
                  _buildParagraph(
                      'Magic Mile Media, LLC uses the collected data for various purposes:'),
                  _buildBulletPoint('To provide and maintain the App'),
                  _buildBulletPoint('To notify you about changes to our App'),
                  _buildBulletPoint(
                      'To allow you to participate in interactive features of our App when you choose to do so'),
                  _buildBulletPoint('To provide customer care and support'),
                  _buildBulletPoint(
                      'To provide analysis or valuable information so that we can improve the App'),
                  _buildBulletPoint('To monitor the usage of the App'),
                  _buildBulletPoint(
                      'To detect, prevent and address technical issues'),
                  _buildBulletPoint(
                      'To deliver relevant advertisement content based on your preferences'),

                  // Firebase Analytics and Tracking
                  _buildSectionTitle('Firebase Analytics and Tracking'),
                  _buildParagraph(
                      'We use Firebase, a service provided by Google, for analytics and user tracking purposes. Firebase collects information about how you use our App, including but not limited to app usage statistics, crash reports, and user engagement metrics.'),
                  _buildParagraph(
                      'The information collected by Firebase is used to analyze and improve our App\'s performance, understand user behavior, and optimize our services. This information is processed in accordance with Google\'s privacy policy, which can be found at https://policies.google.com/privacy.'),

                  // Ad Metrics and Analytics
                  _buildSectionTitle('Ad Metrics and Analytics'),
                  _buildParagraph(
                      'Our App includes an advertising system that collects metrics such as impressions, clicks, and engagement data. This information is used to measure the effectiveness of advertisements and to improve the advertising experience within the App.'),
                  _buildParagraph(
                      'If you are an advertiser, we collect and provide information about the performance of your advertisements, including impression counts, click-through rates, and conversion metrics. This information is stored securely and is only accessible to you and our administrative team.'),

                  // Transfer of Data
                  _buildSectionTitle('Transfer of Data'),
                  _buildParagraph(
                      'Your information, including Personal Data, may be transferred to — and maintained on — computers located outside of your state, province, country or other governmental jurisdiction where the data protection laws may differ from those of your jurisdiction.'),
                  _buildParagraph(
                      'If you are located outside the United States and choose to provide information to us, please note that we transfer the data, including Personal Data, to the United States and process it there.'),
                  _buildParagraph(
                      'Your consent to this Privacy Policy followed by your submission of such information represents your agreement to that transfer.'),
                  _buildParagraph(
                      'Magic Mile Media, LLC will take all steps reasonably necessary to ensure that your data is treated securely and in accordance with this Privacy Policy and no transfer of your Personal Data will take place to an organization or a country unless there are adequate controls in place including the security of your data and other personal information.'),

                  // Security of Data
                  _buildSectionTitle('Security of Data'),
                  _buildParagraph(
                      'The security of your data is important to us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your Personal Data, we cannot guarantee its absolute security.'),

                  // In-App Purchases
                  _buildSectionTitle('In-App Purchases'),
                  _buildParagraph(
                      'Our App offers in-app purchases for sponsored articles, community events, and ad removal. Payment information is processed through Apple App Store or Google Play Store and is subject to their respective privacy policies.'),
                  _buildParagraph(
                      'We do not store your payment information such as credit card details. However, we do maintain records of your purchases for customer service purposes and to fulfill our obligations to you as a customer.'),

                  // Service Providers
                  _buildSectionTitle('Service Providers'),
                  _buildParagraph(
                      'We may employ third party companies and individuals to facilitate our App ("Service Providers"), to provide the App on our behalf, to perform App-related services or to assist us in analyzing how our App is used.'),
                  _buildParagraph(
                      'These third parties have access to your Personal Data only to perform these tasks on our behalf and are obligated not to disclose or use it for any other purpose.'),

                  // Links to Other Sites
                  _buildSectionTitle('Links to Other Sites'),
                  _buildParagraph(
                      'Our App may contain links to other sites that are not operated by us. If you click on a third party link, you will be directed to that third party\'s site. We strongly advise you to review the Privacy Policy of every site you visit.'),
                  _buildParagraph(
                      'We have no control over and assume no responsibility for the content, privacy policies or practices of any third party sites or services.'),

                  // Children's Privacy
                  _buildSectionTitle('Children\'s Privacy'),
                  _buildParagraph(
                      'Our App does not address anyone under the age of 18 ("Children").'),
                  _buildParagraph(
                      'We do not knowingly collect personally identifiable information from anyone under the age of 18. If you are a parent or guardian and you are aware that your Children has provided us with Personal Data, please contact us. If we become aware that we have collected Personal Data from children without verification of parental consent, we take steps to remove that information from our servers.'),

                  // Changes to This Privacy Policy
                  _buildSectionTitle('Changes to This Privacy Policy'),
                  _buildParagraph(
                      'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.'),
                  _buildParagraph(
                      'We will let you know via email and/or a prominent notice on our App, prior to the change becoming effective and update the "effective date" at the top of this Privacy Policy.'),
                  _buildParagraph(
                      'You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.'),

                  // Contact Us
                  _buildSectionTitle('Contact Us'),
                  _buildParagraph(
                      'If you have any questions about this Privacy Policy, please contact us:'),
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
                        text: 'Accept Privacy Policy',
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
          color: BrandColors.darkGray,
        ),
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: BrandColors.darkGray,
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
          color: BrandColors.darkGray,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: BrandColors.darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: BrandColors.darkGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
