import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class Header extends StatefulWidget {
  final String title;
  final bool showSearch;
  final bool showDropdown;
  final VoidCallback? onProfileTap;

  const Header({
    super.key,
    this.title = 'Neuse News',
    this.showSearch = true,
    this.showDropdown = true,
    this.onProfileTap,
  });

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool _showSearchBox = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Local News'; // Changed default to Local News

  // Removed "News Categories" entry as requested
  final List<DropdownMenuItem<String>> _newsCategories = [
    const DropdownMenuItem(value: 'Local News', child: Text('Local News')),
    const DropdownMenuItem(value: 'State News', child: Text('State News')),
    const DropdownMenuItem(value: 'Columns', child: Text('Columns')),
    const DropdownMenuItem(
        value: 'Matters of Record', child: Text('Matters of Record')),
    const DropdownMenuItem(value: 'Obituaries', child: Text('Obituaries')),
    const DropdownMenuItem(
        value: 'Public Notice', child: Text('Public Notice')),
    const DropdownMenuItem(value: 'Classifieds', child: Text('Classifieds')),
    const DropdownMenuItem(
        value: 'Community Calendar', child: Text('Community Calendar')),
    const DropdownMenuItem(value: 'Advertise', child: Text('Advertise')),
    const DropdownMenuItem(value: 'Weather', child: Text('Weather')),
  ];

  Map<String, String> get categoryUrls => {
        'Local News':
            'https://www.neusenews.com/index/category/Local+News?format=rss',
        'State News':
            'https://www.neusenews.com/index/category/NC+News?format=rss',
        'Columns':
            'https://www.neusenews.com/index/category/Columns?format=rss',
        'Matters of Record':
            'https://www.neusenews.com/index/category/Matters+of+Record?format=rss',
        'Obituaries':
            'https://www.neusenews.com/index/category/Obituaries?format=rss',
        'Public Notice':
            'https://www.neusenews.com/index/category/Public+Notices?format=rss',
        'Classifieds':
            'https://www.neusenews.com/index/category/Classifieds?format=rss',
        'Community Calendar': '', // Handled specially
        'Weather': '', // Handled specially
      };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCategoryChange(String? value) {
    if (value == null) return;

    setState(() {
      _selectedCategory = value;
    });

    if (value == 'Community Calendar') {
      Navigator.pushNamed(context, AppRoutes.calendar);
    } else if (value == 'Weather') {
      Navigator.pushNamed(context, AppRoutes.weather);
    } else if (value == 'Advertise') {
      // Handle advertise section
    } else if (categoryUrls.containsKey(value)) {
      Navigator.pushNamed(
        context,
        AppRoutes.rssFeed,
        arguments: {
          'feedURL': categoryUrls[value],
          'title': value,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main Header (3 columns)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: BrandColors.gold,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Left: Search Icon
                if (widget.showSearch)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearchBox = !_showSearchBox;
                      });
                    },
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                // Middle: Logo (centered)
                Expanded(
                  child: Center(
                    child: Image.asset(
                      ImageConstants.logoLong,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Right: Profile Icon
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                  onSelected: (String choice) {
                    switch (choice) {
                      case 'profile':
                        Navigator.pushNamed(context, AppRoutes.profile);
                        break;
                      case 'edit_profile':
                        Navigator.pushNamed(context, AppRoutes.editProfile);
                        break;
                      case 'submit_article':
                        // Handle in-app purchase
                        break;
                      case 'add_event':
                        // Handle in-app purchase
                        break;
                      case 'remove_ads':
                        // Handle in-app purchase
                        break;
                      case 'logout':
                        // Handle logout
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'profile',
                        child: Text('Profile'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit_profile',
                        child: Text('Edit Profile'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'submit_article',
                        child: Text('Submit Sponsored Article (\$75)'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'add_event',
                        child: Text('Add Community Event (\$25)'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'remove_ads',
                        child: Text('Remove Ads (\$5)'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),

        // Search box (if visible)
        if (_showSearchBox)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search articles...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Handle search
                    final query = _searchController.text;
                    if (query.isNotEmpty) {
                      // Perform search
                      _searchController.clear();
                      setState(() {
                        _showSearchBox = false;
                      });
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (value) {
                // Handle search
                if (value.isNotEmpty) {
                  // Perform search
                  _searchController.clear();
                  setState(() {
                    _showSearchBox = false;
                  });
                }
              },
            ),
          ),

        // Top Navigation (if enabled)
        if (widget.showDropdown)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                // Left: dropdown menu
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: BrandColors.gold),
                    style: const TextStyle(
                      color: BrandColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                    underline: Container(
                      height: 1,
                      color: BrandColors.gold,
                    ),
                    onChanged: _handleCategoryChange,
                    items: _newsCategories,
                  ),
                ),

                const SizedBox(width: 16),

                // Right: Order Classifieds Button
                OutlinedButton(
                  onPressed: () {
                    // Open classifieds order page in WebView
                    Navigator.pushNamed(
                      context,
                      AppRoutes.articleDetail,
                      arguments: {
                        'articleURL':
                            'https://www.neusenews.com/order-classifieds'
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandColors.gold,
                    side: const BorderSide(color: BrandColors.gold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Order Classifieds'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AppRoutes {
  static const String profile = '/profile';
  static const String editProfile = '/edit_profile';
  static const String rssFeed = '/rss_feed';
  static const String calendar = '/calendar'; // Added calendar route
  static const String weather = '/weather'; // Added weather route
  static const String articleDetail =
      '/article_detail'; // Added articleDetail route
  // Add other routes here
}

class ImageConstants {
  static const String logoLong = 'assets/images/logo_long.png';
  // Add other constants here
}
