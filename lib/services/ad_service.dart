// filepath: /Users/kristybock/neuse_news_rebuild/lib/services/ad_service.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../config/environment_config.dart';
import '../models/ad.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling advertisement operations
class AdService {
  final FirebaseService _firebaseService;
  final List<Ad> _bannerAds = [];
  final List<Ad> _nativeAds = [];
  bool _initialized = false;

  AdService(this._firebaseService);

  /// Initialize the ad service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _loadAds();
      _initialized = true;

      // Set up periodic refresh
      _setupPeriodicRefresh();
    } catch (e) {
      debugPrint('Error initializing ad service: $e');
      rethrow;
    }
  }

  /// Load ads from Firebase
  Future<void> _loadAds() async {
    try {
      // Clear existing ads
      _bannerAds.clear();
      _nativeAds.clear();

      // Load active ads from Firestore
      final ads = await _firebaseService.getActiveAds();

      // Sort into categories
      for (final ad in ads) {
        if (ad.type == AdType.banner) {
          _bannerAds.add(ad);
        } else if (ad.type == AdType.native) {
          _nativeAds.add(ad);
        }
      }
    } catch (e) {
      debugPrint('Error loading ads: $e');
      rethrow;
    }
  }

  /// Set up periodic ad refresh
  void _setupPeriodicRefresh() {
    final refreshIntervalSeconds = EnvironmentConfig.adRefreshInterval;

    Future.delayed(Duration(seconds: refreshIntervalSeconds), () {
      refreshAds();
      _setupPeriodicRefresh(); // Schedule next refresh
    });
  }

  /// Refresh ads from Firebase
  Future<void> refreshAds() async {
    try {
      await _loadAds();
    } catch (e) {
      debugPrint('Error refreshing ads: $e');
    }
  }

  /// Get a banner ad for a specific position
  Future<Map<String, dynamic>?> getBannerAd(String position) async {
    if (!_initialized) {
      await initialize();
    }

    // Filter banner ads for the requested position
    final positionAds = _bannerAds
        .where((ad) => ad.position == position && ad.isActive)
        .toList();

    if (positionAds.isEmpty) {
      return null;
    }

    // Select a random ad from those available for this position
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % positionAds.length;
    final selectedAd = positionAds[randomIndex];

    // Return ad data for display
    return {
      'id': selectedAd.id,
      'imageUrl': selectedAd.imageUrl,
      'clickUrl': selectedAd.clickUrl,
      'title': selectedAd.title,
      'advertiser': selectedAd.advertiser,
    };
  }

  /// Get a native ad for a specific position
  Future<Map<String, dynamic>?> getNativeAd(String position) async {
    if (!_initialized) {
      await initialize();
    }

    // Filter native ads for the requested position
    final positionAds = _nativeAds
        .where((ad) => ad.position == position && ad.isActive)
        .toList();

    if (positionAds.isEmpty) {
      return null;
    }

    // Select a random ad from those available for this position
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % positionAds.length;
    final selectedAd = positionAds[randomIndex];

    // Return ad data for display
    return {
      'id': selectedAd.id,
      'imageUrl': selectedAd.imageUrl,
      'clickUrl': selectedAd.clickUrl,
      'title': selectedAd.title,
      'description': selectedAd.description,
      'advertiser': selectedAd.advertiser,
    };
  }

  /// Track an ad impression
  Future<void> trackImpression(String adId) async {
    try {
      await _firebaseService.trackAdImpression(adId);
    } catch (e) {
      debugPrint('Error tracking ad impression: $e');
    }
  }

  /// Track an ad click
  Future<void> trackClick(String adId) async {
    try {
      await _firebaseService.trackAdClick(adId);
    } catch (e) {
      debugPrint('Error tracking ad click: $e');
    }
  }

  /// Check if user has purchased ad removal
  Future<bool> checkAdRemovalStatus() async {
    try {
      return await _firebaseService.hasUserRemovedAds();
    } catch (e) {
      debugPrint('Error checking ad removal status: $e');
      return false;
    }
  }

  /// Disable ads after purchase
  Future<void> disableAds() async {
    _initialized = false;
    _bannerAds.clear();
    _nativeAds.clear();
  }

  /// Get an ad for a specific unit ID
  Future<Ad?> getAdForUnit(String adUnitId) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Find ad type based on unit ID format
      final isNative = adUnitId.contains('native');
      final adList = isNative ? _nativeAds : _bannerAds;

      // Filter relevant ads - first check if there's an exact match for the unit
      final exactMatch = adList.where((ad) => ad.id == adUnitId).toList();
      if (exactMatch.isNotEmpty) {
        return exactMatch.first;
      }

      // Otherwise, find a position-based ad
      String position = _getPositionFromAdUnitId(adUnitId);
      final positionAds =
          adList.where((ad) => ad.position == position && ad.isActive).toList();

      if (positionAds.isEmpty) {
        return null;
      }

      // Select a random ad from those available for this position
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % positionAds.length;
      return positionAds[randomIndex];
    } catch (e) {
      debugPrint('Error getting ad for unit $adUnitId: $e');
      return null;
    }
  }

  /// Map ad unit ID to position
  String _getPositionFromAdUnitId(String adUnitId) {
    if (adUnitId.contains('splash')) {
      return 'splashScreen';
    } else if (adUnitId.contains('header')) {
      return 'feedHeader';
    } else if (adUnitId.contains('inline')) {
      return 'feedInline';
    } else if (adUnitId.contains('article_top')) {
      return 'articleTop';
    } else if (adUnitId.contains('article_bottom')) {
      return 'articleBottom';
    } else if (adUnitId.contains('classified')) {
      return 'classifiedsTop';
    } else if (adUnitId.contains('calendar')) {
      return 'calendarTop';
    } else if (adUnitId.contains('weather')) {
      return 'weatherTop';
    } else {
      return 'feedInline'; // Default position
    }
  }

  /// Log an ad impression
  Future<void> logImpression(String adId) async {
    try {
      await trackImpression(adId);
    } catch (e) {
      debugPrint('Error logging impression: $e');
    }
  }

  /// Log an ad click
  Future<void> logClick(String adId) async {
    try {
      await trackClick(adId);
    } catch (e) {
      debugPrint('Error logging click: $e');
    }
  }

  /// Get statistics about ads in the system
  Future<Map<String, dynamic>> getAdStats() async {
    try {
      // Default stats object
      final stats = {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'active': 0,
        'impressions': 0,
        'clicks': 0,
        'ctr': 0.0,
      };

      // Get total counts
      final adsSnapshot =
          await _firebaseService.firestore.collection('ads').get();
      stats['total'] = adsSnapshot.docs.length;

      // Count by status
      for (final doc in adsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';
        final isActive = data['isActive'] as bool? ?? false;
        final impressions = data['impressions'] as int? ?? 0;
        final clicks = data['clicks'] as int? ?? 0;

        // Increment counters
        stats['impressions'] = (stats['impressions'] as int) + impressions;
        stats['clicks'] = (stats['clicks'] as int) + clicks;

        // Increment status counts
        switch (status) {
          case 'pending':
            stats['pending'] = (stats['pending'] as int) + 1;
            break;
          case 'approved':
            stats['approved'] = (stats['approved'] as int) + 1;
            break;
          case 'rejected':
            stats['rejected'] = (stats['rejected'] as int) + 1;
            break;
        }

        // Count active ads
        if (isActive) {
          stats['active'] = (stats['active'] as int) + 1;
        }
      }

      // Calculate CTR if there are impressions
      if ((stats['impressions'] ?? 0) > 0) {
        stats['ctr'] =
            (stats['clicks'] as int) / (stats['impressions'] as int) * 100;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting ad stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'active': 0,
        'impressions': 0,
        'clicks': 0,
        'ctr': 0.0,
      };
    }
  }

  /// Get ads by status
  Future<List<Ad>> getAdsByStatus(String status) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('ads')
          .where('status', isEqualTo: status)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();

        // Add missing fields needed by the admin dashboard
        data['advertiserName'] = data['advertiser'] ?? 'Unknown';
        data['createdAt'] = data['createdAt'] ?? FieldValue.serverTimestamp();
        data['placement'] = data['position'] ?? 'Unknown';

        return Ad.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('Error getting ads by status: $e');
      return [];
    }
  }

  /// Update an ad
  Future<void> updateAd(String adId, Map<String, dynamic> updates) async {
    try {
      await _firebaseService.firestore
          .collection('ads')
          .doc(adId)
          .update(updates);
    } catch (e) {
      debugPrint('Error updating ad: $e');
      throw Exception('Failed to update ad: $e');
    }
  }

  /// Get all ads created by a specific advertiser
  Future<List<Ad>> getAdvertiserAds(String advertiserId) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('ads')
          .where('advertiser', isEqualTo: advertiserId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Ad.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting advertiser ads: $e');
      return [];
    }
  }

  /// Get detailed metrics for a specific ad
  Future<Map<String, dynamic>> getAdMetrics(String adId) async {
    try {
      // Get basic ad data
      final adDoc =
          await _firebaseService.firestore.collection('ads').doc(adId).get();

      if (!adDoc.exists) {
        return {
          'impressions': 0,
          'clicks': 0,
          'ctr': 0.0,
          'dailyStats': [],
        };
      }

      final adData = adDoc.data()!;

      // Get detailed metrics from adMetrics collection
      final metricsDoc = await _firebaseService.firestore
          .collection('adMetrics')
          .doc(adId)
          .get();

      final impressions = metricsDoc.exists
          ? (metricsDoc.data()?['impressions'] ?? adData['impressions'] ?? 0)
          : (adData['impressions'] ?? 0);

      final clicks = metricsDoc.exists
          ? (metricsDoc.data()?['clicks'] ?? adData['clicks'] ?? 0)
          : (adData['clicks'] ?? 0);

      // Calculate CTR
      final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0.0;

      // Get daily stats (last 7 days) if available
      List<Map<String, dynamic>> dailyStats = [];

      if (metricsDoc.exists && metricsDoc.data()?['dailyStats'] != null) {
        dailyStats =
            List<Map<String, dynamic>>.from(metricsDoc.data()!['dailyStats']);
      } else {
        // If no daily stats, create a placeholder with zeros
        final now = DateTime.now();
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          dailyStats.add({
            'date': DateFormat('MM/dd').format(date),
            'impressions': 0,
            'clicks': 0,
          });
        }
      }

      return {
        'impressions': impressions,
        'clicks': clicks,
        'ctr': ctr,
        'dailyStats': dailyStats,
      };
    } catch (e) {
      debugPrint('Error getting ad metrics: $e');
      return {
        'impressions': 0,
        'clicks': 0,
        'ctr': 0.0,
        'dailyStats': [],
      };
    }
  }
}
