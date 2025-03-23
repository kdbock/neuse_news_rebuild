import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/brand_colors.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleURL;
  const ArticleDetailScreen({super.key, required this.articleURL});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // For Android hybrid composition, uncomment the following line:
    // WebView.platform = SurfaceAndroidWebView();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.articleURL));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Article Detail"),
        backgroundColor: BrandColors.gold,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
