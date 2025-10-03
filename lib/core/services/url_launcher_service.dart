import 'package:url_launcher/url_launcher.dart';

/// Service for launching URLs with error handling
class URLLauncherService {
  static const String websiteUrl = 'https://lottokeralalotteries.com/';
  static const String whatsappGroupUrl =
      'https://chat.whatsapp.com/Lp7h3ft3I0xAsbGoLx9IW2?mode=ems_share_t';

  /// Launch website URL
  /// Returns true if successful, false otherwise
  static Future<bool> launchWebsite() async {
    return await _launchURL(websiteUrl);
  }

  /// Launch WhatsApp group URL
  /// Returns true if successful, false otherwise
  static Future<bool> launchWhatsAppGroup() async {
    return await _launchURL(whatsappGroupUrl);
  }

  /// Generic method to launch any URL
  static Future<bool> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);

      // Check if the URL can be launched
      final bool canLaunch = await canLaunchUrl(url);

      if (canLaunch) {
        // Force launch in external browser/app
        final bool launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        return launched;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
