import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
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
              'profile'.tr(),
              [
                _buildListTile(
                  'email'.tr(),
                  Icons.email_outlined,
                  subtitle: 'vishnulalvm007@gmail.com',
                  showArrow: false,
                ),
                _buildListTile(
                  'google'.tr(),
                  Icons.g_mobiledata,
                  trailing: Text(
                    'connected'.tr(),
                    style: TextStyle(color: Colors.grey),
                  ),
                  showArrow: false,
                ),
              ],
              theme,
            ),
            _buildSection(
              'about'.tr(),
              [
                _buildListTile('terms_of_use'.tr(), Icons.description_outlined),
                _buildListTile('privacy_policy'.tr(), Icons.privacy_tip_outlined),
                _buildListTile(
                  'check_for_updates'.tr(),
                  Icons.update,
                  trailing: Text(
                    '1.0.8(39)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
              theme,
            ),
            _buildSection(
              'app'.tr(),
              [
                _buildListTile(
                  'color_scheme'.tr(),
                  Icons.palette_outlined,
                  trailing: Text(
                    'system'.tr(),
                    style: TextStyle(color: Colors.grey),
                  ),
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
              ],
              theme,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildListTile(
                'contact_us'.tr(),
                Icons.contact_support_outlined,
              ),
            ),
            _buildActionButton(
              'log_out'.tr(),
              Icons.logout,
              onTap: () {},
              isDestructive: false,
              theme: theme,
            ),
            _buildActionButton(
              'delete_account'.tr(),
              Icons.delete_forever,
              onTap: () {},
              isDestructive: true,
              theme: theme,
            ),
          ],
        ),
      ),
    );
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
      default:
        return 'english'.tr();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('app_language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context,
                'english'.tr(),
                const Locale('en'),
              ),
              _buildLanguageOption(
                context,
                'malayalam'.tr(),
                const Locale('ml'),
              ),
              _buildLanguageOption(
                context,
                'hindi'.tr(),
                const Locale('hi'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageName,
    Locale locale,
  ) {
    final isSelected = context.locale == locale;
    return ListTile(
      title: Text(languageName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        context.setLocale(locale);
        Navigator.of(context).pop();
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
              top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
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
      onTap: onTap ?? () {},
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon, {
    required VoidCallback onTap,
    bool isDestructive = false,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor:
            isDestructive ? Colors.red.withOpacity(0.1) : theme.cardColor,
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}