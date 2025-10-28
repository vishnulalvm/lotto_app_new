import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/helpers/feedback_helper.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(theme),
              const SizedBox(height: 20),
              _buildTutorialCard(
                context,
                theme,
                'guessing_tutorial'.tr(),
                Icons.games_outlined,
                'https://youtu.be/Odc0kvjWCSs',
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildTutorialCard(
                context,
                theme,
                'result_tutorial'.tr(),
                Icons.receipt_long,
                'https://youtube.com/shorts/-C-Ov-fYrME?feature=share',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildTutorialCard(
                context,
                theme,
                'statistics_tutorial'.tr(),
                Icons.bar_chart_outlined,
                'https://youtube.com/shorts/kssNz_54RQI?feature=share',
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildTutorialCard(
                context,
                theme,
                'scan_tutorial'.tr(),
                Icons.qr_code_scanner,
                'https://youtube.com/shorts/gNDsGDOMXzo?feature=share',
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildTutorialCard(
                context,
                theme,
                'video_tutorial'.tr(),
                Icons.live_tv,
                'https://youtube.com/shorts/lZbjCI9y8so?feature=share',
                Colors.red,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme, BuildContext context) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.appBarTheme.iconTheme?.color,
        ),
        onPressed: () {
          FeedbackHelper.lightClick();
          context.go('/');
        },
      ),
      title: Text(
        'how_to_use'.tr(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.video_library,
              size: 48,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'tutorial_videos'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'tap_to_watch'.tr(),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialCard(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    String videoUrl,
    Color accentColor,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _launchVideo(context, videoUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon container with accent color
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'tap_to_watch'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Play button icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchVideo(BuildContext context, String videoUrl) async {
    // Add click feedback
    FeedbackHelper.lightClick();

    final url = Uri.parse(videoUrl);
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('could_not_open_video'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_opening_video'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
