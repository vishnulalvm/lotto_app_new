import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// A reusable card widget for displaying statistics with numbers and counts.
///
/// This widget consolidates the functionality of:
/// - People Predictions Card
/// - Most Repeated Last 7 Days Card
/// - Most Repeated Last 2 Digits Card
class StatisticsCard extends StatelessWidget {
  /// Icon to display in the header
  final IconData icon;

  /// Color for the icon
  final Color iconColor;

  /// Title text for the card
  final String title;

  /// List of number data with 'number' and 'count' keys
  final List<Map<String, dynamic>> numberData;

  /// Border color for the number containers
  final Color borderColor;

  /// Translation key for the footer text (e.g., 'digits_found', 'two_digits_found')
  final String footerTranslationKey;

  /// Optional maximum number of items to display
  final int? maxItems;

  const StatisticsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.numberData,
    required this.borderColor,
    required this.footerTranslationKey,
    this.maxItems,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayData =
        maxItems != null ? numberData.take(maxItems!).toList() : numberData;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: theme.primaryColor,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),
            _buildNumbersRow(theme, displayData),
          ],
        ),
      ),
    );
  }

  /// Builds the header row with icon and title
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Builds the numbers row with counts and footer
  Widget _buildNumbersRow(
      ThemeData theme, List<Map<String, dynamic>> displayData) {
    final textColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        Row(
          children: displayData.map((data) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border.all(
                    color: borderColor,
                    width: .5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['number'],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: borderColor,
                            width: .5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'count_times'.tr(
                              namedArgs: {'count': data['count'].toString()}),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // _buildFooter(theme, displayData.length),
      ],
    );
  }

}
