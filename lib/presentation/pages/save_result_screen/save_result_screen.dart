import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/models/results_screen/save_result.dart';
import 'package:lotto_app/data/services/save_results.dart';

class SavedResultsScreen extends StatefulWidget {
  const SavedResultsScreen({super.key});

  @override
  State<SavedResultsScreen> createState() => _SavedResultsScreenState();
}

class _SavedResultsScreenState extends State<SavedResultsScreen> {
  List<SavedLotteryResult> savedResults = [];
  List<SavedLotteryResult> filteredResults = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadSavedResults();
  }

  Future<void> _loadSavedResults() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await SavedResultsService.init();
      final results = SavedResultsService.getAllSavedResults();

      setState(() {
        savedResults = results;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_loading_saved_results'.tr()}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<SavedLotteryResult> results = List.from(savedResults);

    // Apply favorites filter
    if (_showFavoritesOnly) {
      results = results.where((result) => result.isFavorite).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      results = results.where((result) {
        final query = _searchQuery.toLowerCase();
        return result.title.toLowerCase().contains(query) ||
            result.winner.toLowerCase().contains(query) ||
            result.consolationPrizes
                .any((prize) => prize.toLowerCase().contains(query));
      }).toList();
    }

    setState(() {
      filteredResults = results;
    });
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
    });
    _applyFilters();
  }

  Future<void> _toggleFavorite(SavedLotteryResult result) async {
    final success = await SavedResultsService.toggleFavorite(result.uniqueId);
    if (success) {
      await _loadSavedResults(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.isFavorite
                ? 'added_to_favorites'.tr()
                : 'removed_from_favorites'.tr()),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _removeSavedResult(SavedLotteryResult result) async {
    final success =
        await SavedResultsService.removeSavedResult(result.uniqueId);
    if (success) {
      await _loadSavedResults(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.title}${'removed_from_saved_suffix'.tr()}'),
            action: SnackBarAction(
              label: 'undo'.tr(),
              onPressed: () async {
                // Re-save the result (you might want to store the original LotteryResultModel)
                // For now, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'cannot_undo_message'.tr()),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _navigateToResultDetails(String uniqueId) {
    context.go('/lottery-result-details/$uniqueId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      centerTitle: true,
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'saved_results'.tr(),
        style: theme.appBarTheme.titleTextStyle,
      ),
      actions: [
        // Search button
        IconButton(
          icon: Icon(Icons.search,
              color: theme.appBarTheme.actionsIconTheme?.color),
          onPressed: () {
            showSearch(
              context: context,
              delegate: SavedResultsSearchDelegate(
                savedResults: filteredResults,
                onResultTapped: _navigateToResultDetails,
              ),
            );
          },
        ),
        // Filter button
        PopupMenuButton<String>(
          icon: Icon(
            _showFavoritesOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: theme.appBarTheme.actionsIconTheme?.color,
          ),
          onSelected: (value) {
            switch (value) {
              case 'favorites':
                _toggleFavoritesFilter();
                break;
              case 'clear_all':
                _showClearAllDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'favorites',
              child: Row(
                children: [
                  Icon(_showFavoritesOnly
                      ? Icons.favorite
                      : Icons.favorite_border),
                  const SizedBox(width: 8),
                  Text(_showFavoritesOnly ? 'show_all'.tr() : 'favorites_only'.tr()),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.clear_all, color: Colors.red),
                  SizedBox(width: 8),
                  Text('clear_all'.tr(), style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (savedResults.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (filteredResults.isEmpty) {
      return _buildNoResultsFound(theme);
    }

    return _buildResultsList(theme);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: theme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'no_saved_results'.tr(),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'saved_results_description'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: Text('browse_results'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'no_results_found'.tr(),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _showFavoritesOnly
                ? 'no_favorite_results'.tr()
                : 'no_search_match'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _showFavoritesOnly = false;
              });
              _applyFilters();
            },
            child: Text('clear_filters'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme) {
    return Column(
      children: [
        // Filter info bar
        if (_showFavoritesOnly || _searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _showFavoritesOnly
                        ? '${'showing_prefix'.tr()}${filteredResults.length}${'favorite_result_singular'.tr()}${filteredResults.length != 1 ? 's' : ''}'
                        : '${'showing_prefix'.tr()}${filteredResults.length} result${filteredResults.length != 1 ? 's' : ''} for "$_searchQuery"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _showFavoritesOnly = false;
                    });
                    _applyFilters();
                  },
                  child: Text('clear'.tr(),
                      style: TextStyle(color: theme.primaryColor)),
                ),
              ],
            ),
          ),
        // Results list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSavedResults,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredResults.length,
              itemBuilder: (context, index) {
                final result = filteredResults[index];
                return _buildSavedResultCard(result, theme);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedResultCard(SavedLotteryResult result, ThemeData theme) {
    return Dismissible(
      key: Key(result.uniqueId),
      background: _buildDismissBackground(theme, false),
      secondaryBackground: _buildDismissBackground(theme, true),
      onDismissed: (direction) {
        _removeSavedResult(result);
      },
      child: Card(
        color: theme.cardTheme.color,
        margin: const EdgeInsets.only(bottom: 16),
        elevation: theme.cardTheme.elevation,
        shape: theme.cardTheme.shape,
        child: InkWell(
          onTap: () => _navigateToResultDetails(result.uniqueId),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              _buildCardHeader(result, theme),
              _buildCardContent(result, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(SavedLotteryResult result, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFFFE4E6)
            : Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.date,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saved ${_formatSavedDate(result.savedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              result.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: result.isFavorite
                  ? theme.primaryColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onPressed: () => _toggleFavorite(result),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(SavedLotteryResult result, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.prize,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.emoji_events, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  result.winner,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          if (result.consolationPrizes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Consolation Prizes:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.consolationPrizes
                  .take(3) // Show only first 3 consolation prizes
                  .map<Widget>((prize) => _buildPrizeChip(prize, theme))
                  .toList()
                ..addAll(result.consolationPrizes.length > 3
                    ? [
                        _buildMoreChip(
                            result.consolationPrizes.length - 3, theme)
                      ]
                    : []),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrizeChip(String prize, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? theme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        prize,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMoreChip(int count, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '+$count more',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildDismissBackground(ThemeData theme, bool isSecondary) {
    return Container(
      color: Colors.red.withValues(alpha: 0.1),
      alignment: isSecondary ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.only(
        left: isSecondary ? 0 : 20,
        right: isSecondary ? 20 : 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete,
            color: Colors.red,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            'Remove',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSavedDate(DateTime savedAt) {
    final now = DateTime.now();
    final difference = now.difference(savedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Saved Results'),
        content: const Text(
          'Are you sure you want to remove all saved results? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await SavedResultsService.clearAllSavedResults();
              if (success) {
                await _loadSavedResults();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All saved results cleared'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// Search delegate for saved results
class SavedResultsSearchDelegate extends SearchDelegate<SavedLotteryResult?> {
  final List<SavedLotteryResult> savedResults;
  final Function(String) onResultTapped;

  SavedResultsSearchDelegate({
    required this.savedResults,
    required this.onResultTapped,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final filteredResults = savedResults.where((result) {
      final queryLower = query.toLowerCase();
      return result.title.toLowerCase().contains(queryLower) ||
          result.winner.toLowerCase().contains(queryLower) ||
          result.consolationPrizes
              .any((prize) => prize.toLowerCase().contains(queryLower));
    }).toList();

    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a search term to find saved results'),
      );
    }

    if (filteredResults.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final result = filteredResults[index];
        return ListTile(
          title: Text(result.title),
          subtitle: Text(result.winner),
          trailing: Text(result.date),
          onTap: () {
            close(context, result);
            onResultTapped(result.uniqueId);
          },
        );
      },
    );
  }
}
