import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../theme/brand_colors.dart';
import '../utils/snackbar_helper.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/header.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  File? _imageFile;
  bool _isSubmitting = false;
  bool _isPurchasing = false;
  bool _showSuccessMessage = false;
  bool _hasAgreedToTerms = false;

  // In a real app, this would be tied to payment processor
  static const double eventPrice = 25.00;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Error selecting image: $e',
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BrandColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BrandColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;

        // Automatically set end time to 2 hours later if start time is changed
        final int newHour = (_startTime.hour + 2) % 24;
        _endTime = TimeOfDay(hour: newHour, minute: _startTime.minute);
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BrandColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submitEvent() async {
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
      // Simulate payment processing
      await _processEventPayment();

      // Get current user
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.appUser;

      if (user == null) {
        throw Exception('You must be logged in to submit an event');
      }

      // Upload image to Firebase Storage if provided
      String? imageUrl;
      if (_imageFile != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('community_events')
            .child('${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await imageRef.putFile(_imageFile!);
        imageUrl = await imageRef.getDownloadURL();
      }

      // Combine date and time
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Submit to Firestore
      await FirebaseFirestore.instance.collection('community_events').add({
        'userId': user.id,
        'userEmail': user.email,
        'userName': user.displayName,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'startDateTime': Timestamp.fromDate(startDateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),
        'imageUrl': imageUrl,
        'contactName': _contactNameController.text,
        'contactEmail': _contactEmailController.text,
        'contactPhone': _contactPhoneController.text,
        'status': 'pending', // pending, approved, rejected
        'submittedAt': FieldValue.serverTimestamp(),
        'paymentStatus': 'completed',
        'paymentAmount': eventPrice,
      });

      setState(() {
        _isSubmitting = false;
        _showSuccessMessage = true;
      });

      // Reset form after successful submission
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _contactNameController.clear();
      _contactEmailController.clear();
      _contactPhoneController.clear();
      setState(() {
        _imageFile = null;
        _selectedDate = DateTime.now().add(const Duration(days: 7));
        _startTime = const TimeOfDay(hour: 9, minute: 0);
        _endTime = const TimeOfDay(hour: 12, minute: 0);
        _hasAgreedToTerms = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Error submitting event: $e',
      );
    }
  }

  Future<void> _processEventPayment() async {
    setState(() {
      _isPurchasing = true;
    });

    // Simulate payment process
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would integrate with in-app purchases
    // For iOS: StoreKit/In-App Purchase API
    // For Android: Google Play Billing Library
    // Or use a cross-platform solution like 'in_app_purchase' package

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
            title: 'Add Community Event',
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
              'Event Submitted Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your community event has been submitted for review. Our team will review your submission and publish it soon.',
              style: TextStyle(
                fontSize: 16,
                color: BrandColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Submit Another Event',
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
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Info Card
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Community Event Submission',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your community event will be reviewed before publication in our community calendar. The cost for submission is \$25.00.',
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
                                'Events will appear in the Community Calendar section and may be featured in the news feed.',
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

              // Event Title
              const Text(
                'Event Title',
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
                  hintText: 'Enter event title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Event title',
                ),
                maxLength: 80,
              ),
              const SizedBox(height: 16),

              // Event Description
              const Text(
                'Event Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Describe your event...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => Validators.validateTextLength(
                  value,
                  min: 30,
                  max: 1000,
                ),
                maxLines: 5,
                maxLength: 1000,
              ),
              const SizedBox(height: 24),

              // Event Date and Time
              const Text(
                'Event Date and Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFormat.format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: BrandColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectStartTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: BrandColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectEndTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Event Location
              const Text(
                'Event Location',
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
                  hintText: 'Enter event location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Event location',
                ),
              ),
              const SizedBox(height: 24),

              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactNameController,
                decoration: const InputDecoration(
                  hintText: 'Contact Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Contact name',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(
                  hintText: 'Contact Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) => Validators.validateEmail(value),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(
                  hintText: 'Contact Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) => Validators.validatePhone(value),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Event Image
              const Text(
                'Event Image (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
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
                              'Upload Event Image',
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
                        'I agree to the terms and conditions for event submission. My content adheres to community standards and does not contain inappropriate material.',
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
                          : 'Submit and Pay \$25.00',
                  onPressed:
                      (_isSubmitting || _isPurchasing) ? null : _submitEvent,
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
}
