import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/presentation/pages/contact_us/contact_us.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class ClaimScreen extends StatelessWidget {
  const ClaimScreen({super.key});

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
              _buildClaimStepsCard(theme),
              const SizedBox(height: 20),
              _buildRequiredDocumentsCard(theme),
              const SizedBox(height: 20),
              _buildActionButtons(context, theme),
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
        onPressed: () => context.go('/'),
      ),
      title: Text(
        'claim_your_prize'.tr(),
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
              Icons.emoji_events,
              size: 48,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'congratulations'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'claim_steps_description'.tr(),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimStepsCard(ThemeData theme) {
    final steps = [
      {
        'title': 'verify_ticket'.tr(),
        'description': 'verify_ticket_description'.tr(),
        'icon': Icons.check_circle,
      },
      {
        'title': 'prize_collection_time'.tr(),
        'description': 'prize_collection_time_description'.tr(),
        'icon': Icons.timer,
      },
      {
        'title': 'where_to_claim'.tr(),
        'description': 'where_to_claim_description'.tr(),
        'icon': Icons.location_on,
      },
      {
        'title': 'tax_deduction'.tr(),
        'description': 'tax_deduction_description'.tr(),
        'icon': Icons.account_balance,
      }
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'claim_process'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...steps.map((step) => _buildStepItem(step, theme)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(Map<String, dynamic> step, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step['icon'] as IconData,
              size: 24,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['description'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredDocumentsCard(ThemeData theme) {
    final documents = [
      'original_winning_ticket'.tr(),
      'two_passport_photos'.tr(),
      'id_proof'.tr(),
      'pan_card'.tr(),
      'bank_account_details'.tr(),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'required_documents'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...documents.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 20,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final url =
                Uri.parse('https://statelottery.kerala.gov.in/index.php');
            try {
              await launchUrl(url);
            } catch (e) {
              debugPrint('Could not launch lottery website: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('website_launch_error'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.language),
          label: Text('visit_kerala_lottery_website'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              )),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _showContactSheet(context),
          icon: const Icon(Icons.contact_support),
          label: Text('contact_support'.tr()),
        ),
      ],
    );
  }

  // Contact Bottom Sheet Implementation
  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ContactBottomSheet(),
    );
  }
}
