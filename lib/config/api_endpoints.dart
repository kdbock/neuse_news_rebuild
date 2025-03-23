// filepath: /Users/kristybock/neuse_news_rebuild/lib/config/api_endpoints.dart

/// API endpoints for the application
class ApiEndpoints {
  /// RSS feed endpoints
  static final rssFeeds = _RssFeeds();
}

/// RSS feed endpoints
class _RssFeeds {
  /// Main news feed
  String get news => 'https://www.neusenews.com/index?format=rss';

  /// Sports news feed
  String get sports => 'https://www.neusenewssports.com/news-1?format=rss';

  /// Political news feed
  String get political => 'https://www.ncpoliticalnews.com/news?format=rss';

  /// Business news feed
  String get business => 'https://www.magicmilemedia.com/blog?format=rss';

  /// Classifieds feed
  String get classifieds => 'https://www.neusenews.com/index/category/Classifieds?format=rss';

  /// Get feed URL by category
  String getCategory(String category) {
    switch (category.toLowerCase()) {
      case 'local news':
        return 'https://www.neusenews.com/index/category/Local+News?format=rss';
      case 'state news':
        return 'https://www.neusenews.com/index/category/NC+News?format=rss';
      case 'columns':
        return 'https://www.neusenews.com/index/category/Columns?format=rss';
      case 'matters of record':
        return 'https://www.neusenews.com/index/category/Matters+of+Record?format=rss';
      case 'obituaries':
        return 'https://www.neusenews.com/index/category/Obituaries?format=rss';
      case 'public notice':
        return 'https://www.neusenews.com/index/category/Public+Notices?format=rss';
      case 'classifieds':
        return classifieds;
      default:
        return news;
    }
  }

  /// Map of all feed URLs by source name
  Map<String, String> get allFeeds => {
    'news': news,
    'sports': sports,
    'political': political,
    'business': business,
    'classifieds': classifieds,
  };
}
