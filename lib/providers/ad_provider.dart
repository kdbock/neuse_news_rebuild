// filepath: /Users/kristybock/neuse_news_rebuild/lib/providers/ad_provider.dart
import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../config/environment_config.dart';

/// Provider for managing advertisements
class AdProvider extends ChangeNotifier {
  final AdService _adService;
  bool _adsEnabled = true;
  bool _isLoading = false;
  bool _hasRemovedAds = false;
  
  AdProvider(this._adService) {
    _initialize();
  }

  /// Whether ads are enabled
  bool get adsEnabled => _adsEnabled && !_hasRemovedAds;
  
  /// Whether ads are currently loading
  bool get isLoading => _isLoading;
  
  /// Whether user has purchased ad removal
  bool get hasRemovedAds => _hasRemovedAds;

  /// Initialize and load ads
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if user has purchased ad removal
      _hasRemovedAds = await _adService.checkAdRemovalStatus();
      
      // Initialize ad system if ads should be shown
      if (!_hasRemovedAds) {
        await _adService.initialize();
      }
      
      _adsEnabled = EnvironmentConfig.adTrackingEnabled && !_hasRemovedAds;
    } catch (e) {
      debugPrint('Error initializing ads: $e');
      _adsEnabled = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a banner ad
  Future<Map<String, dynamic>?> loadBannerAd(String position) async {
    if (!adsEnabled) return null;
    
    try {
      final adData = await _adService.getBannerAd(position);
      return adData;
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      return null;
    }
  }

  /// Load a native ad
  Future<Map<String, dynamic>?> loadNativeAd(String position) async {
    if (!adsEnabled) return null;
    
    try {
      final adData = await _adService.getNativeAd(position);
      return adData;
    } catch (e) {
      debugPrint('Error loading native ad: $e');
      return null;
    }
  }

  /// Track ad impression
  Future<void> trackImpression(String adId) async {
    if (!adsEnabled) return;
    
    try {
      await _adService.trackImpression(adId);
    } catch (e) {
      debugPrint('Error tracking ad impression: $e');
    }
  }

  /// Track ad click
  Future<void> trackClick(String adId) async {
    if (!adsEnabled) return;
    
    try {
      await _adService.trackClick(adId);
    } catch (e) {
      debugPrint('Error tracking ad click: $e');
    }
  }

  /// Update ad removal status after purchase
  Future<void> updateAdRemovalStatus(bool removed) async {
    _hasRemovedAds = removed;
    notifyListeners();
    
    if (removed) {
      await _adService.disableAds();
    } else {
      await _initialize();
    }
  }

  /// Refresh available ads
  Future<void> refreshAds() async {
    if (!adsEnabled) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _adService.refreshAds();
    } catch (e) {
      debugPrint('Error refreshing ads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
