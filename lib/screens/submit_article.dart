import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import '../theme/brand_colors.dart';
import '../utils/snackbar_helper.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/header.dart';
import '../models/user_role.dart'; // Add this line to import UserRole

class SubmitArticleScreen extends StatefulWidget {
  const SubmitArticleScreen({super.key});

  @override
  State<SubmitArticleScreen> createState() => _SubmitArticleScreenState();
}

class _SubmitArticleScreenState extends State<SubmitArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<File?> _imageFiles = [null, null];
  bool _isSubmitting = false;
  bool _isPurchasing = false;
  bool _showSuccessMessage = false;
  bool _hasAgreedToTerms = false;

  // In a real app, this would be tied to payment processor
  static const double articlePrice = 75.00;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFiles[index] = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Error selecting image: $e',
      );
    }
  }

  Future<void> _submitArticle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasAgreedToTerms) {
      SnackBarHelper.showWarningSnackBar(
        context,
        message: 'You must agree to the terms and conditions',
      );
      return;
    }

    if (_imageFiles[0] == null) {
      SnackBarHelper.showWarningSnackBar(
        context,
        message: 'Please upload at least one image',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate payment processing
      await _processSponsoredArticlePayment();

      // Check if widget is still mounted before accessing context
      if (!mounted) return;

      // Get current user
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.appUser;

      if (user == null) {
        throw Exception('You must be logged in to submit an article');
      }

      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      for (int i = 0; i < _imageFiles.length; i++) {
        if (_imageFiles[i] != null) {
          final imageRef = FirebaseStorage.instance
              .ref()
              .child('sponsored_articles')
              .child(
                  '${user.id}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');

          await imageRef.putFile(_imageFiles[i]!);
          final imageUrl = await imageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }

      // Submit to Firestore
      await FirebaseFirestore.instance.collection('sponsored_articles').add({
        'userId': user.id,
        'userEmail': user.email,
        'userName': user.displayName,
        'title': _titleController.text,
        'content': _contentController.text,
        'imageUrls': imageUrls,
        'status': 'pending', // pending, approved, rejected
        'submittedAt': FieldValue.serverTimestamp(),
        'paymentStatus': 'completed',
        'paymentAmount': articlePrice,
      });

      // Check if user is already advertiser, if not, upgrade
      if (user.role == UserRole.basic) {
        await authService.upgradeToAdvertiser();
      }

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _showSuccessMessage = true;
      });

      // Reset form after successful submission
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _imageFiles = [null, null];
        _hasAgreedToTerms = false;
      });
    } catch (e) {
      // Check if widget is still mounted before accessing context
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Error submitting article: $e',
      );
    }
  }

  Future<void> _processSponsoredArticlePayment() async {
    setState(() {
      _isPurchasing = true;
    });

    // Simulate payment process
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would integrate with in-app purchases
    // For iOS: StoreKit/In-App Purchase API
    // For Android: Google Play Billing Library
    // Or use a cross-platform solution like 'in_app_purchase' package

    // Check if widget is still mounted before updating state
    if (!mounted) return;

    setState(() {
      _isPurchasing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(
            title: 'Submit Sponsored Article',
            showDropdown: false,
          ),
          Expanded(
            child: _showSuccessMessage
                ? _buildSuccessView()
                : _buildSubmissionForm(),
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
              'Article Submitted Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your sponsored article has been submitted for review. Our team will review your submission and publish it soon.',
              style: TextStyle(
                fontSize: 16,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Submit Another Article',
              onPressed: () {
                setState(() {
                  _showSuccessMessage = false;
                });
              },
              variant: CustomButtonVariant.primary,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Return to Home',
              onPressed: () {
                Navigator.of(context).pop();
              },
              variant: CustomButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sponsored Article Info Card
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Sponsored Article Submission',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your sponsored article will be reviewed by our team before publication. The cost for submission is \$75.00.',
                        style: TextStyle(
                          fontSize: 14,
                          color: BrandColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
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
                                'Sponsored articles are marked as "Sponsored Content" when published and will appear in the news feed.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title
              const Text(
                'Article Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter a compelling title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Article title',
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Content
              const Text(
                'Article Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Write your article content here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => Validators.validateTextLength(
                  value,
                  min: 100,
                  max: 5000,
                ),
                maxLines: 10,
                maxLength: 5000,
              ),
              const SizedBox(height: 24),

              // Image Upload
              const Text(
                'Upload Images (2 max)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageUploader(0),
                  _buildImageUploader(1),
                ],
              ),
              const SizedBox(height: 24),

              // Terms and Conditions
              Row(
                children: [
                  Checkbox(
                    value: _hasAgreedToTerms,
                    onChanged: (bool? value) {
                      setState(() {
                        _hasAgreedToTerms = value ?? false;
                      });
                    },
                    activeColor: BrandColors.gold,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _hasAgreedToTerms = !_hasAgreedToTerms;
                        });
                      },
                      child: const Text(
                        'I agree to the terms and conditions for sponsored content submission. My content adheres to community standards and does not contain inappropriate material.',
                        style: TextStyle(
                          fontSize: 14,
                          color: BrandColors.darkGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isPurchasing
                      ? 'Processing Payment...'
                      : _isSubmitting
                          ? 'Submitting...'
                          : 'Submit and Pay \$75.00',
                  onPressed:
                      (_isSubmitting || _isPurchasing) ? null : _submitArticle,
                  isLoading: _isSubmitting || _isPurchasing,
                  variant: CustomButtonVariant.primary,
                  size: CustomButtonSize.large,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
          ),
        ),
        child: _imageFiles[index] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imageFiles[index]!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    index == 0 ? 'Main Image' : 'Second Image',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '(Tap to upload)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
