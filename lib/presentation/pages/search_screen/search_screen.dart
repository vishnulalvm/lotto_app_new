import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isSearchFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildSearchBar(theme),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSearchFocused) ...[
                    _buildRecentSearches(theme),
                    _buildPopularSearches(theme),
                  ] else ...[
                    _buildSearchResults(theme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.appBarTheme.iconTheme?.color,
        ),
        onPressed: () => context.go('/'),
      ),
      title: Text(
        'Search',
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.appBarTheme.backgroundColor,
      child: TextField(
        controller: _searchController,
        onTap: () {
          setState(() {
            isSearchFocused = true;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search lottery numbers, results...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: theme.primaryColor),
          suffixIcon: isSearchFocused
              ? IconButton(
                  icon: Icon(Icons.close, color: theme.primaryColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      isSearchFocused = false;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primaryColor, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(ThemeData theme) {
    final recentSearches = ['AK 620', 'Win Win W 755', 'Nirmal NR 352'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((search) => _buildSearchChip(
              search,
              theme,
              icon: Icons.history,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSearches(ThemeData theme) {
    final popularSearches = [
      'Akshaya',
      'Win Win',
      'Karunya',
      'Nirmal',
      'Karunya Plus',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularSearches.map((search) => _buildSearchChip(
              search,
              theme,
              icon: Icons.trending_up,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildResultCard(
            'Akshaya AK 620',
            'Draw Date: 24-01-2024',
            '1st Prize: Rs 70 Lakhs',
            theme,
          ),
          _buildResultCard(
            'Win Win W 755',
            'Draw Date: 22-01-2024',
            '1st Prize: Rs 75 Lakhs',
            theme,
          ),
          _buildResultCard(
            'Nirmal NR 352',
            'Draw Date: 19-01-2024',
            '1st Prize: Rs 70 Lakhs',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label, ThemeData theme, {IconData? icon}) {
    return InkWell(
      onTap: () {
        _searchController.text = label;
        setState(() {
          isSearchFocused = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    String date,
    String prize,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                date,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prize,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}