import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:lotto_app/presentation/blocs/theme/theme_state.dart';
import 'package:lotto_app/presentation/pages/contact_us/contact_us.dart';
import 'package:lotto_app/presentation/pages/settings_screen/widgets/disclaimer_screen.dart';
import 'package:lotto_app/presentation/pages/settings_screen/widgets/color_theme_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/audio_service.dart';
import 'package:lotto_app/core/helpers/feedback_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEffectsEnabled = true;
  final AudioService _audioService = AudioService();
  
  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadSoundSettings();
    
    // Track screen view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        AnalyticsService.trackScreenView(
          screenName: 'settings_screen',
          screenClass: 'SettingsScreen',
          parameters: {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      });
    });
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    } catch (e) {
      // Handle error silently, use default value
    }
  }

  Future<void> _loadSoundSettings() async {
    setState(() {
      _soundEffectsEnabled = _audioService.isSoundEnabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(value ? 'enabling_notifications'.tr() : 'disabling_notifications'.tr()),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Update notification settings with Firebase
      bool success = await FirebaseMessagingService.updateNotificationSettings(value);

      if (success) {
        setState(() {
          _notificationsEnabled = value;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value ? 'notifications_enabled'.tr() : 'notifications_disabled'.tr(),
              ),
              backgroundColor: value ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_saving_settings'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_saving_settings'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleSoundEffects(bool value) async {
    // Play feedback when toggling (only if enabling)
    if (value) {
      FeedbackHelper.lightClick();
    }

    await _audioService.setSoundEnabled(value);
    setState(() {
      _soundEffectsEnabled = value;
    });
  }

  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('could_not_open_link'.tr())),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_opening_link'.tr())),
        );
      }
    }
  }

  void _checkForUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Replace with your actual latest version
      const latestVersion = '1.0.9';

      if (!mounted) return;

      if (currentVersion != latestVersion) {
        showDialog(
          context: context,
          useRootNavigator: false,
          builder: (context) => AlertDialog(
            title: Text('update_available'.tr()),
            content: Text('newer_version_available'.tr(namedArgs: {'version': latestVersion})),
            actions: [
              TextButton(
                child: Text('later'.tr()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('update_now'.tr()),
                onPressed: () {
                  Navigator.of(context).pop();
                  _launchUrl('https://play.google.com/store/apps/details?id=app.solidapps.lotto');
                },
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('latest_version_message'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_checking_updates'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: theme.appBarTheme.iconTheme?.color),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'profile'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'about'.tr(),
                    [
                      _buildListTile(
                        'terms_of_use'.tr(),
                        Icons.description_outlined,
                        onTap: () => _launchUrl(
                            'https://lotto-app-f3440.web.app/terms-conditions.html'),
                      ),
                      _buildListTile(
                        'privacy_policy'.tr(),
                        Icons.privacy_tip_outlined,
                        onTap: () => _launchUrl(
                            'https://lotto-app-f3440.web.app/privacy-policy.html'),
                      ),
                      _buildListTile(
                        'disclaimer'.tr(),
                        Icons.warning_amber_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DisclaimerScreen()),
                        ),
                      ),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.data?.version ?? 'loading'.tr();
                          final buildNumber = snapshot.data?.buildNumber ?? '';
                          final versionText = buildNumber.isNotEmpty ? '$version($buildNumber)' : version;
                          
                          return _buildListTile(
                            'check_for_updates'.tr(),
                            Icons.update,
                            trailing: Text(
                              versionText,
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: _checkForUpdate,
                          );
                        },
                      ),
                    ],
                    theme,
                  ),
                  _buildSection(
                    'app'.tr(),
                    [
                      BlocBuilder<ThemeCubit, ThemeState>(
                        builder: (context, themeState) {
                          return _buildListTile(
                            'color_scheme'.tr(),
                            Icons.palette_outlined,
                            trailing: Text(
                              _getThemeModeName(themeState.themeMode, context),
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => const ColorThemeDialog(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        'app_language'.tr(),
                        Icons.language,
                        trailing: Text(
                          _getCurrentLanguageName(context),
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () => _showLanguageDialog(context),
                      ),
                      _buildListTile(
                        'notifications'.tr(),
                        Icons.notifications_outlined,
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeThumbColor: theme.primaryColor,
                        ),
                        showArrow: false,
                        onTap: () => _toggleNotifications(!_notificationsEnabled),
                      ),
                      _buildListTile(
                        'sound_effects'.tr(),
                        Icons.volume_up_outlined,
                        trailing: Switch(
                          value: _soundEffectsEnabled,
                          onChanged: _toggleSoundEffects,
                          activeThumbColor: theme.primaryColor,
                        ),
                        showArrow: false,
                        onTap: () => _toggleSoundEffects(!_soundEffectsEnabled),
                      ),
                    ],
                    theme,
                  ),
                  _buildSection(
                    'lottery'.tr(),
                    [
                      _buildListTile(
                        'claim_lottery'.tr(),
                        Icons.emoji_events_outlined,
                        onTap: () => context.go('/claim'),
                      ),
                    ],
                    theme,
                  ),
                  _buildSection(
                    'support'.tr(),
                    [
                      _buildListTile(
                        'how_to_use'.tr(),
                        Icons.help_outline,
                        onTap: () => context.go('/how-to-use'),
                      ),
                      _buildListTile(
                        'contact_us'.tr(),
                        Icons.contact_support_outlined,
                        onTap: () => _showContactSheet(context),
                      ),
                    ],
                    theme,
                  ),
                                    // Company name at bottom center
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 16),
                      child: Text(
                        'SOLID APPS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ),


                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 16,
                  ), // Add padding for bottom navigation


                ],
              ),
            ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ContactBottomSheet(),
    );
  }

  String _getThemeModeName(ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light'.tr();
      case ThemeMode.dark:
        return 'dark'.tr();
      case ThemeMode.system:
        return 'system'.tr();
    }
  }

  String _getCurrentLanguageName(BuildContext context) {
    final currentLocale = context.locale;
    switch (currentLocale.languageCode) {
      case 'en':
        return 'english'.tr();
      case 'ml':
        return 'malayalam'.tr();
      case 'hi':
        return 'hindi'.tr();
      case 'ta': // Added Tamil support
        return 'tamil'.tr();
      default:
        return 'english'.tr();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('app_language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context,
                dialogContext,
                'English',
                const Locale('en'),
              ),
              _buildLanguageOption(
                context,
                dialogContext,
                'Malayalam',
                const Locale('ml'),
              ),
              _buildLanguageOption(
                context,
                dialogContext,
                'Hindi',
                const Locale('hi'),
              ),
              _buildLanguageOption(
                // Added Tamil option
                context,
                dialogContext,
                'Tamil',
                const Locale('ta'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('close'.tr()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    BuildContext dialogContext,
    String languageName,
    Locale locale,
  ) {
    final isSelected = context.locale == locale;
    return ListTile(
      title: Text(languageName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        FeedbackHelper.lightClick();
        context.setLocale(locale);
        Navigator.of(dialogContext).pop();
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
              bottom:
                  BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    String title,
    IconData icon, {
    String? subtitle,
    Widget? trailing,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ??
          (showArrow ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap != null
          ? () {
              FeedbackHelper.lightClick();
              onTap();
            }
          : null,
    );
  }
}
