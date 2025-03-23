import 'package:flutter/material.dart';

/// A simplified SVG image widget when flutter_svg is causing compatibility issues
class SvgPlaceholder extends StatelessWidget {
  final String assetName;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const SvgPlaceholder({
    super.key,
    required this.assetName,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.transparent,
      child: Center(
        child: Icon(
          Icons.image,
          color: color ?? Colors.grey,
          size: width != null ? width! * 0.5 : 24,
        ),
      ),
    );
  }

  /// Factory constructor for creating from an asset
  static SvgPlaceholder asset(
    String assetName, {
    Key? key,
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPlaceholder(
      key: key,
      assetName: assetName,
      width: width,
      height: height,
      color: color,
      fit: fit,
    );
  }
}
