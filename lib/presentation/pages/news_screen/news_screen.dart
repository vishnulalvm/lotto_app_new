import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lotto_app/data/models/news_screen/news_model.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_bloc.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_event.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_state.dart';
import 'package:lotto_app/presentation/widgets/news_content_item.dart';

class ContentItem {
  final String id;
  final ContentType type;
  final NewsModel? newsModel;

  ContentItem({
    required this.id,
    required this.type,
    this.newsModel,
  });
}

class LotteryNewsScreen extends StatefulWidget {
  const LotteryNewsScreen({super.key});

  @override
  State<LotteryNewsScreen> createState() => _LotteryNewsScreenState();
}

class _LotteryNewsScreenState extends State<LotteryNewsScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;
  String? expandedNewsId;
  List<ContentItem> contentItems = [];

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

  List<ContentItem> _createMixedContent(List<NewsModel> newsList) {
    List<ContentItem> content = [];
    
    for (int i = 0; i < newsList.length; i++) {
      // Add news item
      content.add(ContentItem(
        id: 'news_${newsList[i].id}',
        type: ContentType.news,
        newsModel: newsList[i],
      ));
      
      // Add ad after every news item
      content.add(ContentItem(
        id: 'ad_$i',
        type: ContentType.ad,
      ));
    }
    
    return content;
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
      extendBodyBehindAppBar: true,
      appBar: _buildTransparentAppBar(theme),
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

  AppBar _buildTransparentAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () => context.go('/'),
        padding: EdgeInsets.zero,
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'NEWS SUMMARY',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontSize: 17,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
      titleSpacing: 0,
      centerTitle: false,
      actions: [
        BlocBuilder<NewsBloc, NewsState>(
          builder: (context, state) {
            if (state is NewsLoaded && state.news.isNotEmpty && contentItems.isNotEmpty) {
              return IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  if (currentPage < contentItems.length) {
                    final currentItem = contentItems[currentPage];
                    if (currentItem.type == ContentType.news && currentItem.newsModel != null) {
                      _shareNews(currentItem.newsModel!);
                    }
                  }
                },
                padding: EdgeInsets.zero,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
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
    contentItems = _createMixedContent(newsList);
    
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) => setState(() {
        currentPage = index;
        expandedNewsId = null;
      }),
      itemCount: contentItems.length,
      itemBuilder: (context, index) {
        final contentItem = contentItems[index];
        
        return NewsContentItem(
          key: ValueKey(contentItem.id),
          type: contentItem.type,
          newsModel: contentItem.newsModel,
          expandedNewsId: expandedNewsId,
          onToggleContent: _toggleFullContent,
          onShareNews: _shareNews,
          onLaunchUrl: _launchUrl,
        );
      },
    );
  }

}
