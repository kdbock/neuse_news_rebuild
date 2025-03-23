import 'package:dart_rss/domain/rss_item.dart' as rss;

/// A model representing an RSS item
class RssItem {
  final String guid;
  final String title;
  final String description;
  final String? link;
  final String? author;
  final String? pubDate;
  final String? imageUrl;
  final List<String> categories;
  final Map<String, dynamic>? enclosure;

  RssItem({
    required this.guid,
    required this.title,
    required this.description,
    this.link,
    this.author,
    this.pubDate,
    this.imageUrl,
    this.categories = const [],
    this.enclosure,
  });

  /// Create an RssItem from the dart_rss library's RssItem
  factory RssItem.fromRssItem(rss.RssItem item) {
    return RssItem(
      guid: item.guid ?? item.link ?? DateTime.now().toIso8601String(),
      title: item.title ?? 'Untitled',
      description: item.description ?? '',
      link: item.link,
      author: item.author,
      pubDate: item.pubDate,
      imageUrl: _extractImageFromItem(item),
      categories:
          item.categories.map((c) => c.value).whereType<String>().toList(),
      enclosure: item.enclosure != null
          ? {
              'url': item.enclosure!.url,
              'type': item.enclosure!.type,
              'length': item.enclosure!.length,
            }
          : null,
    );
  }

  /// Extract image URL from an RSS item
  static String? _extractImageFromItem(rss.RssItem item) {
    // First check enclosure
    if (item.enclosure != null &&
        item.enclosure!.url != null &&
        item.enclosure!.type != null &&
        item.enclosure!.type!.startsWith('image/')) {
      return item.enclosure!.url;
    }

    // Then check media:content
    if (item.media != null && item.media!.contents.isNotEmpty) {
      for (final media in item.media!.contents) {
        if (media.url != null &&
            media.type != null &&
            media.type!.startsWith('image/')) {
          return media.url;
        }
      }
    }

    // Then try to extract from description (common in WordPress feeds)
    if (item.description != null) {
      final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
      final match = imgRegex.firstMatch(item.description!);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }
}

/// Model class for RSS media content
class RssMediaContent {
  final String? url;
  final String? type;
  final String? medium;
  final int? width;
  final int? height;

  RssMediaContent({this.url, this.type, this.medium, this.width, this.height});
}
