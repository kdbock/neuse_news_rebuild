import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../constants/app_strings.dart';
import '../theme/brand_colors.dart';
import '../utils/validators.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _photoURL;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    // Populate form with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        setState(() {
          _photoURL = user.photoURL;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateProfile(displayName: _nameController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileUpdated)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.updateFailed}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Update UI with selected image
      setState(() {
        // For local images, use a File object
        // This is temporary - we'll need to upload to Firebase Storage
        _localImage = File(image.path);
      });

      // Then upload to Firebase Storage
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final photoURL = await authService.uploadProfilePhoto(_localImage!);

        if (photoURL != null) {
          setState(() {
            _photoURL = photoURL;
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        backgroundColor: BrandColors.gold,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: BrandColors.gold
                                .withAlpha(51), // 0.2 * 255 = 51
                            child: _photoURL != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.network(
                                      _photoURL!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          const Icon(Icons.person, size: 60),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 60),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: BrandColors.gold,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.name,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => Validators.validateName(value),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text(AppStrings.saveChanges),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(AppStrings.cancel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
