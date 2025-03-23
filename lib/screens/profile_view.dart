import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/app_routes.dart';
import '../constants/app_strings.dart';
import '../theme/brand_colors.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        backgroundColor: BrandColors.gold,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: BrandColors.gold.withOpacity(0.2),
                      child: user?.photoURL != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.network(
                                user!.photoURL!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 60),
                              ),
                            )
                          : const Icon(Icons.person, size: 60),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user?.displayName ?? AppStrings.noName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? AppStrings.noEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.editProfile);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text(AppStrings.editProfile),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.bookmark_border),
                      title: const Text(AppStrings.savedArticles),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to saved articles
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications_none),
                      title: const Text(AppStrings.notifications),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to notifications settings
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text(AppStrings.logout),
                      onTap: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        await authService.signOut();

                        if (!mounted) return;
                        setState(() {
                          _isLoading = false;
                        });

                        Navigator.pushNamedAndRemoveUntil(
                            context, AppRoutes.login, (route) => false);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
