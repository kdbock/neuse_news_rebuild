import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/rss_item.dart';
import '../services/rss_service.dart';
import '../utils/analytics_helper.dart';
import '../utils/local_storage.dart';
import '../config/api_endpoints.dart';
import '../config/environment_config.dart';

enum RssLoadingState {
  initial,
  loading,
  loaded,
  error,
  noConnection,
}

/// Provider for managing RSS feeds throughout the application
class RssProvider extends ChangeNotifier {
  // Modify constructor to accept RssService
  RssProvider([RssService? rssService]) {
    _rssService = rssService ?? RssService();
  }

  late final RssService _rssService;
  final AnalyticsHelper _analytics = AnalyticsHelper();
  final LocalStorage _localStorage = LocalStorage();

  // RSS data by category/source
  final Map<String, List<RssItem>> _rssItemsBySource = {};

  // Current selected categories
  String _currentSource = 'News';
  String? _currentCategory;

  // Loading state by source
  final Map<String, RssLoadingState> _loadingState = {};

  // Error messages by source
  final Map<String, String?> _errorMessages = {};

  // Last refresh time by source
  final Map<String, DateTime> _lastRefreshTime = {};

  // Favorite article IDs
  Set<String> _favoriteArticleIds = {};

  // Read article IDs
  Set<String> _readArticleIds = {};

  // Cache expiration time in minutes
  final int _cacheExpirationMinutes = EnvironmentConfig.cacheDuration;

  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = true;

  // Getters
  Map<String, List<RssItem>> get rssItemsBySource => _rssItemsBySource;
  String get currentSource => _currentSource;
  String? get currentCategory => _currentCategory;
  Map<String, RssLoadingState> get loadingState => _loadingState;
  Map<String, String?> get errorMessages => _errorMessages;
  Map<String, DateTime> get lastRefreshTime => _lastRefreshTime;
  Set<String> get favoriteArticleIds => _favoriteArticleIds;
  Set<String> get readArticleIds => _readArticleIds;
  bool get autoRefreshEnabled => _autoRefreshEnabled;

  /// Initialize the provider
  Future<void> initialize() async {
    await _localStorage.initialize();
    await _loadSavedPreferences();

    // Load the default feed
    await loadFeed(_currentSource);

    // Set up auto-refresh
    _setupAutoRefreshTimer();
  }

