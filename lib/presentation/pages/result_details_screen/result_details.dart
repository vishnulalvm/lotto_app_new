import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LotteryResultScreen extends StatefulWidget {
  const LotteryResultScreen({super.key});

  @override
  State<LotteryResultScreen> createState() => _LotteryResultScreenState();
}

class _LotteryResultScreenState extends State<LotteryResultScreen> {
  // Scroll controller to track scroll position
  final ScrollController _scrollController = ScrollController();

  // Store all lottery numbers from all prize categories
  final List<Map<String, dynamic>> _allLotteryNumbers = [];

  // Currently highlighted number index
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();

    // Initialize all lottery numbers with their categories
    _initializeLotteryNumbers();

    // Add scroll listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Initialize all lottery numbers with categories and prize values
  void _initializeLotteryNumbers() {
    // First prize
    _allLotteryNumbers.add({
      'number': 'PK782442',
      'category': '1st Prize',
      'prize': '₹ 1,00,00,000/-',
      'location': 'PATTAMBI'
    });

    // Consolation prizes
    final List<String> consolationNumbers = [
      'PA782442',
      'PB782442',
      'PC782442',
      'PD782442',
      'PE782442',
      'PF782442',
      'PG782442',
      'PH782442',
      'PJ782442',
      'PL782442',
      'PM782442'
    ];

    for (final number in consolationNumbers) {
      _allLotteryNumbers.add({
        'number': number,
        'category': 'Consolation Prize',
        'prize': '₹ 5,000/-',
        'location': ''
      });
    }

    // Second prize
    _allLotteryNumbers.add({
      'number': 'PB865070',
      'category': '2nd Prize',
      'prize': '₹ 50,00,000/-',
      'location': 'THAMARASSERI'
    });

    // Third prizes
    final List<Map<String, String>> thirdPrizeWinners = [
      {'number': 'PA256696', 'location': 'ERNAKULAM'},
      {'number': 'PB189941', 'location': 'IDUKKI'},
      {'number': 'PC406396', 'location': 'PALAKKAD'},
      {'number': 'PD656764', 'location': 'MOOVATTUPUZHA'},
      {'number': 'PE744697', 'location': 'THAMARASSERY'},
      {'number': 'PF895580', 'location': 'KATTAPPANA'},
      {'number': 'PG755206', 'location': 'KARUNAGAPALLY'},
      {'number': 'PH543730', 'location': 'KAYAMKULAM'},
      {'number': 'PJ862524', 'location': 'ADIMALY'},
      {'number': 'PK358362', 'location': 'PALAKKAD'},
      {'number': 'PL226366', 'location': 'PALAKKAD'},
      {'number': 'PM519130', 'location': 'CHERTHALA'},
    ];

    for (final winner in thirdPrizeWinners) {
      _allLotteryNumbers.add({
        'number': winner['number']!,
        'category': '3rd Prize',
        'prize': '₹ 5,00,000/-',
        'location': winner['location']!
      });
    }

    // Fourth prizes
    final List<String> fourthPrizeNumbers = [
      '1078',
      '1447',
      '2406',
      '3102',
      '3475',
      '3567',
      '4232',
      '4677',
      '5786',
      '6085',
      '6485',
      '6801',
      '7172',
      '7690',
      '7986',
      '8881',
      '9539',
      '9894'
    ];

    for (final number in fourthPrizeNumbers) {
      _allLotteryNumbers.add({
        'number': number,
        'category': '4th Prize',
        'prize': '₹ 5,000/-',
        'location': ''
      });
    }

    // Fifth prizes
    final List<String> fifthPrizeNumbers = [
      '0161',
      '0496',
      '0571',
      '0864',
      '1240',
      '1250',
      '1358',
      '1463',
      '1551',
      '1617',
      '1879',
      '2084',
      '2213',
      '2626',
      '2943',
      '3243',
      '4029',
      '5009',
      '5938',
      '6096',
      '6188',
      '6508',
      '6641',
      '7973',
      '8412',
      '8813',
      '8864',
      '8907',
      '9097',
      '9146'
    ];

    for (final number in fifthPrizeNumbers) {
      _allLotteryNumbers.add({
        'number': number,
        'category': '5th Prize',
        'prize': '₹ 1,000/-',
        'location': ''
      });
    }

    // Sixth prizes
    final List<String> sixthPrizeNumbers = [
      '0011',
      '0015',
      '0041',
      '0109',
      '0312',
      '0357',
      '0410',
      '0443',
      '0578',
      '0622',
      '1209',
      '1243',
      '1277',
      '1377',
      '1525',
      '1569',
      '1923',
      '1967',
      '2310',
      '2368'
    ];

    for (final number in sixthPrizeNumbers) {
      _allLotteryNumbers.add({
        'number': number,
        'category': '6th Prize',
        'prize': '₹ 500/-',
        'location': ''
      });
    }

    // Seventh prizes (showing first 20 only to save space)
    final List<String> seventhPrizeNumbers = [
      '0030', '0044', '0158', '0178', '0287', '0323', '0326', '0328', '0390',
      '0428', '0478', '0515', '0590', '0683', '0721', '0785', '0895', '0926',
      '0938', '0944'
      // Rest of the numbers are not included here for brevity
    ];

    for (final number in seventhPrizeNumbers) {
      _allLotteryNumbers.add({
        'number': number,
        'category': '7th Prize',
        'prize': '₹ 100/-',
        'location': ''
      });
    }
  }

