import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';
import '../models/ad.dart';
import '../constants/ad_constants.dart';
import '../theme/brand_colors.dart';

enum AdBannerSize { small, medium, large }

enum AdBannerPosition { top, bottom, inline }

class AdBanner extends StatefulWidget {
  final AdBannerSize size;
  final AdBannerPosition position;
  final String adUnitId;
  final bool shouldRotate;

  const AdBanner({
    super.key,
    this.size = AdBannerSize.medium,
    this.position = AdBannerPosition.top,
    required this.adUnitId,
    this.shouldRotate = true,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  Ad? _currentAd;
  late final AdService _adService;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _adService = Provider.of<AdService>(context, listen: false);
    _loadAd();

    if (widget.shouldRotate) {
      // Set up ad rotation timer
      Future.delayed(
          const Duration(seconds: AdConstants.bannerAdRefreshInterval),
          _rotateAd);
    }
  }

  Future<void> _loadAd() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Load ad from service based on unit ID
      final ad = await _adService.getAdForUnit(widget.adUnitId);

      if (mounted) {
        setState(() {
          _currentAd = ad;
          _isLoading = false;
        });

        // Log impression
        if (ad != null) {
          _adService.logImpression(ad.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _rotateAd() {
    if (mounted && widget.shouldRotate) {
      _loadAd();
      // Schedule next rotation
      Future.delayed(
          const Duration(seconds: AdConstants.bannerAdRefreshInterval),
          _rotateAd);
    }
  }

  void _handleAdTap() async {
    if (_currentAd != null) {
      _adService.logClick(_currentAd!.id);

      // Launch the URL if available
      if (_currentAd!.url != null && _currentAd!.url!.isNotEmpty) {
        final url = Uri.parse(_currentAd!.url!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.inAppWebView);
        } else {
          debugPrint('Could not launch ${_currentAd!.url}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions based on size
    Size adSize;
    switch (widget.size) {
      case AdBannerSize.small:
        adSize = const Size(320, 50); // Standard small banner
        break;
      case AdBannerSize.medium:
        adSize = const Size(468, 60); // Medium rectangle
        break;
      case AdBannerSize.large:
        adSize = const Size(728, 90); // Large banner
        break;
    }

    if (_isLoading) {
      return Container(
        width: adSize.width,
        height: adSize.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
            ),
          ),
        ),
      );
    }

    if (_hasError || _currentAd == null) {
      return Container(
        width: adSize.width,
        height: adSize.height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            'Advertisement',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleAdTap,
      child: Container(
        width: adSize.width,
        height: adSize.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _currentAd!.imageUrl.isNotEmpty
            ? Stack(
                children: [
                  Image.network(
                    _currentAd!.imageUrl,
                    width: adSize.width,
                    height: adSize.height,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorPlaceholder(adSize);
                    },
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        // Fixed deprecated withOpacity
                        color: Colors.black.withAlpha(153), // 0.6 opacity
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'Ad',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _buildErrorPlaceholder(adSize),
      ),
    );
  }

  Widget _buildErrorPlaceholder(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      // Fixed deprecated withOpacity
      color: BrandColors.gold.withAlpha(51), // 0.2 opacity
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.ad_units,
              color: BrandColors.gold,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              _currentAd?.title ?? 'Advertisement',
              style: const TextStyle(
                color: BrandColors.darkGray,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