  /// Load saved preferences
  Future<void> _loadSavedPreferences() async {
    try {
      // Load favorite articles
      final savedFavorites = await _localStorage.getFavoriteArticles();
      if (savedFavorites != null) {
        _favoriteArticleIds = Set<String>.from(savedFavorites);
      }

      // Load read articles
      final savedRead = await _localStorage.getReadArticles();
      if (savedRead != null) {
        _readArticleIds = Set<String>.from(savedRead);
      }

      // Load last selected source and category
      final savedSource = await _localStorage.getValue('lastSource');
      if (savedSource != null) {
        _currentSource = savedSource;
      }

      final savedCategory = await _localStorage.getValue('lastCategory');
      if (savedCategory != null) {
        _currentCategory = savedCategory;
      }

      // Load auto-refresh setting
      final autoRefresh = await _localStorage.getValue('autoRefreshEnabled');
      if (autoRefresh != null) {
        _autoRefreshEnabled = autoRefresh == 'true';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved preferences: $e');
    }
  }

  /// Save current preferences
  Future<void> _savePreferences() async {
    try {
      await _localStorage.saveValue('lastSource', _currentSource);
      if (_currentCategory != null) {
        await _localStorage.saveValue('lastCategory', _currentCategory!);
      }
      await _localStorage.saveValue(
          'autoRefreshEnabled', _autoRefreshEnabled.toString());
      await _localStorage.saveFavoriteArticles(_favoriteArticleIds.toList());
      await _localStorage.saveReadArticles(_readArticleIds.toList());
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  /// Load RSS feed by source name
  Future<void> loadFeed(String source, {bool forceRefresh = false}) async {
    // Skip if already loading
    if (_loadingState[source] == RssLoadingState.loading) return;

    // Set loading state
    _loadingState[source] = RssLoadingState.loading;
    _errorMessages[source] = null;
    notifyListeners();

    try {
      // Try to load from cache first if not forcing refresh
      final bool hasFreshCache = !forceRefresh && _hasFreshCache(source);
      List<RssItem> items = [];

      if (hasFreshCache) {
        items = _rssItemsBySource[source] ?? [];
      }

      // If no fresh cache, load from service
      if (items.isEmpty) {
        // Get URL for the source
        final url = _getUrlForSource(source);
        if (url == null) {
          throw Exception('Invalid source: $source');
        }

        // Load from service
        items = (await _rssService.fetchRssFeed(url)).cast<RssItem>();

        // Update cache time
        _lastRefreshTime[source] = DateTime.now();
      }

      // Store items
      _rssItemsBySource[source] = items;

      // Set loading state to loaded
      _loadingState[source] = RssLoadingState.loaded;

      // Log analytics
      _analytics.logEvent('rss_feed_loaded', parameters: {
        'source': source,
        'item_count': items.length,
        'from_cache': hasFreshCache,
      });

      // Save current source as preference
      _currentSource = source;
      _currentCategory = null;
      await _savePreferences();

      notifyListeners();
    } catch (e) {
      // Set error state
      _loadingState[source] = _isNoConnectionError(e)
          ? RssLoadingState.noConnection
          : RssLoadingState.error;
      _errorMessages[source] = e.toString();

      // Log error
      _analytics.logEvent('rss_feed_error', parameters: {
        'source': source,
        'error': e.toString(),
      });

      notifyListeners();
    }
  }

  /// Load RSS feed by category
  Future<void> loadFeedByCategory(String category,
      {bool forceRefresh = false}) async {
    // Skip if already loading
    if (_loadingState[category] == RssLoadingState.loading) return;

    // Set loading state
    _loadingState[category] = RssLoadingState.loading;
    _errorMessages[category] = null;
    notifyListeners();

    try {
      // Try to load from cache first if not forcing refresh
      final bool hasFreshCache = !forceRefresh && _hasFreshCache(category);
      List<RssItem> items = [];

      if (hasFreshCache) {
        items = _rssItemsBySource[category] ?? [];
      }

      // If no fresh cache, load from service
      if (items.isEmpty) {
        // Get URL for the category
        final url = ApiEndpoints.rssFeeds.getCategory(category);

        // Load from service
        items = (await _rssService.fetchRssFeed(url)).cast<RssItem>();

        // Update cache time
        _lastRefreshTime[category] = DateTime.now();
      }

      // Store items
      _rssItemsBySource[category] = items;

      // Set loading state to loaded
      _loadingState[category] = RssLoadingState.loaded;

      // Log analytics
      _analytics.logEvent('rss_category_loaded', parameters: {
        'category': category,
        'item_count': items.length,
        'from_cache': hasFreshCache,
      });

      // Save current category as preference
      _currentCategory = category;
      _currentSource = 'Category';
      await _savePreferences();

      notifyListeners();
    } catch (e) {
      // Set error state
      _loadingState[category] = _isNoConnectionError(e)
          ? RssLoadingState.noConnection
          : RssLoadingState.error;
      _errorMessages[category] = e.toString();

      // Log error
      _analytics.logEvent('rss_category_error', parameters: {
        'category': category,
        'error': e.toString(),
      });

      notifyListeners();
    }
  }

  /// Refresh the current feed
  Future<void> refreshCurrentFeed() async {
    if (_currentCategory != null) {
      await loadFeedByCategory(_currentCategory!, forceRefresh: true);
    } else {
      await loadFeed(_currentSource, forceRefresh: true);
    }
  }

  /// Get items for the current source/category
  List<RssItem> getCurrentItems() {
    if (_currentCategory != null) {
      return _rssItemsBySource[_currentCategory!] ?? [];
    }
    return _rssItemsBySource[_currentSource] ?? [];
  }

  /// Get loading state for the current source/category
  RssLoadingState getCurrentLoadingState() {
    if (_currentCategory != null) {
      return _loadingState[_currentCategory!] ?? RssLoadingState.initial;
    }
    return _loadingState[_currentSource] ?? RssLoadingState.initial;
  }

  /// Get error message for the current source/category
  String? getCurrentErrorMessage() {
    if (_currentCategory != null) {
      return _errorMessages[_currentCategory!];
    }
    return _errorMessages[_currentSource];
  }

  /// Change the current source
  Future<void> changeSource(String source) async {
    if (_currentSource == source && _currentCategory == null) return;

    _currentSource = source;
    _currentCategory = null;
    notifyListeners();

    await loadFeed(source);
  }

  /// Change the current category
  Future<void> changeCategory(String category) async {
    if (_currentCategory == category) return;

    _currentCategory = category;
    notifyListeners();

    await loadFeedByCategory(category);
  }

  /// Toggle article favorite status
  Future<void> toggleFavorite(String articleId) async {
    if (_favoriteArticleIds.contains(articleId)) {
      _favoriteArticleIds.remove(articleId);

      // Log analytics
      _analytics.logEvent('article_unfavorited', parameters: {
        'article_id': articleId,
      });
    } else {
      _favoriteArticleIds.add(articleId);

      // Log analytics
      _analytics.logEvent('article_favorited', parameters: {
        'article_id': articleId,
      });
    }

    notifyListeners();
    await _savePreferences();
  }

  /// Mark article as read
  Future<void> markAsRead(String articleId) async {
    if (!_readArticleIds.contains(articleId)) {
      _readArticleIds.add(articleId);

      // Log analytics
      _analytics.logEvent('article_read', parameters: {
        'article_id': articleId,
      });

      notifyListeners();
      await _savePreferences();
    }
  }

  /// Check if article is favorited
  bool isFavorite(String articleId) {
    return _favoriteArticleIds.contains(articleId);
  }

  /// Check if article is read
  bool isRead(String articleId) {
    return _readArticleIds.contains(articleId);
  }

  /// Get favorite articles
  List<RssItem> getFavoriteArticles() {
    final List<RssItem> favorites = [];

    for (final source in _rssItemsBySource.keys) {
      final items = _rssItemsBySource[source] ?? [];
      for (final item in items) {
        if (_favoriteArticleIds.contains(item.guid)) {
          favorites.add(item);
        }
      }
    }

    return favorites;
  }

  /// Check if we have a fresh cache for the source
  bool _hasFreshCache(String source) {
    // Check if we have cached items
    final items = _rssItemsBySource[source];
    if (items == null || items.isEmpty) {
      return false;
    }

    // Check if cache is expired
    final lastRefresh = _lastRefreshTime[source];
    if (lastRefresh == null) {
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(lastRefresh).inMinutes;

    return difference < _cacheExpirationMinutes;
  }

  /// Toggle auto-refresh
  Future<void> toggleAutoRefresh() async {
    _autoRefreshEnabled = !_autoRefreshEnabled;

    if (_autoRefreshEnabled) {
      _setupAutoRefreshTimer();
    } else {
      _autoRefreshTimer?.cancel();
    }

    notifyListeners();
    await _savePreferences();
  }

  /// Set up auto-refresh timer
  void _setupAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();

    if (_autoRefreshEnabled) {
      // Refresh every hour
      _autoRefreshTimer = Timer.periodic(
        const Duration(minutes: 60),
        (_) => refreshCurrentFeed(),
      );
    }
  }

  /// Get URL for a named source
  String? _getUrlForSource(String source) {
    switch (source) {
      case 'News':
        return ApiEndpoints.rssFeeds.news;
      case 'Sports':
        return ApiEndpoints.rssFeeds.sports;
      case 'Political':
        return ApiEndpoints.rssFeeds.political;
      case 'Business':
        return ApiEndpoints.rssFeeds.business;
      case 'Classifieds':
        return ApiEndpoints.rssFeeds.classifieds;
      default:
        return ApiEndpoints.rssFeeds.allFeeds[source];
    }
  }

  /// Check if error is a network connectivity error
  bool _isNoConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection reset') ||
        errorString.contains('connection timed out') ||
        errorString.contains('no internet');
  }

  /// Search articles across all feeds
  List<RssItem> searchArticles(String query) {
    if (query.isEmpty) {
      return [];
    }

    final List<RssItem> results = [];
    final lowerCaseQuery = query.toLowerCase();

    for (final source in _rssItemsBySource.keys) {
      final items = _rssItemsBySource[source] ?? [];
      for (final item in items) {
        if (item.title.toLowerCase().contains(lowerCaseQuery) ||
            item.description.toLowerCase().contains(lowerCaseQuery)) {
          results.add(item);
        }
      }
    }

    // Log search
    _analytics.logEvent('article_search', parameters: {
      'query': query,
      'results_count': results.length,
    });

    return results;
  }

  /// Clear read articles history
  Future<void> clearReadHistory() async {
    _readArticleIds.clear();
    notifyListeners();
    await _savePreferences();

    // Log analytics
    _analytics.logEvent('read_history_cleared');
  }

  /// Clear favorite articles
  Future<void> clearFavorites() async {
    _favoriteArticleIds.clear();
    notifyListeners();
    await _savePreferences();

    // Log analytics
    _analytics.logEvent('favorites_cleared');
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