  // Scroll listener to change highlighted index
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Calculate scroll percentage (0.0 to 1.0)
    final scrollPercentage =
        _scrollController.offset / _scrollController.position.maxScrollExtent;

    // Calculate which index should be highlighted based on scroll percentage
    final newIndex = (scrollPercentage * _allLotteryNumbers.length).floor();

    // Clamp index to valid range
    final clampedIndex = newIndex.clamp(0, _allLotteryNumbers.length - 1);

    // Update highlighted index if changed
    if (clampedIndex != _highlightedIndex) {
      setState(() {
        _highlightedIndex = clampedIndex;
      });
    }
  }

  // Check if a number should be highlighted
  bool _isHighlighted(String number, String category) {
    if (_highlightedIndex < 0 ||
        _highlightedIndex >= _allLotteryNumbers.length) {
      return false;
    }

    final highlightedItem = _allLotteryNumbers[_highlightedIndex];
    return highlightedItem['number'] == number &&
        highlightedItem['category'] == category;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, context),
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(theme),
                  const SizedBox(height: 8),
                  _buildFirstPrizeSection(theme),
                  const SizedBox(height: 8),
                  _buildConsolationSection(theme),
                  const SizedBox(height: 8),
                  _buildSecondPrizeSection(theme),
                  const SizedBox(height: 8),
                  _buildThirdPrizeSection(theme),
                  const SizedBox(height: 8),
                  _buildFourthPrizeSection(theme),
                  const SizedBox(height: 8),
                  _buildFifthPrizeSection(theme),
                  const SizedBox(height: 8),
                  _buildSixthPrizeSection(theme),
                  const SizedBox(height: 8),
                  _buildSeventhPrizeSection(theme),
                  const SizedBox(height: 8),
                  _buildContactSection(theme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Show currently highlighted number info in a floating card
          if (_highlightedIndex >= 0 &&
              _highlightedIndex < _allLotteryNumbers.length)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: _buildHighlightedCard(theme),
              ),
            ),
        ],
      ),
    );
  }

  // Build floating card showing highlighted number info
  Widget _buildHighlightedCard(ThemeData theme) {
    final highlightedItem = _allLotteryNumbers[_highlightedIndex];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.primaryColor, width: 2),
      ),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                highlightedItem['category'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              highlightedItem['number'],
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              highlightedItem['prize'],
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
                 fontSize: 18,
              ),
            ),
            if (highlightedItem['location'] != null &&
                highlightedItem['location'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  highlightedItem['location'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme, BuildContext context) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
        onPressed: () => context.go('/'),
      ),
      title: Text(
        'KARUNYA PLUS',
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share,
              color: theme.appBarTheme.actionsIconTheme?.color),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.bookmark_outline,
              color: theme.appBarTheme.actionsIconTheme?.color),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '08/05/2025',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.tag, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'KN-571',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPrizeSection(ThemeData theme) {
    final isHighlighted = _isHighlighted('PK782442', '1st Prize');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: isHighlighted
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '1 st Prize',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16.0),
            color: isHighlighted ? Colors.yellow[50] : null,
            child: Column(
              children: [
                Text(
                  '₹ 1,00,00,000/-',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'PK782442',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: isHighlighted ? theme.primaryColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'PATTAMBI',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolationSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              'Consolation Prize',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  '₹ 5,000/-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildConsolationGrid(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolationGrid(ThemeData theme) {
    final List<String> consolationNumbers = [
      'PA782442',
      'PB782442',
      'PC782442',
      'PD782442',
      'PE782442',
      'PF782442',
      'PG782442',
      'PH782442',
      'PJ782442',
      'PL782442',
      'PM782442'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: _createConsolationRows(consolationNumbers, theme),
      ),
    );
  }

  List<TableRow> _createConsolationRows(List<String> numbers, ThemeData theme) {
    List<TableRow> rows = [];

    for (int i = 0; i < numbers.length; i += 2) {
      if (i + 1 < numbers.length) {
        // Two columns per row
        rows.add(
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _isHighlighted(numbers[i], 'Consolation Prize') 
                        ? Colors.yellow[100] 
                        : null,
                    borderRadius: _isHighlighted(numbers[i], 'Consolation Prize')
                        ? BorderRadius.circular(6)
                        : null,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: _isHighlighted(numbers[i], 'Consolation Prize') 
                          ? theme.primaryColor 
                          : null,
                      fontWeight: _isHighlighted(numbers[i], 'Consolation Prize') 
                          ? FontWeight.bold 
                          : null,
                      fontSize: _isHighlighted(numbers[i], 'Consolation Prize')
                          ? 18
                          : 14,
                    ),
                    child: Text(
                      numbers[i],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _isHighlighted(numbers[i + 1], 'Consolation Prize') 
                        ? Colors.yellow[100] 
                        : null,
                    borderRadius: _isHighlighted(numbers[i + 1], 'Consolation Prize')
                        ? BorderRadius.circular(6)
                        : null,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: _isHighlighted(numbers[i + 1], 'Consolation Prize') 
                          ? theme.primaryColor 
                          : null,
                      fontWeight: _isHighlighted(numbers[i + 1], 'Consolation Prize') 
                          ? FontWeight.bold 
                          : null,
                      fontSize: _isHighlighted(numbers[i + 1], 'Consolation Prize')
                          ? 18
                          : 14,
                    ),
                    child: Text(
                      numbers[i + 1],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Only one item for the last row if odd number
        rows.add(
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _isHighlighted(numbers[i], 'Consolation Prize') 
                        ? Colors.yellow[100] 
                        : null,
                    borderRadius: _isHighlighted(numbers[i], 'Consolation Prize')
                        ? BorderRadius.circular(6)
                        : null,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: _isHighlighted(numbers[i], 'Consolation Prize') 
                          ? theme.primaryColor 
                          : null,
                      fontWeight: _isHighlighted(numbers[i], 'Consolation Prize') 
                          ? FontWeight.bold 
                          : null,
                      fontSize: _isHighlighted(numbers[i], 'Consolation Prize')
                          ? 18
                          : 14,
                    ),
                    child: Text(
                      numbers[i],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(''),
              ),
            ],
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildSecondPrizeSection(ThemeData theme) {
    final isHighlighted = _isHighlighted('PB865070', '2nd Prize');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: isHighlighted
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '2 nd Prize',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16.0),
            color: isHighlighted ? Colors.yellow[50] : null,
            child: Column(
              children: [
                Text(
                  '₹ 50,00,000/-',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'PB865070',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: isHighlighted ? theme.primaryColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'THAMARASSERI',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPrizeSection(ThemeData theme) {
    final List<Map<String, String>> thirdPrizeWinners = [
      {'number': 'PA256696', 'location': 'ERNAKULAM'},
      {'number': 'PB189941', 'location': 'IDUKKI'},
      {'number': 'PC406396', 'location': 'PALAKKAD'},
      {'number': 'PD656764', 'location': 'MOOVATTUPUZHA'},
      {'number': 'PE744697', 'location': 'THAMARASSERY'},
      {'number': 'PF895580', 'location': 'KATTAPPANA'},
      {'number': 'PG755206', 'location': 'KARUNAGAPALLY'},
      {'number': 'PH543730', 'location': 'KAYAMKULAM'},
      {'number': 'PJ862524', 'location': 'ADIMALY'},
      {'number': 'PK358362', 'location': 'PALAKKAD'},
      {'number': 'PL226366', 'location': 'PALAKKAD'},
      {'number': 'PM519130', 'location': 'CHERTHALA'},
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '3 rd Prize',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  '₹ 5,00,000/-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: thirdPrizeWinners.length,
                  itemBuilder: (context, index) {
                    final isHighlighted = _isHighlighted(
                        thirdPrizeWinners[index]['number']!, '3rd Prize');

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        color: isHighlighted ? Colors.yellow[50] : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              thirdPrizeWinners[index]['number']!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    isHighlighted ? theme.primaryColor : null,
                              ),
                            ),
                            Text(
                              thirdPrizeWinners[index]['location']!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourthPrizeSection(ThemeData theme) {
    final List<String> fourthPrizeNumbers = [
      '1078',
      '1447',
      '2406',
      '3102',
      '3475',
      '3567',
      '4232',
      '4677',
      '5786',
      '6085',
      '6485',
      '6801',
      '7172',
      '7690',
      '7986',
      '8881',
      '9539',
      '9894'
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '4 th Prize',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  '₹ 5,000/-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildNumberGrid(fourthPrizeNumbers, theme, '4th Prize'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFifthPrizeSection(ThemeData theme) {
    final List<String> fifthPrizeNumbers = [
      '0161',
      '0496',
      '0571',
      '0864',
      '1240',
      '1250',
      '1358',
      '1463',
      '1551',
      '1617',
      '1879',
      '2084',
      '2213',
      '2626',
      '2943',
      '3243',
      '4029',
      '5009',
      '5938',
      '6096',
      '6188',
      '6508',
      '6641',
      '7973',
      '8412',
      '8813',
      '8864',
      '8907',
      '9097',
      '9146',
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor, // Using theme primary color
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '5 th Prize',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  '₹ 1,000/-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildNumberGrid(fifthPrizeNumbers, theme, '5th Prize'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixthPrizeSection(ThemeData theme) {
    final List<String> sixthPrizeNumbers = [
      '0011',
      '0015',
      '0041',
      '0109',
      '0312',
      '0357',
      '0410',
      '0443',
      '0578',
      '0622',
      '1209',
      '1243',
      '1277',
      '1377',
      '1525',
      '1569',
      '1923',
      '1967',
      '2310',
      '2368'
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '6 th Prize',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  '₹ 500/-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildNumberGrid(sixthPrizeNumbers, theme, '6th Prize'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeventhPrizeSection(ThemeData theme) {
    final List<String> seventhPrizeNumbers = [
      '0030', '0044', '0158', '0178', '0287', '0323', '0326', '0328', '0390',
      '0428', '0478', '0515', '0590', '0683', '0721', '0785', '0895', '0926',
      '0938', '0944', '0962', '0968', '1287', '1394', '1411', '1474', '1549',
      '1616', '1638', '1673', '1677', '1750', '1808', '1826', '1845', '1936',
      '2075', '2077', '2111', '2131', '2225', '2297', '2301', '2429', '2439',
      '2521', '2522', '2543', '2586', '2629', '2638', '2651', '2719', '2841',
      '2843', '2850', '2897', '2933', '3034', '3080', '3100', '3112', '3119'
      // Truncated for brevity
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '7 th Prize',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  '₹ 100/-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildNumberGrid(seventhPrizeNumbers, theme, '7th Prize'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Added Contact Section from the first code
  Widget _buildContactSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactRow(Icons.phone, 'Phone: 0471-2305230', theme),
            _buildContactRow(Icons.person, 'Director: 0471-2305193', theme),
            _buildContactRow(
                Icons.email, 'Email: cru.dir.lotteries@kerala.gov.in', theme),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Visit Official Website'),
            ),
          ],
        ),
      ),
    );
  }

  // Added Contact Row helper from the first code
  Widget _buildContactRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberGrid(
      List<String> numbers, ThemeData theme, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: _createNumberRows(numbers, theme, category),
      ),
    );
  }

  List<TableRow> _createNumberRows(
      List<String> numbers, ThemeData theme, String category) {
    List<TableRow> rows = [];

    for (int i = 0; i < numbers.length; i += 4) {
      List<Widget> cells = [];

      for (int j = 0; j < 4; j++) {
        if (i + j < numbers.length) {
          final number = numbers[i + j];
          final isHighlighted = _isHighlighted(number, category);

          cells.add(
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.yellow[50] : null,
                  borderRadius: isHighlighted ? BorderRadius.circular(4) : null,
                ),
                child: Text(
                  number,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isHighlighted ? theme.primaryColor : null,
                    fontWeight: isHighlighted ? FontWeight.bold : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else {
          cells.add(
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(''),
            ),
          );
        }
      }

      rows.add(TableRow(children: cells));
    }

    return rows;
  }
}
