// filepath: /Users/kristybock/neuse_news_rebuild/lib/services/rss_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import '../utils/analytics_helper.dart';
import '../utils/date_formatter.dart';

/// Service for fetching and parsing RSS feeds
class RssService {
  final _httpClient = http.Client();
  final _cache = <String, _CachedResponse>{};
  final _analyticsHelper = AnalyticsHelper();

  /// Fetch and parse an RSS feed from the given URL
  Future<List<RssItem>> fetchRssFeed(String url,
      {bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh &&
          _cache.containsKey(url) &&
          !_cache[url]!.isExpired()) {
        debugPrint('Using cached feed for $url');
        return _cache[url]!.items;
      }

      debugPrint('Fetching RSS feed from $url');
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load feed: ${response.statusCode}');
      }

      final feed = RssFeed.parse(response.body);

      // Cache the response
      _cache[url] = _CachedResponse(feed.items);

      // Log the feed fetch
      await _analyticsHelper.logEvent('fetch_rss_feed', parameters: {
        'url': url,
        'item_count': feed.items.length,
      });

      return feed.items;
    } catch (e) {
      debugPrint('Error fetching RSS feed: $e');
      rethrow;
    }
  }

  /// Search for content across feeds
  Future<List<RssItem>> searchContent(List<String> feeds, String query) async {
    final results = <RssItem>[];
    query = query.toLowerCase();

    for (final url in feeds) {
      try {
        final items = await fetchRssFeed(url);

        final matches = items.where((item) {
          final title = item.title?.toLowerCase() ?? '';
          final description = item.description?.toLowerCase() ?? '';

          return title.contains(query) || description.contains(query);
        }).toList();

        results.addAll(matches);
      } catch (e) {
        debugPrint('Error searching feed $url: $e');
      }
    }

    // Sort by date (newest first)
    results.sort((a, b) {
      final dateA = DateFormatter.parseRssDate(a.pubDate ?? '');
      final dateB = DateFormatter.parseRssDate(b.pubDate ?? '');
      return dateB.compareTo(dateA);
    });

    return results;
  }
}

/// Helper class for caching RSS responses
class _CachedResponse {
  final List<RssItem> items;
  final DateTime timestamp;
  final Duration validDuration;

  _CachedResponse(
    this.items, {
    Duration? validFor,
  })  : timestamp = DateTime.now(),
        validDuration = validFor ?? const Duration(minutes: 15);

  bool isExpired() {
    return DateTime.now().difference(timestamp) > validDuration;
  }
}
