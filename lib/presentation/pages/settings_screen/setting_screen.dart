import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          'Profile',
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
              'Profile',
              [
                _buildListTile(
                  'Email',
                  Icons.email_outlined,
                  subtitle: 'vishnulalvm007@gmail.com',
                  showArrow: false,
                ),
                _buildListTile(
                  'Google',
                  Icons.g_mobiledata,
                  trailing:
                      Text('Connected', style: TextStyle(color: Colors.grey)),
                  showArrow: false,
                ),
              ],
              theme,
            ),
            _buildSection(
              'About',
              [
                _buildListTile('Terms of Use', Icons.description_outlined),
                _buildListTile('Privacy Policy', Icons.privacy_tip_outlined),
                _buildListTile(
                  'Check for updates',
                  Icons.update,
                  trailing:
                      Text('1.0.8(39)', style: TextStyle(color: Colors.grey)),
                ),
              ],
              theme,
            ),
            _buildSection(
              'App',
              [
                _buildListTile(
                  'Color Scheme',
                  Icons.palette_outlined,
                  trailing:
                      Text('System', style: TextStyle(color: Colors.grey)),
                ),
                _buildListTile(
                  'App Language',
                  Icons.language,
                  trailing:
                      Text('English', style: TextStyle(color: Colors.grey)),
                ),
              ],
              theme,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  _buildListTile('Contact us', Icons.contact_support_outlined),
            ),
            _buildActionButton('Log out', Icons.logout,
                onTap: () {}, isDestructive: false, theme: theme),
            _buildActionButton('Delete account', Icons.delete_forever,
                onTap: () {}, isDestructive: true, theme: theme),
          ],
        ),
      ),
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
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ??
          (showArrow ? Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: () {},
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
