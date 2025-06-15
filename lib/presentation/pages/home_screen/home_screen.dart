import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_event.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_state.dart';
import 'package:lotto_app/presentation/pages/contact_us/contact_us.dart';
import 'package:lotto_app/routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<String> carouselImages = [
    'assets/images/five.jpeg',
    'assets/images/four.jpeg',
    'assets/images/seven.jpeg',
    'assets/images/six.jpeg',
    'assets/images/tree.jpeg',
  ];

  late ScrollController _scrollController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isExpanded = true;
  bool _isScrollingDown = false;

  void initState() {
    super.initState();
    _loadLotteryResults();

    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: const Duration(
          milliseconds: 400), // Slightly longer for smoother feel
      vsync: this,
    );

    // Use a smooth curve for the animation
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOutCubic, // Smoother curve
      reverseCurve: Curves.easeInOutCubic,
    );

    _fabAnimationController.forward();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final ScrollDirection direction =
        _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse) {
      // Scrolling down - collapse FAB
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        if (_isExpanded) {
          setState(() {
            _isExpanded = false;
          });
          _fabAnimationController.reverse();
        }
      }
    } else if (direction == ScrollDirection.forward) {
      // Scrolling up - expand FAB
      if (_isScrollingDown) {
        _isScrollingDown = false;
        if (!_isExpanded) {
          setState(() {
            _isExpanded = true;
          });
          _fabAnimationController.forward();
        }
      }
    }
  }

  void _loadLotteryResults() {
    context.read<HomeScreenResultsBloc>().add(LoadLotteryResultsEvent());
  }

  void _refreshResults() {
    context.read<HomeScreenResultsBloc>().add(RefreshLotteryResultsEvent());
  }

  // Method to show date picker and navigate to specific date
  Future<void> _showDatePicker() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select date to filter results',
      cancelText: 'Cancel',
      confirmText: 'Filter',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Colors.white,
                  surface: Theme.of(context).cardColor,
                  onSurface: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Show loading feedback

      // Let the BLoC handle the filtering
      context
          .read<HomeScreenResultsBloc>()
          .add(LoadLotteryResultsByDateEvent(selectedDate));
    }
  }

  // Helper method to format date for display
  String _formatDateForDisplay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! < 0) {
          context.go('/news_screen');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: BlocListener<HomeScreenResultsBloc, HomeScreenResultsState>(
          listener: (context, state) {
            // Clear any existing snackbars first
            ScaffoldMessenger.of(context).clearSnackBars();

            if (state is HomeScreenResultsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _loadLotteryResults,
                  ),
                ),
              );
            }
          },
          child: RefreshIndicator(
            onRefresh: () async {
              _refreshResults();
            },
            child: SingleChildScrollView(
              controller:
                  _scrollController, // This was the original missing piece!
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildCarousel(),
                  SizedBox(height: AppResponsive.spacing(context, 5)),
                  _buildNavigationIcons(theme),
                  SizedBox(height: AppResponsive.spacing(context, 10)),
                  _buildResultsSection(theme),
                  SizedBox(height: AppResponsive.spacing(context, 100)),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _buildScanButton(theme),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      centerTitle: true,
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(
          Icons.notifications,
          color: theme.appBarTheme.actionsIconTheme?.color,
          size: AppResponsive.fontSize(context, 24),
        ),
        onPressed: () => context.go('/notifications'),
      ),
      title: Text(
        'LOTTO',
        style: TextStyle(
          fontSize: AppResponsive.fontSize(context, 20),
          fontWeight: FontWeight.bold,
          color: theme.appBarTheme.titleTextStyle?.color,
        ),
      ),
      actions: [
        // Beautiful Coin Button
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.spacing(context, 4),
          ),
          child: GestureDetector(
            onTap: () => context.go('/lottoPoints'),
            child: Container(
              height: AppResponsive.fontSize(context, 26),
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.spacing(context, 6),
                vertical: AppResponsive.spacing(context, 4),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 204, 61, 25), // Gold
                    Color.fromARGB(255, 206, 71, 4), // Light Gold
                    Color.fromARGB(255, 229, 92, 38), // Gold
                  ],
                  stops: [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  AppResponsive.spacing(context, 18),
                ),
                border: Border.all(
                  color: Color(0xFFFFE55C).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: Color(0xFF8B4513), // Brown color for contrast
                    size: AppResponsive.fontSize(context, 14),
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 4)),
                  Text(
                    '1,250', // Replace with your actual coin count variable
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 10),
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Brown color for contrast
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.appBarTheme.actionsIconTheme?.color,
            size: AppResponsive.fontSize(context, 24),
          ),
          offset: Offset(0, AppResponsive.spacing(context, 45)),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
          ),
          itemBuilder: (BuildContext context) => [
            _buildPopupMenuItem(
              'settings',
              Icons.settings,
              'Settings',
              theme,
            ),
            _buildPopupMenuItem(
              'contact',
              Icons.contact_support,
              'Contact Us',
              theme,
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'settings':
                context.push('/settings');
                break;
              case 'contact':
                showContactSheet(context);
                break;
            }
          },
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text,
    ThemeData theme,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.iconTheme.color,
            size: AppResponsive.fontSize(context, 20),
          ),
          SizedBox(width: AppResponsive.spacing(context, 12)),
          Text(
            text,
            style: TextStyle(
              fontSize: AppResponsive.fontSize(context, 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return Padding(
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 8),
      child: CarouselSlider(
        options: CarouselOptions(
          height: AppResponsive.height(
              context, AppResponsive.isMobile(context) ? 15 : 20),
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: AppResponsive.isMobile(context) ? 0.85 : 0.7,
        ),
        items: carouselImages.map((image) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: AppResponsive.width(context, 100),
                margin: AppResponsive.margin(context, horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.pink[100],
                  borderRadius:
                      BorderRadius.circular(AppResponsive.spacing(context, 8)),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppResponsive.spacing(context, 8)),
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationIcons(ThemeData theme) {
    final List<Map<String, dynamic>> navItems = [
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Scanner',
        'route': '/barcode_scanner_screen'
      },
      {'icon': Icons.emoji_events, 'label': 'Claim', 'route': '/claim'},
      {'icon': Icons.games_outlined, 'label': 'Predict', 'route': '/Predict'},
      {'icon': Icons.newspaper, 'label': 'News', 'route': '/news_screen'},
      {'icon': Icons.bookmark, 'label': 'Saved', 'route': '/saved-results'},
    ];

    return Container(
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: AppResponsive.spacing(context, 8),
            offset: Offset(0, AppResponsive.spacing(context, 2)),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: navItems.map((item) => _buildNavItem(item, theme)).toList(),
      ),
    );
  }

  Widget _buildNavItem(Map<String, dynamic> item, ThemeData theme) {
    final double iconSize = AppResponsive.fontSize(context, 24);
    final double containerSize = AppResponsive.width(
      context,
      AppResponsive.isMobile(context) ? 12 : 8,
    );

    return InkWell(
      onTap: () {
        if (item['route'] != null) {
          context.go(item['route']);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? const Color(0xFFFFE4E6)
                  : const Color(0xFF2D1518), // Dark red tint for dark theme
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'],
              color: theme.iconTheme.color,
              size: iconSize,
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 8)),
          SizedBox(
            width: AppResponsive.width(context, 15),
            child: Text(
              item['label'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 12),
                fontWeight: FontWeight.w500,
                color:
                    theme.textTheme.bodyMedium?.color, // Use theme text color
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
      builder: (context, state) {
        if (state is HomeScreenResultsLoading) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading lottery results...',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: AppResponsive.fontSize(context, 14),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is HomeScreenResultsError) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: AppResponsive.fontSize(context, 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load results',
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: AppResponsive.fontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: AppResponsive.fontSize(context, 14),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadLotteryResults,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is HomeScreenResultsLoaded) {
          // Show filter indicator if results are filtered (BLoC handles this now)
          Widget filterIndicator = const SizedBox.shrink();
          if (state.isFiltered && state.filteredDate != null) {
            filterIndicator = Container(
              margin:
                  AppResponsive.margin(context, horizontal: 16, vertical: 8),
              padding:
                  AppResponsive.padding(context, horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppResponsive.spacing(context, 8)),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: theme.colorScheme.primary,
                    size: AppResponsive.fontSize(context, 20),
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 8)),
                  Expanded(
                    child: Text(
                      'Showing results for ${_formatDateForDisplay(state.filteredDate!)}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: AppResponsive.fontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context
                          .read<HomeScreenResultsBloc>()
                          .add(ClearDateFilterEvent());
                    },
                    icon: Icon(
                      Icons.clear,
                      size: AppResponsive.fontSize(context, 16),
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      'Show All',
                      style: TextStyle(
                        fontSize: AppResponsive.fontSize(context, 12),
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: AppResponsive.padding(context,
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.data.results.isEmpty) {
            return Column(
              children: [
                filterIndicator,
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                        size: AppResponsive.fontSize(context, 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.isFiltered
                            ? 'No lottery results found for selected date'
                            : 'No lottery results available',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: AppResponsive.fontSize(context, 16),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (state.isFiltered) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context
                                .read<HomeScreenResultsBloc>()
                                .add(ClearDateFilterEvent());
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text(
                            'Show All Results',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                theme.floatingActionButtonTheme.backgroundColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }

          // Group results by date category
          Map<String, List<HomeScreenResultModel>> groupedResults = {};
          for (var result in state.data.results) {
            String dateCategory = result.formattedDate;
            if (!groupedResults.containsKey(dateCategory)) {
              groupedResults[dateCategory] = [];
            }
            groupedResults[dateCategory]!.add(result);
          }

          return Column(
            children: [
              filterIndicator,
              ...groupedResults.entries.map((entry) {
                return Column(
                  children: [
                    _buildDateDivider(entry.key, theme),
                    ...entry.value
                        .map((result) => _buildResultCard(result, theme))
                        .toList(),
                  ],
                );
              }).toList(),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Pull to refresh lottery results',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: AppResponsive.fontSize(context, 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateDivider(String text, ThemeData theme) {
    return GestureDetector(
      onTap: _showDatePicker, // Add tap functionality here
      child: Container(
        color: Colors.transparent, // Make the entire area tappable
        child: Padding(
          padding: AppResponsive.padding(context, horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Divider(color: theme.dividerTheme.color)),
              Padding(
                padding: AppResponsive.padding(context, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: AppResponsive.fontSize(context, 14),
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 6)),
                    Text(
                      text,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: AppResponsive.fontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Divider(color: theme.dividerTheme.color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(HomeScreenResultModel result, ThemeData theme) {
    // Get first 6 consolation tickets for display
    List<String> consolationTickets =
        result.consolationTicketsList.take(6).toList();
    // Split into 2 rows of 3
    List<String> firstRow = consolationTickets.take(3).toList();
    List<String> secondRow = consolationTickets.skip(3).take(3).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card
        Card(
          color: theme.cardTheme.color,
          margin: AppResponsive.margin(context, horizontal: 16, vertical: 10),
          elevation: theme.brightness == Brightness.dark ? 4.0 : 2.0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
            side: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              width: theme.brightness == Brightness.dark ? 1.0 : 0.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              context.go('/result-details', extra: result.uniqueId);
            },
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
            child: Padding(
              padding:
                  AppResponsive.padding(context, horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with accent line
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: AppResponsive.spacing(context, 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 10)),
                      Expanded(
                        child: Text(
                          result.formattedTitle,
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 6)),

                  // Prize amount in highlighted container
                  Container(
                    padding: AppResponsive.padding(context,
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.pink[50]
                          : const Color(0xFF2D1518),
                      borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 3)),
                    ),
                    child: Text(
                      result.formattedFirstPrize,
                      style: TextStyle(
                        fontSize: AppResponsive.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.light
                            ? Colors.pink[900]
                            : Colors.red[300],
                      ),
                    ),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 16)),

                  // Winner section
                  Text(
                    'First Prize Winner:',
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 13),
                      fontWeight: FontWeight.w500,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 4)),
                  Text(
                    result.formattedWinner,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  // Consolation prizes section with divider
                  Divider(
                    color: theme.dividerTheme.color,
                    thickness: 1,
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 8)),

                  Text(
                    result.formattedConsolationPrize,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 12)),

                  // First row of consolation prizes
                  if (firstRow.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: firstRow
                          .map((prize) =>
                              _buildConsolationPrizeContainer(prize, theme))
                          .toList(),
                    ),

                  if (secondRow.isNotEmpty)
                    SizedBox(height: AppResponsive.spacing(context, 8)),

                  // Second row of consolation prizes
                  if (secondRow.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: secondRow
                          .map((prize) =>
                              _buildConsolationPrizeContainer(prize, theme))
                          .toList(),
                    ),

                  SizedBox(height: AppResponsive.spacing(context, 16)),

                  // "See More" button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                       context.go('/result-details', extra: result.uniqueId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.red[50]
                            : Colors.red[900],
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.red[800]
                            : Colors.red[100],
                        padding: AppResponsive.padding(context,
                            horizontal: 12, vertical: 6),
                        elevation:
                            theme.brightness == Brightness.dark ? 2.0 : 1.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppResponsive.spacing(context, 6)),
                          side: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.red[700]!
                                : Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See More',
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: AppResponsive.fontSize(context, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // New Badge (only shown if it's today's result)
        if (result.isNew)
          Positioned(
            top: 13,
            right: AppResponsive.spacing(context, 16),
            child: Container(
              padding:
                  AppResponsive.padding(context, horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  bottomLeft:
                      Radius.circular(AppResponsive.spacing(context, 8)),
                  bottomRight:
                      Radius.circular(AppResponsive.spacing(context, 8)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppResponsive.fontSize(context, 10),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConsolationPrizeContainer(String prize, ThemeData theme) {
    return Container(
      padding: AppResponsive.padding(context, horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.grey[200]
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 4)),
      ),
      child: Text(
        prize,
        style: TextStyle(
          fontSize: AppResponsive.fontSize(context, 13),
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildScanButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return FloatingActionButton.extended(
          onPressed: () {
            context.pushNamed(RouteNames.barcodeScannerScreen);
          },
          backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
          foregroundColor: theme.floatingActionButtonTheme.foregroundColor,
          icon: Icon(
            Icons.qr_code_scanner,
            size: AppResponsive.fontSize(context, 24),
          ),
          label: SizeTransition(
            sizeFactor: _fabAnimation,
            axis: Axis.horizontal,
            axisAlignment: -1.0, // Align to start (left)
            child: Padding(
              padding: EdgeInsets.only(
                left: 8.0 * _fabAnimation.value, // Smooth spacing transition
              ),
              child: Text(
                'Barcode Scan',
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 14),
                ),
              ),
            ),
          ),
          // Smooth padding transition using animation value
          extendedPadding: EdgeInsets.symmetric(
            horizontal: 12.0 + (4.0 * _fabAnimation.value),
          ),
          // Smooth spacing transition
          extendedIconLabelSpacing:
              0.0, // Set to 0 since we handle spacing in the Padding widget
        );
      },
    );
  }
}
