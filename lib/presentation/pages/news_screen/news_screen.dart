import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LotteryNewsScreen extends StatefulWidget {
  const LotteryNewsScreen({super.key});

  @override
  State<LotteryNewsScreen> createState() => _LotteryNewsScreenState();
}

class _LotteryNewsScreenState extends State<LotteryNewsScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<Map<String, dynamic>> newsItems = [
    {
      'title': 'Kerala Lottery: Akshaya AK-620 result declared',
      'description': 'The first prize worth Rs 70 lakhs has been won by ticket number AY 197092 from Thrissur.',
      'source': 'Kerala Lottery',
      'timeAgo': '2 hours ago',
      'images': ['assets/images/four.jpeg'],
      'relatedTopic': 'View Full Result',
      'relatedImage': 'assets/images/four.jpeg'
    },
    {
      'title': 'Win Win W-755 lottery: Draw on Monday',
      'description': 'The Kerala lottery department will conduct Win Win W-755 lottery draw on Monday at 3 PM.',
      'source': 'Kerala Lottery',
      'timeAgo': '5 hours ago',
      'images': ['assets/images/four.jpeg'],
      'relatedTopic': 'Buy Ticket',
      'relatedImage': 'assets/images/four.jpeg'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) => setState(() => currentPage = index),
            itemCount: newsItems.length,
            itemBuilder: (context, index) => _buildNewsPage(newsItems[index], theme),
          ),
          _buildOverlayButtons(theme),
        ],
      ),
    );
  }

  Widget _buildNewsPage(Map<String, dynamic> news, ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: news['images'].length,
          itemBuilder: (context, index) => Image.asset(
            news['images'][index],
            fit: BoxFit.cover,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
                Colors.black,
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news['title'],
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                news['description'],
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.white60),
                  const SizedBox(width: 4),
                  Text(
                    news['timeAgo'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Source: ${news['source']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: InkWell(
            onTap: () {
              if (news['relatedTopic'] == 'View Full Result') {
                context.push('/result/details');
              } else if (news['relatedTopic'] == 'Buy Ticket') {
                context.push('/ticket/buy');
              }
            },
            child: _buildRelatedTopicCard(news, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedTopicCard(Map<String, dynamic> news, ThemeData theme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            news['relatedTopic'] == 'View Full Result' 
                ? Icons.article_outlined
                : Icons.shopping_cart_outlined,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            news['relatedTopic'],
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.primaryColor,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            color: theme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildOverlayButtons(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.bookmark_border, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}