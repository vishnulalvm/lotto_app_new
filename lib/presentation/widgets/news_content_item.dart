import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/models/news_screen/news_model.dart';
import 'package:lotto_app/presentation/widgets/native_ad_news_widget.dart';

enum ContentType { news, ad }

class NewsContentItem extends StatefulWidget {
  final ContentType type;
  final NewsModel? newsModel;
  final String? expandedNewsId;
  final Function(String)? onToggleContent;
  final Function(NewsModel)? onShareNews;
  final Function(String)? onLaunchUrl;

  const NewsContentItem({
    super.key,
    required this.type,
    this.newsModel,
    this.expandedNewsId,
    this.onToggleContent,
    this.onShareNews,
    this.onLaunchUrl,
  });

  @override
  State<NewsContentItem> createState() => _NewsContentItemState();
}

class _NewsContentItemState extends State<NewsContentItem> {
  @override
  Widget build(BuildContext context) {
    if (widget.type == ContentType.ad) {
      return const NativeAdNewsWidget();
    } else if (widget.type == ContentType.news && widget.newsModel != null) {
      return _buildNewsPage(widget.newsModel!, Theme.of(context));
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildNewsPage(NewsModel news, ThemeData theme) {
    final isExpanded = widget.expandedNewsId == news.id.toString();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        news.hasValidImage
            ? Image.network(
                news.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.white30,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[900],
                child: Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.white30,
                ),
              ),

        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isExpanded
                  ? [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black,
                    ]
                  : [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black,
                    ],
            ),
          ),
        ),

        // Content positioned at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: 0,
          child: GestureDetector(
            onTap: () => widget.onToggleContent?.call(news.id.toString()),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Title
                  Text(
                    news.headline,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Source and time
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text(
                        news.formattedPublishedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.source, size: 16, color: Colors.white60),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          news.source,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Content text with smooth expansion
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    constraints: BoxConstraints(
                      maxHeight: isExpanded
                          ? MediaQuery.of(context).size.height * 0.5
                          : 100,
                    ),
                    child: SingleChildScrollView(
                      physics: isExpanded
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          key: ValueKey('${news.id}-$isExpanded'),
                          isExpanded ? news.content : news.shortContent,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                            height: 1.6,
                          ),
                          maxLines: isExpanded ? null : 3,
                          overflow: isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Read more/less indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: theme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            key: ValueKey('indicator-$isExpanded'),
                            isExpanded ? 'Tap to show less' : 'Tap to read more',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Website button
                  if (news.hasValidNewsUrl)
                    GestureDetector(
                      onTap: () => widget.onLaunchUrl?.call(news.newsUrl),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_outward,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'visit_website'.tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}