import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactBottomSheet extends StatelessWidget {
  const ContactBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Contact Us',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildContactOption(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Chat with us',
            onTap: () => _launchWhatsApp('Hello, I need assistance'),
            theme: theme,
          ),
          _buildContactOption(
            context,
            icon: Icons.phone_outlined,
            title: 'Call us',
            onTap: () => _makePhoneCall('9876543210'),
            theme: theme,
          ),
          _buildContactOption(
            context,
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            onTap: () => _launchWhatsApp('I would like to give feedback about the app'),
            theme: theme,
          ),
          _buildContactOption(
            context,
            icon: Icons.error_outline,
            title: 'Report a Problem',
            onTap: () => _launchWhatsApp('I would like to report a problem'),
            theme: theme,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.primaryColor,
        ),
      ),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _launchWhatsApp(String message) async {
    final Uri whatsappUri = Uri.parse(
      'whatsapp://send?phone=+919876543210&text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(whatsappUri);
  }
}

// Show the bottom sheet:
void showContactSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const ContactBottomSheet(),
  );
}