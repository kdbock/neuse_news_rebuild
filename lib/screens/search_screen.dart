import 'package:flutter/material.dart';
import 'package:dart_rss/dart_rss.dart';
import 'package:provider/provider.dart';
import '../services/rss_service.dart';
import '../theme/brand_colors.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/header.dart';
import '../widgets/rss_item_cell.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _feedUrls = [
    'https://www.neusenews.com/index?format=rss',
    'https://www.neusenews.com/index/category/Local+News?format=rss',
    'https://www.neusenews.com/index/category/NC+News?format=rss',
    'https://www.neusenewssports.com/news-1?format=rss',
    'https://www.ncpoliticalnews.com/news?format=rss',
    'https://www.magicmilemedia.com/blog?format=rss',
  ];

  List<RssItem> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      SnackBarHelper.showInfoSnackBar(
        context,
        message: 'Please enter a search term',
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchQuery = query;
      _searchResults = [];
    });

    try {
      final rssService = Provider.of<RssService>(context, listen: false);
      final results = await rssService.searchContent(_feedUrls, query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });

        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Error searching articles: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(
            title: 'Search Articles',
            showDropdown: false,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search news articles...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(BrandColors.gold),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsFound();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return RSSItemCell(
          item: item,
          index: index,
          showAd: false,
        );
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for news articles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter keywords to find articles across all feeds',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No articles found matching "$_searchQuery"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _hasSearched = false;
              });
              _searchFocusNode.requestFocus();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try another search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.gold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
