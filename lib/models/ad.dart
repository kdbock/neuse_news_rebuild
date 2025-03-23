// filepath: /Users/kristybock/neuse_news_rebuild/lib/models/ad.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for different types of ads
enum AdType {
  banner,
  native,
  splash,
  interstitial,
}

/// Enum for different ad positions in the app
enum AdPosition {
  splashScreen,
  feedHeader,
  feedInline,
  articleTop,
  articleBottom,
  classifiedsTop,
  calendarTop,
  weatherTop,
}

/// Model representing an advertisement
class Ad {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String clickUrl;
  final String advertiser;
  final String position;
  final AdType type;
  final DateTime startDate;
  final DateTime endDate;
  final int impressions;
  final int clicks;
  final double ctr;
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final String? advertiserName;
  final DateTime? createdAt;
  final String? placement;
  final String? adUnitId; // Add this line

  Ad({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    required this.clickUrl,
    required this.advertiser,
    required this.position,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0.0,
    this.metadata,
    this.isActive = true,
    this.advertiserName,
    this.createdAt,
    this.placement,
    this.adUnitId, // Add this line
  });

  /// Create an Ad from a Firestore document
  factory Ad.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Ad(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      clickUrl: data['clickUrl'] ?? '',
      advertiser: data['advertiser'] ?? '',
      position: data['position'] ?? '',
      type: _parseAdType(data['type']),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      impressions: data['impressions'] ?? 0,
      clicks: data['clicks'] ?? 0,
      ctr: data['ctr']?.toDouble() ?? 0.0,
      metadata: data['metadata'],
      isActive: data['isActive'] ?? true,
      advertiserName: data['advertiserName'] ?? data['advertiser'] ?? 'Unknown',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      placement: data['placement'] ?? data['position'] ?? '',
    );
  }

  /// Create an Ad from a JSON object
  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'] ?? '',
      clickUrl: json['clickUrl'] ?? '',
      advertiser: json['advertiser'] ?? '',
      position: json['position'] ?? '',
      type: _parseAdType(json['type']),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      ctr: json['ctr']?.toDouble() ?? 0.0,
      metadata: json['metadata'],
      isActive: json['isActive'] ?? true,
      advertiserName: json['advertiserName'] ?? json['advertiser'] ?? 'Unknown',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      placement: json['placement'] ?? json['position'] ?? '',
      adUnitId: json['adUnitId'] ?? json['id'] ?? '', // Add this line
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'clickUrl': clickUrl,
      'advertiser': advertiser,
      'position': position,
      'type': type.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'impressions': impressions,
      'clicks': clicks,
      'ctr': ctr,
      'metadata': metadata,
      'isActive': isActive,
    };
  }

  /// Create a copy of this Ad with optional parameter overrides
  Ad copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? clickUrl,
    String? advertiser,
    String? position,
    AdType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? impressions,
    int? clicks,
    double? ctr,
    Map<String, dynamic>? metadata,
    bool? isActive,
    String? adUnitId, // Add this line
  }) {
    return Ad(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      clickUrl: clickUrl ?? this.clickUrl,
      advertiser: advertiser ?? this.advertiser,
      position: position ?? this.position,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      ctr: ctr ?? this.ctr,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      adUnitId: adUnitId ?? this.adUnitId, // Add this line
    );
  }

  /// Parse AdType from string
  static AdType _parseAdType(String? type) {
    switch (type) {
      case 'banner':
        return AdType.banner;
      case 'native':
        return AdType.native;
      case 'splash':
        return AdType.splash;
      case 'interstitial':
        return AdType.interstitial;
      default:
        return AdType.banner;
    }
  }

  /// Check if ad is currently valid based on dates
  bool get isValid {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// URL for the ad - shorthand for clickUrl
  String? get url => clickUrl;
}
