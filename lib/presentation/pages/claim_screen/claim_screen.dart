import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
        'Claim Your Prize',
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
              'Congratulations!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow these steps to claim your lottery prize',
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
        'title': 'Verify Your Ticket',
        'description':
            'Check your lottery ticket number against the official results on the Kerala Lottery website.',
        'icon': Icons.check_circle,
      },
      {
        'title': 'Prize Collection Time Frame',
        'description':
            'Submit your winning ticket within 30 days of the draw. After 30 days, tickets expire and prizes cannot be claimed.',
        'icon': Icons.timer,
      },
      {
        'title': 'Where to Claim',
        'description': 'For prizes up to ₹5,000: Claim at any lottery shop\n'
            'For prizes up to ₹1 Lakh: Claim at district lottery offices\n'
            'For prizes above ₹1 Lakh: Claim at Directorate of State Lotteries, Thiruvananthapuram',
        'icon': Icons.location_on,
      },
      {
        'title': 'Tax Deduction',
        'description':
            'For prizes above ₹10,000, Income Tax and Surcharge will be deducted at source as per government regulations.',
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
              'Claim Process',
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
      'Original winning ticket',
      'Two passport size photographs',
      'ID proof (Aadhaar/Voter ID/Driving License)',
      'PAN Card (for prizes above ₹10,000)',
      'Bank account details for prize transfer',
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
              'Required Documents',
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
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
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
          label: const Text('Visit Kerala Lottery Website'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.push('/contact'),
          icon: const Icon(Icons.contact_support),
          label: const Text('Contact Support'),
        ),
      ],
    );
  }
}
