import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../theme/brand_colors.dart';
import '../utils/snackbar_helper.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/header.dart';

class SubmitNewsTipView extends StatefulWidget {
  const SubmitNewsTipView({super.key});

  @override
  State<SubmitNewsTipView> createState() => _SubmitNewsTipViewState();
}

class _SubmitNewsTipViewState extends State<SubmitNewsTipView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<File?> _imageFiles = [null, null];
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  bool _showSuccessMessage = false;
  bool _hasAgreedToTerms = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _locationController.dispose();
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
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Error selecting image: $e',
      );
    }
  }

  Future<void> _submitNewsTip() async {
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.appUser;

      if (user == null) {
        throw Exception('You must be logged in to submit a news tip');
      }

      // Upload images to Firebase Storage if provided
      List<String> imageUrls = [];
      for (int i = 0; i < _imageFiles.length; i++) {
        if (_imageFiles[i] != null) {
          final imageRef = FirebaseStorage.instance
              .ref()
              .child('news_tips')
              .child(
                  '${user.id}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');

          await imageRef.putFile(_imageFiles[i]!);
          final imageUrl = await imageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }

      // Submit to Firestore
      await FirebaseFirestore.instance.collection('news_tips').add({
        'userId': _isAnonymous ? null : user.id,
        'userEmail': _isAnonymous ? null : user.email,
        'userName': _isAnonymous ? 'Anonymous' : user.displayName,
        'title': _titleController.text,
        'details': _detailsController.text,
        'location': _locationController.text,
        'imageUrls': imageUrls,
        'isAnonymous': _isAnonymous,
        'status': 'pending', // pending, reviewed, published, rejected
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Also send email to info@neusenews.com
      // In a real app, you would implement a Cloud Function or server API for this

      setState(() {
        _isSubmitting = false;
        _showSuccessMessage = true;
      });

      // Reset form after successful submission
      _titleController.clear();
      _detailsController.clear();
      _locationController.clear();
      setState(() {
        _imageFiles = [null, null];
        _isAnonymous = false;
        _hasAgreedToTerms = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Error submitting news tip: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(
            title: 'Submit News Tip',
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
              'News Tip Submitted Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank you for your submission! Our editorial team will review your news tip.',
              style: TextStyle(
                fontSize: 16,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Submit Another Tip',
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
              // News Tip Info Card
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Submit a News Tip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Have a news story or information you think we should know about? Share it with our editorial team.',
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
                                'All submissions are reviewed by our editors. If we pursue your tip, someone may contact you for additional information.',
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
                'News Tip Title',
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
                  hintText: 'Brief description of the news tip',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'News tip title',
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Details
              const Text(
                'News Tip Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  hintText:
                      'Provide as much detail as possible about your news tip...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => Validators.validateTextLength(
                  value,
                  min: 50,
                  max: 2000,
                ),
                maxLines: 8,
                maxLength: 2000,
              ),
              const SizedBox(height: 16),

              // Location
              const Text(
                'Location (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'Where did this happen?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => null, // Optional field
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

              // Anonymous option
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    onChanged: (bool? value) {
                      setState(() {
                        _isAnonymous = value ?? false;
                      });
                    },
                    activeColor: BrandColors.gold,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAnonymous = !_isAnonymous;
                        });
                      },
                      child: const Text(
                        'Submit this news tip anonymously',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.darkGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_isAnonymous)
                Container(
                  margin: const EdgeInsets.only(left: 42, top: 8),
                  child: const Text(
                    'Note: Anonymous submissions make it more difficult for our team to verify information or request additional details.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
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
                        'I confirm that this information is accurate to the best of my knowledge and understand that it may be published.',
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
                  text: _isSubmitting ? 'Submitting...' : 'Submit News Tip',
                  onPressed: _isSubmitting ? null : _submitNewsTip,
                  isLoading: _isSubmitting,
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
                    index == 0 ? 'Primary Image' : 'Secondary Image',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '(optional)',
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
