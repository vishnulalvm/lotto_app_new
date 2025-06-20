import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: _buildNotificationList(theme),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      title: Text(
        'Notifications',
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.appBarTheme.iconTheme?.color,
        ),
        onPressed: () => context.go('/'),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: theme.appBarTheme.actionsIconTheme?.color,
          ),
          onPressed: () {
            // Clear all notifications
          },
        ),
      ],
    );
  }

  Widget _buildNotificationList(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateHeader('Today', theme),
        const SizedBox(height: 8),
        _buildNotificationCard(
          theme,
          title: 'Akshaya AK 620 Result Out!',
          message: 'Check your ticket number.',
          time: '2 hours ago',
          icon: Icons.emoji_events,
          isNew: true,
        ),
        _buildNotificationCard(
          theme,
          title: 'Win Win W 755 Draw Today',
          message: 'Don\'t forget to check the results at 3 PM.',
          time: '5 hours ago',
          icon: Icons.access_time,
          isNew: true,
        ),
        const SizedBox(height: 24),
        _buildDateHeader('Yesterday', theme),
        const SizedBox(height: 8),
        _buildNotificationCard(
          theme,
          title: 'Your Saved Ticket',
          message: 'Reminder: Check WIN WIN W-754 ticket result.',
          time: '1 day ago',
          icon: Icons.bookmark,
        ),
        _buildNotificationCard(
          theme,
          title: 'Claim Prize Update',
          message: 'New procedure for claiming prizes above ₹1 Lakh.',
          time: '1 day ago',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 24),
        _buildDateHeader('This Week', theme),
        const SizedBox(height: 8),
        _buildNotificationCard(
          theme,
          title: 'Special Draw Announced',
          message: 'Monsoon Bumper 2024 tickets available now.',
          time: '2 days ago',
          icon: Icons.star_outline,
        ),
        _buildNotificationCard(
          theme,
          title: 'App Update Available',
          message: 'Update to get new features and improvements.',
          time: '3 days ago',
          icon: Icons.system_update,
        ),
      ],
    );
  }

  Widget _buildDateHeader(String date, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        date,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    ThemeData theme, {
    required String title,
    required String message,
    required String time,
    required IconData icon,
    bool isNew = false,
  }) {
    return Card(
      elevation: 0,
      color: isNew ? theme.primaryColor.withValues(alpha: 0.05) : theme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Handle notification tap
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'New',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}