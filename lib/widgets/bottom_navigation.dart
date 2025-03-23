import 'package:flutter/material.dart';
import '../screens/rss_feed_screen.dart';
import '../theme/brand_colors.dart';
import '../constants/app_strings.dart';

class BottomNavigation extends StatefulWidget {
  final int initialIndex;

  const BottomNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  late int _currentIndex;
  final List<String> _feedUrls = [
    'https://www.neusenews.com/index?format=rss', // News
    'https://www.neusenewssports.com/news-1?format=rss', // Sports
    'https://www.ncpoliticalnews.com/news?format=rss', // Political
    'https://www.magicmilemedia.com/blog?format=rss', // Business
    'https://www.neusenews.com/index/category/Classifieds?format=rss', // Classifieds
  ];

  final List<String> _feedTitles = [
    AppStrings.news,
    AppStrings.sports,
    AppStrings.political,
    AppStrings.business,
    AppStrings.classifieds,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _feedUrls.length,
          (index) => RSSFeedScreen(
            feedURL: _feedUrls[index],
            title: _feedTitles[index],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: BrandColors.gold,
        unselectedItemColor: BrandColors.darkGray,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: AppStrings.news,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball_outlined),
            activeIcon: Icon(Icons.sports_basketball),
            label: AppStrings.sports,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote_outlined),
            activeIcon: Icon(Icons.how_to_vote),
            label: AppStrings.political,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_outlined),
            activeIcon: Icon(Icons.business_center),
            label: AppStrings.business,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: AppStrings.classifieds,
          ),
        ],
      ),
    );
  }
}
