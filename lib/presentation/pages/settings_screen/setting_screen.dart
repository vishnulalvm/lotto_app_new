import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/services/theme_service.dart' as theme_service;
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_event.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_state.dart';
import 'package:lotto_app/presentation/blocs/color_theme/theme_bloc.dart';
import 'package:lotto_app/presentation/blocs/color_theme/theme_event.dart';
import 'package:lotto_app/presentation/blocs/color_theme/theme_state.dart';
import 'package:lotto_app/presentation/pages/contact_us/contact_us.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          context.go('/auth');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('logged_out_successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
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
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final isLoading = authState is AuthLoading;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'profile'.tr(),
                    [
                      FutureBuilder<String?>(
                        future: context
                            .read<AuthBloc>()
                            .repository
                            .getCurrentUser()
                            .then((user) => user?.name),
                        builder: (context, snapshot) {
                          return _buildListTile(
                            'user_name'.tr(),
                            Icons.person_outline,
                            subtitle: snapshot.data ?? 'loading'.tr(),
                            showArrow: false,
                          );
                        },
                      ),
                      FutureBuilder<String?>(
                        future: context
                            .read<AuthBloc>()
                            .repository
                            .getCurrentUser()
                            .then((user) => user?.phoneNumber),
                        builder: (context, snapshot) {
                          return _buildListTile(
                            'phone_number'.tr(),
                            Icons.phone_outlined,
                            subtitle: snapshot.data ?? 'loading'.tr(),
                            showArrow: false,
                          );
                        },
                      ),
                    ],
                    theme,
                  ),
                  _buildSection(
                    'about'.tr(),
                    [
                      _buildListTile(
                          'terms_of_use'.tr(), Icons.description_outlined),
                      _buildListTile(
                          'privacy_policy'.tr(), Icons.privacy_tip_outlined),
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
                      BlocBuilder<ThemeBloc, ThemeState>(
                        builder: (context, themeState) {
                          return _buildListTile(
                            'color_scheme'.tr(),
                            Icons.palette_outlined,
                            trailing: Text(
                              _getThemeModeName(themeState.themeMode, context),
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () =>
                                _showThemeDialog(context, themeState.themeMode),
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
                    ],
                    theme,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildListTile(
                      'contact_us'.tr(),
                      Icons.contact_support_outlined,
                      onTap: () => _showContactSheet(
                          context), // Updated to show bottom sheet
                    ),
                  ),
                  _buildActionButton(
                    'log_out'.tr(),
                    Icons.logout,
                    onTap: isLoading ? null : () => _showLogoutDialog(context),
                    isDestructive: false,
                    theme: theme,
                    isLoading: isLoading,
                  ),
                  _buildActionButton(
                    'delete_account'.tr(),
                    Icons.delete_forever,
                    onTap: isLoading
                        ? null
                        : () => _showDeleteAccountDialog(context),
                    isDestructive: true,
                    theme: theme,
                    isLoading: false,
                  ),
                ],
              ),
            );
          },
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

  String _getThemeModeName(
      theme_service.ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case theme_service.ThemeMode.light:
        return 'light'.tr();
      case theme_service.ThemeMode.dark:
        return 'dark'.tr();
      case theme_service.ThemeMode.system:
        return 'system'.tr();
    }
  }

  void _showThemeDialog(
      BuildContext context, theme_service.ThemeMode currentTheme) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return AlertDialog(
              title: Text('color_scheme'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeOption(
                    context,
                    'light'.tr(),
                    theme_service.ThemeMode.light,
                    themeState.themeMode, // Use current state from bloc
                    Icons.light_mode,
                    dialogContext,
                  ),
                  _buildThemeOption(
                    context,
                    'dark'.tr(),
                    theme_service.ThemeMode.dark,
                    themeState.themeMode, // Use current state from bloc
                    Icons.dark_mode,
                    dialogContext,
                  ),
                  _buildThemeOption(
                    context,
                    'system'.tr(),
                    theme_service.ThemeMode.system,
                    themeState.themeMode, // Use current state from bloc
                    Icons.settings_suggest,
                    dialogContext,
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
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String themeName,
    theme_service.ThemeMode themeMode,
    theme_service.ThemeMode currentTheme,
    IconData icon,
    BuildContext dialogContext,
  ) {
    final isSelected = currentTheme == themeMode;
    return ListTile(
      leading: Icon(icon),
      title: Text(themeName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        context.read<ThemeBloc>().add(ThemeChanged(themeMode));
        // Optional: Close dialog after selection
        // Navigator.of(dialogContext).pop();
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('confirm_logout'.tr()),
          content: Text('are_you_sure_logout'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('log_out'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('delete_account'.tr()),
          content: Text('delete_account_warning'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('delete_account_not_implemented'.tr()),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('delete'.tr()),
            ),
          ],
        );
      },
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
      case 'ta': // Added Tamil support
        return 'tamil'.tr();
      default:
        return 'english'.tr();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('App language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context,
                'English',
                const Locale('en'),
              ),
              _buildLanguageOption(
                context,
                'Malayalam',
                const Locale('ml'),
              ),
              _buildLanguageOption(
                context,
                'Hindi',
                const Locale('hi'),
              ),
              _buildLanguageOption(
                // Added Tamil option
                context,
                'Tamil',
                const Locale('ta'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'),
            ),
          ],
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
    required VoidCallback? onTap,
    bool isDestructive = false,
    required ThemeData theme,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor:
            isDestructive ? Colors.red.withOpacity(0.1) : theme.cardColor,
        leading: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDestructive ? Colors.red : theme.primaryColor,
                  ),
                ),
              )
            : Icon(icon, color: isDestructive ? Colors.red : null),
        title: Text(
          title,
          style: TextStyle(color: isDestructive ? Colors.red : null),
        ),
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
  }
}
