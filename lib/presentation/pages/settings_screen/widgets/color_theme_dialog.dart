import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/core/services/theme_service.dart';
import 'package:lotto_app/presentation/blocs/theme/theme_cubit.dart';

class ColorThemeDialog extends StatefulWidget {
  const ColorThemeDialog({super.key});

  @override
  State<ColorThemeDialog> createState() => _ColorThemeDialogState();
}

class _ColorThemeDialogState extends State<ColorThemeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  AppColorScheme? _selectedColorScheme;
  ThemeMode? _selectedThemeMode;

  @override
  void initState() {
    super.initState();

    // Initialize with current theme settings
    final currentState = context.read<ThemeCubit>().state;
    _selectedColorScheme = currentState.colorScheme;
    _selectedThemeMode = currentState.themeMode;

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Responsive breakpoints
    final isVerySmallScreen = screenWidth < 300;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    // Responsive sizing
    final dialogPadding = isVerySmallScreen ? 12.0 : (isSmallScreen ? 16.0 : 24.0);
    final titleFontSize = isVerySmallScreen ? 16.0 : (isSmallScreen ? 18.0 : 22.0);
    final subtitleFontSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);
    final verticalSpacing = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);
    final sectionSpacing = isVerySmallScreen ? 8.0 : 12.0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? screenWidth * 0.95 : (isMediumScreen ? 400 : 500),
            maxHeight: screenHeight * 0.9,
          ),
          child: Padding(
            padding: EdgeInsets.all(dialogPadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Color & Theme',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sectionSpacing / 2),

                  // Subtitle
                  Text(
                    'Choose your preferred color and theme mode',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: subtitleFontSize,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: verticalSpacing),

                  // Color Selection Section
                  _buildSectionTitle('Colors', theme, isVerySmallScreen),
                  SizedBox(height: sectionSpacing),
                  _buildColorGrid(screenWidth),
                  SizedBox(height: verticalSpacing),

                  // Theme Mode Selection Section
                  _buildSectionTitle('Theme Mode', theme, isVerySmallScreen),
                  SizedBox(height: sectionSpacing),
                  _buildThemeModeSelection(theme, screenWidth),
                  SizedBox(height: verticalSpacing),

                  // Buttons
                  _buildActionButtons(isVerySmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, bool isVerySmall) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: isVerySmall ? 14 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorGrid(double screenWidth) {
    final theme = Theme.of(context);

    // Responsive sizing for color options
    final isVerySmall = screenWidth < 300;
    final isSmall = screenWidth < 360;
    final spacing = isVerySmall ? 6.0 : (isSmall ? 8.0 : 10.0);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      children: [
        _buildColorOption(AppColorScheme.blue, 'Blue', const Color(0xFF1565C0), theme, screenWidth),
        _buildColorOption(
          AppColorScheme.scarlet,
          'Crimson',
          const Color(0xFFEF5458),
          theme,
          screenWidth,
        ),
        _buildColorOption(
          AppColorScheme.green,
          'Green',
          const Color(0xFF2E7D32),
          theme,
          screenWidth,
        ),
        _buildColorOption(
          AppColorScheme.tigerOrange,
          'Tiger Orange',
          const Color(0xFFE65100),
          theme,
          screenWidth,
        ),
        _buildColorOption(
          AppColorScheme.caramel,
          'Caramel',
          const Color(0xFFB67233),
          theme,
          screenWidth,
        ),
        _buildColorOption(
          AppColorScheme.ocean,
          'Teal',
          const Color(0xFF075E54),
          theme,
          screenWidth,
        ),
        _buildColorOption(
          AppColorScheme.purple,
          'Purple',
          const Color(0xFF7B1FA2),
          theme,
          screenWidth,
        ),
        _buildColorOption(
          AppColorScheme.cyan,
          'Gray',
          const Color(0xFF546E7A),
          theme,
          screenWidth,
        ),
      ],
    );
  }

  Widget _buildColorOption(
    AppColorScheme colorScheme,
    String label,
    Color color,
    ThemeData theme,
    double screenWidth,
  ) {
    final isSelected = _selectedColorScheme == colorScheme;

    // Responsive sizing
    final isVerySmall = screenWidth < 300;
    final isSmall = screenWidth < 360;
    final circleSize = isVerySmall ? 40.0 : (isSmall ? 45.0 : 50.0);
    final iconSize = isVerySmall ? 24.0 : (isSmall ? 28.0 : 32.0);
    final fontSize = isVerySmall ? 9.0 : (isSmall ? 10.0 : 11.0);
    final borderWidth = isSelected ? (isVerySmall ? 2.5 : 3.0) : 1.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColorScheme = colorScheme;
        });
      },
      child: SizedBox(
        width: isVerySmall ? 50 : (isSmall ? 55 : 60),
        child: Column(
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: borderWidth,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: iconSize)
                  : null,
            ),
            SizedBox(height: isVerySmall ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.textTheme.bodyLarge?.color
                    : theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeSelection(ThemeData theme, double screenWidth) {
    final isVerySmall = screenWidth < 300;
    final isSmall = screenWidth < 360;
    final spacing = isVerySmall ? 6.0 : (isSmall ? 8.0 : 10.0);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      children: [
        _buildThemeModeCard(
          ThemeMode.system,
          'System',
          Icons.brightness_auto,
          theme,
          screenWidth,
        ),
        _buildThemeModeCard(
          ThemeMode.light,
          'Light',
          Icons.wb_sunny,
          theme,
          screenWidth,
        ),
        _buildThemeModeCard(
          ThemeMode.dark,
          'Dark',
          Icons.nightlight_round,
          theme,
          screenWidth,
        ),
      ],
    );
  }

  Widget _buildThemeModeCard(
    ThemeMode themeMode,
    String label,
    IconData icon,
    ThemeData theme,
    double screenWidth,
  ) {
    final isSelected = _selectedThemeMode == themeMode;

    // Responsive sizing
    final isVerySmall = screenWidth < 300;
    final isSmall = screenWidth < 360;
    final circleSize = isVerySmall ? 40.0 : (isSmall ? 45.0 : 50.0);
    final iconSize = isVerySmall ? 22.0 : (isSmall ? 25.0 : 28.0);
    final fontSize = isVerySmall ? 9.0 : (isSmall ? 10.0 : 11.0);
    final borderWidth = isSelected ? (isVerySmall ? 2.5 : 3.0) : 1.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedThemeMode = themeMode;
        });
      },
      child: SizedBox(
        width: isVerySmall ? 50 : (isSmall ? 55 : 60),
        child: Column(
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: borderWidth,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: iconSize,
              ),
            ),
            SizedBox(height: isVerySmall ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.textTheme.bodyLarge?.color
                    : theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isVerySmall) {
    if (isVerySmall) {
      // Stack buttons vertically on very small screens
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyTheme,
              child: const Text('Apply'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      );
    }

    // Side by side buttons for larger screens
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyTheme,
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }

  void _applyTheme() {
    if (_selectedColorScheme != null && _selectedThemeMode != null) {
      // Close dialog immediately for better perceived performance
      Navigator.of(context).pop();

      // Apply theme change after dialog closes
      context.read<ThemeCubit>().updateThemeSettings(
        colorScheme: _selectedColorScheme,
        themeMode: _selectedThemeMode,
      );
    }
  }
}
