import 'package:flutter/material.dart';

class SavedResultsScreen extends StatefulWidget {
  const SavedResultsScreen({super.key});

  @override
  State<SavedResultsScreen> createState() => _SavedResultsScreenState();
}

class _SavedResultsScreenState extends State<SavedResultsScreen> {
  final List<Map<String, dynamic>> savedResults = [
    {
      'title': 'Akshaya AK 620',
      'date': '2024-01-22',
      'isFavorite': true,
      'prize': '1st Prize Rs 700000/- [70 Lakhs]',
      'winner': 'AY 197092 (Thrissur)',
      'consolationPrizes': ['NB 57040', 'NC 570212', 'NE 89456'],
    },
    {
      'title': 'Akshaya AK 620',
      'date': '2024-01-22',
      'isFavorite': true,
      'prize': '1st Prize Rs 700000/- [70 Lakhs]',
      'winner': 'AY 197092 (Thrissur)',
      'consolationPrizes': ['NB 57040', 'NC 570212', 'NE 89456'],
    },
    {
      'title': 'Akshaya AK 620',
      'date': '2024-01-22',
      'isFavorite': true,
      'prize': '1st Prize Rs 700000/- [70 Lakhs]',
      'winner': 'AY 197092 (Thrissur)',
      'consolationPrizes': ['NB 57040', 'NC 570212', 'NE 89456'],
    },
    {
      'title': 'Akshaya AK 620',
      'date': '2024-01-22',
      'isFavorite': true,
      'prize': '1st Prize Rs 700000/- [70 Lakhs]',
      'winner': 'AY 197092 (Thrissur)',
      'consolationPrizes': ['NB 57040', 'NC 570212', 'NE 89456'],
    },
    {
      'title': 'Akshaya AK 620',
      'date': '2024-01-22',
      'isFavorite': true,
      'prize': '1st Prize Rs 700000/- [70 Lakhs]',
      'winner': 'AY 197092 (Thrissur)',
      'consolationPrizes': ['NB 57040', 'NC 570212', 'NE 89456'],
    },
    // Add more saved results as needed
  ];

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
        'Saved Results',
        style: theme.appBarTheme.titleTextStyle,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: theme.appBarTheme.actionsIconTheme?.color),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    return savedResults.isEmpty
        ? _buildEmptyState(theme)
        : _buildResultsList(theme);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Results',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your saved lottery results will appear here',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedResults.length,
      itemBuilder: (context, index) {
        final result = savedResults[index];
        return _buildSavedResultCard(result, theme);
      },
    );
  }

  Widget _buildSavedResultCard(Map<String, dynamic> result, ThemeData theme) {
    return Dismissible(
      key: Key(result['title']),
      background: _buildDismissBackground(theme),
      onDismissed: (direction) {
        setState(() {
          savedResults.removeWhere((item) => item['title'] == result['title']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['title']} removed from saved'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  savedResults.insert(0, result);
                });
              },
            ),
          ),
        );
      },
      child: Card(
        color: theme.cardTheme.color,
        margin: const EdgeInsets.only(bottom: 16),
        elevation: theme.cardTheme.elevation,
        shape: theme.cardTheme.shape,
        child: Column(
          children: [
            _buildCardHeader(result, theme),
            _buildCardContent(result, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> result, ThemeData theme) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['title'],
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                result['date'],
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              result['isFavorite'] ? Icons.favorite : Icons.favorite_border,
              color: theme.primaryColor,
            ),
            onPressed: () {
              setState(() {
                result['isFavorite'] = !result['isFavorite'];
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> result, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result['prize'],
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            result['winner'],
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
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
            children: result['consolationPrizes']
                .map<Widget>((prize) => _buildPrizeChip(prize, theme))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeChip(String prize, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFFFE4E6)
            : Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        prize,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildDismissBackground(ThemeData theme) {
    return Container(
      color: Colors.red.shade100,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(
        Icons.delete,
        color: theme.primaryColor,
      ),
    );
  }
}