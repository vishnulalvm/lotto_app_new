import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LotteryResultScreen extends StatelessWidget {
  const LotteryResultScreen({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(theme),
              const SizedBox(height: 20),
              _buildPrizeSection(theme),
              const SizedBox(height: 20),
              _buildContactSection(theme),
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
        icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
        onPressed: () => context.go('/'),
      ),
      title: Text(
        'Lottery Result',
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: theme.appBarTheme.actionsIconTheme?.color),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.bookmark_outline, color: theme.appBarTheme.actionsIconTheme?.color),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'X MAS NEW YEAR BUMPER LOTTERY',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Draw No:', 'BR-101', theme),
            _buildInfoRow('Draw Date:', '05/02/2025, 2:00 PM', theme),
            _buildInfoRow('Venue:', 'GORKY BHAVAN, THIRUVANANTHAPURAM', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeSection(ThemeData theme) {
    return Column(
      children: [
        _buildPrizeCard(
          theme,
          title: '1st Prize',
          amount: '₹20,00,00,000',
          winners: ['XD 387132 (KANNUR)'],
          consolation: [
            'XA 387132', 'XB 387132', 'XC 387132',
            'XE 387132', 'XG 387132', 'XH 387132',
          ],
        ),
        const SizedBox(height: 12),
        _buildPrizeCard(
          theme,
          title: '2nd Prize',
          amount: '₹1,00,00,000',
          winners: [
            'XA 571412 (THIRUVANANTHAPURAM)',
            'XB 289525 (ADIMALY)',
            'XB 325009 (PALAKKAD)',
          ],
        ),
        const SizedBox(height: 12),
        _buildLastDigitPrizeCard(theme),
      ],
    );
  }

  Widget _buildPrizeCard(
    ThemeData theme, {
    required String title,
    required String amount,
    required List<String> winners,
    List<String>? consolation,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...winners.map((winner) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                winner,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
            if (consolation != null) ...[
              const SizedBox(height: 12),
              Text(
                'Consolation Prize - ₹1,00,000',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: consolation.map((number) => Chip(
                  label: Text(number),
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastDigitPrizeCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Digit Prizes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLastDigitRow('6th Prize - ₹5,000', ['0089', '0425', '1108'], theme),
            _buildLastDigitRow('7th Prize - ₹2,000', ['0015', '0017', '0116'], theme),
            _buildLastDigitRow('8th Prize - ₹1,000', ['0126', '0189', '0218'], theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLastDigitRow(String title, List<String> numbers, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: numbers.map((number) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                number,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactRow(Icons.phone, 'Phone: 0471-2305230', theme),
            _buildContactRow(Icons.person, 'Director: 0471-2305193', theme),
            _buildContactRow(Icons.email, 'Email: cru.dir.lotteries@kerala.gov.in', theme),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Visit Official Website'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}