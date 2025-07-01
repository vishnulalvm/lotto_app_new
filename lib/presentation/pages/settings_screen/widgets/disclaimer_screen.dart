import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.iconTheme?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'disclaimer'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App info header
          _buildHeaderCard(theme, context),
          const SizedBox(height: 16),
          
          // Disclaimer section
          _buildCard(
            theme: theme,
            icon: Icons.info_outline,
            iconColor: Colors.orange,
            title: 'disclaimer_title'.tr(),
            content: 'disclaimer_content'.tr(),
          ),
          const SizedBox(height: 16),
          
          // Prediction disclaimer
          _buildCard(
            theme: theme,
            icon: Icons.psychology_outlined,
            iconColor: Colors.purple,
            title: 'prediction_disclaimer_title'.tr(),
            content: 'prediction_disclaimer_content'.tr(),
          ),
          const SizedBox(height: 16),
          
          // Responsibility notice
          _buildCard(
            theme: theme,
            icon: Icons.security_outlined,
            iconColor: Colors.green,
            title: 'responsibility_title'.tr(),
            content: 'responsibility_content'.tr(),
          ),
          const SizedBox(height: 16),
          
          // Data source info
          _buildCard(
            theme: theme,
            icon: Icons.source_outlined,
            iconColor: Colors.blue,
            title: 'data_source_title'.tr(),
            content: 'data_source_content'.tr(),
          ),
          
          const SizedBox(height: 32),
          
          // Important notice footer
          _buildImportantNotice(theme, context),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/logo_foreground.png', // Updated logo path
                width: 80,
                height: 80,
            ),),
            const SizedBox(height: 12),
            Text(
              'lotto_app_title'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'app_version'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotice(ThemeData theme, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'important_notice'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'important_notice_content'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}