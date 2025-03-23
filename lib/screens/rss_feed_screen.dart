import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import '../models/rss_item.dart' as app;
import '../theme/brand_colors.dart';
import '../constants/app_routes.dart';

class RSSFeedScreen extends StatefulWidget {
  final String feedURL;
  final String title;

  const RSSFeedScreen({super.key, required this.feedURL, required this.title});

  @override
  State<RSSFeedScreen> createState() => _RSSFeedScreenState();
}

class _RSSFeedScreenState extends State<RSSFeedScreen> {
  List<app.RssItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRSSFeed();
  }

  Future<void> _fetchRSSFeed() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.get(Uri.parse(widget.feedURL));
      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);

        // Convert to app's RssItem model
        final items =
            feed.items.map((item) => app.RssItem.fromRssItem(item)).toList();

        if (mounted) {
          setState(() {
            _items = items;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load feed: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching RSS feed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading feed: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: BrandColors.white,
        foregroundColor: BrandColors.darkGray,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRSSFeed,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: BrandColors.gold,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load feed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRSSFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.gold,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('No items found in this feed'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRSSFeed,
      color: BrandColors.gold,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final imageUrl = _extractImageUrl(item);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.articleDetail,
                  arguments: {'articleURL': item.link},
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    if (imageUrl != null) const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.darkGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cleanDescription(item.description),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (item.pubDate != null)
                            Text(
                              _formatDate(DateTime.parse(item.pubDate!)),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _extractImageUrl(app.RssItem item) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return item.imageUrl;
    }

    final imgRegExp = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = imgRegExp.firstMatch(item.description);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  String _cleanDescription(String description) {
    // Remove HTML tags and decode HTML entities
    return description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
