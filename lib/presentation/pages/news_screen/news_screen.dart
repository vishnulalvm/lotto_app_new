import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // Add this dependency
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
  final PageController _pageController = PageController();
  int currentPage = 0;
  String? expandedNewsId;

  @override
  void initState() {
    super.initState();
    // Load news data
    context.read<NewsBloc>().add(LoadNewsEvent());
  }

  void _toggleFullContent(String newsId) {
    setState(() {
      if (expandedNewsId == newsId) {
        expandedNewsId = null;
      } else {
        expandedNewsId = newsId;
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareNews(NewsModel news) async {
    try {
      String shareText;
      
      if (news.hasValidNewsUrl) {
        // Share with URL if available
        shareText = '${news.headline}\n\n${news.newsUrl}';
      } else {
        // Share just the headline and content if no URL
        shareText = '${news.headline}\n\n${news.shortContent}';
      }

      await Share.share(
        shareText,
        subject: news.headline, // This is used for email sharing
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share the news'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading) {
            return _buildLoadingState();
          } else if (state is NewsError) {
            return _buildErrorState(theme, state.error);
          } else if (state is NewsLoaded) {
            if (state.news.isEmpty) {
              return _buildEmptyState(theme);
            }
            return _buildNewsContent(state.news, theme);
          }

          return _buildEmptyState(theme);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
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
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load news',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
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
              color: Colors.white60,
            ),
            const SizedBox(height: 16),
            Text(
              'No news available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for the latest news',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsContent(List<NewsModel> newsList, ThemeData theme) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: (index) => setState(() {
            currentPage = index;
            expandedNewsId = null;
          }),
          itemCount: newsList.length,
          itemBuilder: (context, index) =>
              _buildNewsPage(newsList[index], theme),
        ),
        _buildOverlayButtons(theme, newsList),
      ],
    );
  }

  Widget _buildNewsPage(NewsModel news, ThemeData theme) {
    final isExpanded = expandedNewsId == news.id.toString();

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

        // Gradient Overlay - More subtle when expanded
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

        // Content positioned at bottom with smooth text expansion
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: 0,
          child: GestureDetector(
            onTap: () => _toggleFullContent(news.id.toString()),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(16),
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
                          ? MediaQuery.of(context).size.height *
                              0.5 // Allow up to 50% of screen height
                          : 100, // Limited height when collapsed
                    ),
                    child: SingleChildScrollView(
                      physics: isExpanded
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          key: ValueKey('${news.id}-${isExpanded}'),
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

                  // Read more/less indicator with better visibility
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            key: ValueKey('indicator-${isExpanded}'),
                            isExpanded
                                ? 'Tap to show less'
                                : 'Tap to read more',
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

                  // Website button - always visible when URL is available
                  if (news.hasValidNewsUrl)
                    GestureDetector(
                      onTap: () => _launchUrl(news.newsUrl),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
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
                     const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayButtons(ThemeData theme, List<NewsModel> newsList) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go('/'),
                  ),
                  Text(
                    'LOTTO NEWS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      // Share the current news item
                      if (newsList.isNotEmpty && currentPage < newsList.length) {
                        _shareNews(newsList[currentPage]);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}