import 'package:easy_localization/easy_localization.dart';
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
            'contact_us'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildContactOption(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'chat_with_us'.tr(),
            onTap: () => _launchWhatsApp('hello_assistance'.tr()),
            theme: theme,
          ),
          _buildContactOption(
            context,
            icon: Icons.phone_outlined,
            title: 'call_us'.tr(),
            onTap: () => _makePhoneCall('6238970003'),
            theme: theme,
          ),
          _buildContactOption(
            context,
            icon: Icons.feedback_outlined,
            title: 'send_feedback'.tr(),
            onTap: () => _launchWhatsApp('feedback_message'.tr()),
            theme: theme,
          ),
          _buildContactOption(
            context,
            icon: Icons.error_outline,
            title: 'report_problem'.tr(),
            onTap: () => _launchWhatsApp('report_problem_message'.tr()),
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
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.primaryColor,
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.of(context).pop(); // Close bottom sheet first
        onTap(); // Then execute the action
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
    }
  }

  Future<void> _launchWhatsApp(String message) async {
    final Uri whatsappUri = Uri.parse(
      'whatsapp://send?phone=+916238970003&text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(whatsappUri);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
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
