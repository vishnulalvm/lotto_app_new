import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateUsDialog extends StatelessWidget {
  const RateUsDialog({super.key});

  static const String _rateUsShownKey = 'rate_us_shown';
  static const String _rateUsCountKey = 'rate_us_count';
  static const String _lastRateUsDateKey = 'last_rate_us_date';
  static const String _userRatedKey = 'user_rated';
  
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=app.solidapps.lotto';

  /// Check if we should show the rating dialog
  static Future<bool> shouldShowRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Don't show if user already rated
    final userRated = prefs.getBool(_userRatedKey) ?? false;
    if (userRated) return false;
    
    // Don't show if user clicked "Never" before
    final neverShow = prefs.getBool('rate_us_never_show') ?? false;
    if (neverShow) return false;
    
    final count = prefs.getInt(_rateUsCountKey) ?? 0;
    final lastShownStr = prefs.getString(_lastRateUsDateKey);
    
    // Show after every 5 back button presses
    if (count < 5) return false;
    
    // If we've shown before, wait at least 3 days
    if (lastShownStr != null) {
      final lastShown = DateTime.parse(lastShownStr);
      final daysSinceLastShown = DateTime.now().difference(lastShown).inDays;
      if (daysSinceLastShown < 3) return false;
    }
    
    return true;
  }

  /// Increment the back button count
  static Future<void> incrementBackButtonCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_rateUsCountKey) ?? 0;
    await prefs.setInt(_rateUsCountKey, count + 1);
  }

  /// Mark dialog as shown
  static Future<void> markDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rateUsShownKey, true);
    await prefs.setString(_lastRateUsDateKey, DateTime.now().toIso8601String());
    await prefs.setInt(_rateUsCountKey, 0); // Reset count
  }

  /// Mark user as rated
  static Future<void> markUserRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userRatedKey, true);
  }

  /// Mark as never show again
  static Future<void> markNeverShow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rate_us_never_show', true);
  }

  /// Show the rating dialog
  static Future<bool> show(BuildContext context) async {
    final shouldShow = await shouldShowRatingDialog();
    if (!shouldShow) return false;

    await markDialogShown();

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RateUsDialog(),
    );

    return result ?? false;
  }

  /// Launch Play Store
  static Future<void> _launchPlayStore() async {
    try {
      final Uri uri = Uri.parse(_playStoreUrl);
      final bool canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        await markUserRated();
      }
    } catch (e) {
      // Handle Play Store launch error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.star_rate_rounded,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'rate_us_title'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'rate_us_message'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyLarge?.color,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'rate_us_subtitle'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await markNeverShow();
            navigator.pop(false);
          },
          child: Text(
            'never'.tr(),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            'later'.tr(),
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
            await _launchPlayStore();
          },
          icon: Icon(
            Icons.star_rate_rounded,
            size: 18,
          ),
          label: Text(
            'rate_now'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}