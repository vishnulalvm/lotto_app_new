import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_state.dart';

class ResultDetailsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String selectedFilter;
  final bool isSaved;
  final bool isGeneratingPdf;
  final Function(String) onFilterSelected;
  final Function(LotteryResultModel) onCopyAndShare;
  final Function(LotteryResultModel) onShareAsPdf;
  final Function(LotteryResultModel) onToggleSave;
  final Function(String) getFilterColor;
  final Function(String) getFilterIcon;

  const ResultDetailsAppBar({
    super.key,
    required this.selectedFilter,
    required this.isSaved,
    required this.isGeneratingPdf,
    required this.onFilterSelected,
    required this.onCopyAndShare,
    required this.onShareAsPdf,
    required this.onToggleSave,
    required this.getFilterColor,
    required this.getFilterIcon,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: preferredSize,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.2),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
              onPressed: () => context.go('/'),
            ),
            title: BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
              builder: (context, state) {
                if (state is LotteryResultDetailsLoaded) {
                  return Text(
                    state.data.result.lotteryName.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return Text(
                  'Lottery Result',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            actions: [
              // Filter dropdown menu
              _buildFilterMenu(theme),
              // Copy Button
              _buildCopyButton(theme),
              // More options menu (Share & Bookmark)
              _buildMoreMenu(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterMenu(ThemeData theme) {
    return BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
      builder: (context, state) {
        if (state is LotteryResultDetailsLoaded) {
          // Determine if filter icon should show games_outlined or specific filter icon
          final showGamesIcon = selectedFilter == 'matched';

          return PopupMenuButton<String>(
            icon: Icon(
              showGamesIcon ? Icons.games_outlined : getFilterIcon(selectedFilter) as IconData,
              color: theme.appBarTheme.actionsIconTheme?.color,
            ),
            tooltip: 'Filter options',
            onSelected: onFilterSelected,
            itemBuilder: (BuildContext context) => [
              _buildFilterMenuItem(
                value: 'matched',
                label: 'Matched',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                theme: theme,
              ),
              _buildFilterMenuItem(
                value: 'repeated',
                label: 'Repeated',
                icon: Icons.repeat,
                color: Colors.blue,
                theme: theme,
              ),
              _buildFilterMenuItem(
                value: 'patterns',
                label: 'Patterns',
                icon: Icons.grid_view,
                color: Colors.purple,
                theme: theme,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    final isSelected = selectedFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? color : theme.textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected
                ? color
                : theme.iconTheme.color?.withValues(alpha: 0.5),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(ThemeData theme) {
    return BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
      builder: (context, state) {
        if (state is LotteryResultDetailsLoaded) {
          return IconButton(
            icon: Icon(
              Icons.content_copy,
              color: theme.appBarTheme.actionsIconTheme?.color,
            ),
            onPressed: () => onCopyAndShare(state.data.result),
            tooltip: 'Copy result',
          );
        }
        return IconButton(
          icon: Icon(
            Icons.content_copy,
            color: theme.appBarTheme.actionsIconTheme?.color,
          ),
          onPressed: null, // Disabled when no data
        );
      },
    );
  }

  Widget _buildMoreMenu(ThemeData theme) {
    return BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
      builder: (context, state) {
        if (state is LotteryResultDetailsLoaded) {
          return PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.appBarTheme.actionsIconTheme?.color,
            ),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'share':
                  if (!isGeneratingPdf) {
                    onShareAsPdf(state.data.result);
                  }
                  break;
                case 'save':
                  onToggleSave(state.data.result);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'share',
                enabled: !isGeneratingPdf,
                child: Row(
                  children: [
                    if (isGeneratingPdf)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.primaryColor,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.share,
                        color: theme.iconTheme.color,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      isGeneratingPdf ? 'Generating PDF...' : 'Share as PDF',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'save',
                child: Row(
                  children: [
                    Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: isSaved ? theme.primaryColor : theme.iconTheme.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isSaved ? 'Remove from saved' : 'Save result',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.appBarTheme.actionsIconTheme?.color,
          ),
          itemBuilder: (BuildContext context) => [],
          enabled: false,
        );
      },
    );
  }
}
