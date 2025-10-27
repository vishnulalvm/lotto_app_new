import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter info legend
            _buildFilterLegend(theme),
            const SizedBox(height: 20),
            // Contact Information
            Text(
              'Contact Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactRow(Icons.phone, 'Phone: 0471-2305230', theme),
            _buildContactRow(Icons.person, 'Director: 0471-2305193', theme),
            _buildContactRow(
              Icons.email,
              'Email: cru.dir.lotteries@kerala.gov.in',
              theme,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _launchOfficialWebsite(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Visit Official Website',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 16),
            // Disclaimer section
            _buildDisclaimerSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterLegend(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.gamepad_outlined, size: 20,),
            const SizedBox(width: 8),
            Text(
              'Filter Guide (from guessing features)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterLegendItem(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              label: 'Matched Numbers from guessing',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildFilterLegendItem(
              icon: Icons.repeat,
              color: Colors.blue,
              label: 'Repeated Numbers from Last Draw',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildFilterLegendItem(
              icon: Icons.grid_view,
              color: Colors.yellow.shade700,
              label: 'Pattern Numbers Found',
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterLegendItem({
    required IconData icon,
    required Color color,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  Widget _buildDisclaimerSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Important Notice',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These results are manually entered from live TV broadcasts. While we strive for accuracy, there may be occasional errors during data entry. Please cross-check the results on the official government website for verification.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.amber[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchOfficialWebsite(BuildContext context) async {
    final Uri url = Uri.parse(
      'https://statelottery.kerala.gov.in/index.php/lottery-result-view',
    );

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Could not launch website'),
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Error opening website'),
        ),
      );
    }
  }
}
