import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lotto_app/data/models/news_screen/news_model.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_bloc.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_event.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_state.dart';

class LotteryNewsScreen extends StatefulWidget {
  const LotteryNewsScreen({super.key});

  @override
  State<LotteryNewsScreen> createState() => _LotteryNewsScreenState();
}

class _LotteryNewsScreenState extends State<LotteryNewsScreen> {
  String? expandedNewsId;

  @override
  void initState() {
    super.initState();
    // Load news data
    context.read<NewsBloc>().add(LoadNewsEvent());
  }

  void _toggleExpansion(String newsId) {
    setState(() {
      expandedNewsId = expandedNewsId == newsId ? null : newsId;
    });
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('news'.tr()),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => context.read<NewsBloc>().add(RefreshNewsEvent()),
          ),
        ],
      ),
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor,
              ),
            );
          } else if (state is NewsError) {
            return _buildErrorState(theme, state.error);
          } else if (state is NewsLoaded) {
            if (state.news.isEmpty) {
              return _buildEmptyState(theme);
            }
            return _buildNewsList(theme, state.news);
          }
          
          return Center(
            child: Text(
              'No news available',
              style: theme.textTheme.bodyLarge,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load news',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<NewsBloc>().add(LoadNewsEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No news available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for the latest news',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList(ThemeData theme, List<NewsModel> newsList) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NewsBloc>().add(RefreshNewsEvent());
        // Wait for the refresh to complete
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: newsList.length,
        itemBuilder: (context, index) {
          final news = newsList[index];
          final isExpanded = expandedNewsId == news.id.toString();
          
          return _buildNewsCard(theme, news, isExpanded);
        },
      ),
    );
  }

  Widget _buildNewsCard(ThemeData theme, NewsModel news, bool isExpanded) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (news.hasValidImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.network(
                  news.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: theme.disabledColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.primaryColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Text(
                  news.headline,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Source and time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      news.formattedPublishedDate,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.source,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        news.source,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Content with expansion
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isExpanded ? news.content : news.shortContent,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
                
                // Expand/Collapse button
                if (news.content.length > 100)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () => _toggleExpansion(news.id.toString()),
                      child: Text(
                        isExpanded ? 'show_less'.tr() : 'read_more'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Visit website button
                if (news.hasValidNewsUrl)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(news.newsUrl),
                      icon: Icon(Icons.open_in_browser),
                      label: Text('visit_website'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add expansion overlay for better UX
class NewsExpansionOverlay extends StatelessWidget {
  final Widget child;
  final bool isExpanded;
  final VoidCallback onTap;

  const NewsExpansionOverlay({
    super.key,
    required this.child,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isExpanded)
          GestureDetector(
            onTap: onTap,
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}