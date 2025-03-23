import 'package:flutter/material.dart';
import 'package:dart_rss/dart_rss.dart';

class RSSItemCell extends StatelessWidget {
  final RssItem item;
  final int index;
  final bool showAd;
  final String? adUnitId;

  const RSSItemCell({
    super.key,
    required this.item,
    required this.index,
    this.showAd = false,
    this.adUnitId,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: item.enclosure?.url != null
          ? Image.network(
              item.enclosure!.url!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported),
            )
          : const Icon(Icons.article),
      title: Text(item.title ?? 'No title'),
      subtitle: Text(
        item.description ?? 'No description',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        // Handle item tap
        if (item.link != null) {
          Navigator.pushNamed(
            context,
            '/article-detail',
            arguments: {'articleURL': item.link},
          );
        }
      },
    );
  }
}
