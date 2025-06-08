import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/presentation/pages/contact_us/contact_us.dart';
import 'package:lotto_app/routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> carouselImages = [
    'assets/images/five.jpeg',
    'assets/images/four.jpeg',
    'assets/images/seven.jpeg',
    'assets/images/six.jpeg',
    'assets/images/tree.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! < 0) {
          // Swipe left
          context.go('/news_screen');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: SingleChildScrollView(
          physics:
              const ClampingScrollPhysics(), // Prevents horizontal scroll interference
          child: Column(
            children: [
              _buildCarousel(),
              SizedBox(height: AppResponsive.spacing(context, 5)),
              _buildNavigationIcons(theme),
              SizedBox(height: AppResponsive.spacing(context, 10)),
              _buildResultsSection(theme),
            ],
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
          Icons.search,
          color: theme.appBarTheme.iconTheme?.color,
          size: AppResponsive.fontSize(context, 24),
        ),
        onPressed: () => context.go('/search'),
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
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: theme.appBarTheme.actionsIconTheme?.color,
            size: AppResponsive.fontSize(context, 24),
          ),
          onPressed: () => context.go('/notifications'),
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
    return Column(
      children: [
        _buildDateDivider('Today Result', theme),
        _buildResultCard(
          'Akshaya AK 620 Winner List',
          '1st Prize Rs 700000/- [70 Lakhs]',
          'AY 197092 (Thrissur)',
          ['NB 57040', 'NC 570212', 'NE 89456'],
          theme,
          isNew: true, // Mark today's result as new
        ),
        _buildDateDivider('Yesterday Result', theme),
        _buildResultCard(
          'Win Win 520 Winner List',
          '1st Prize Rs 500000/- [50 Lakhs]',
          'WO 695950 (KOLLAM)',
          ['NB 57040', 'NC 570212', 'NE 89456'],
          theme,
          isNew: false,
        ),
        _buildDateDivider('15-10-2023', theme),
        _buildResultCard(
          'Win Win 520 Winner List',
          '1st Prize Rs 500000/- [50 Lakhs]',
          'WO 695950 (KOLLAM)',
          ['NB 57040', 'NC 570212', 'NE 89456'],
          theme,
          isNew: false,
        ),
        _buildDateDivider('16-10-2023', theme),
        _buildResultCard(
          'Win Win 520 Winner List',
          '1st Prize Rs 500000/- [50 Lakhs]',
          'WO 695950 (KOLLAM)',
          ['NB 57040', 'NC 570212', 'NE 89456'],
          theme,
          isNew: false,
        ),
      ],
    );
  }

  Widget _buildDateDivider(String text, ThemeData theme) {
    return Padding(
      padding: AppResponsive.padding(context, horizontal: 24, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.dividerTheme.color)),
          Padding(
            padding: AppResponsive.padding(context, horizontal: 16),
            child: Text(
              text,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: AppResponsive.fontSize(context, 12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.dividerTheme.color)),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    String prize,
    String winner,
    List<String> consolationPrizes,
    ThemeData theme, {
    bool isNew = false, // New parameter to indicate if this is a new result
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card
        Card(
          color: theme.cardTheme.color,
          margin: AppResponsive.margin(context, horizontal: 16, vertical: 10),
          elevation: theme.brightness == Brightness.dark
              ? 4.0
              : 2.0, // Higher elevation for dark mode
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
              context.push('/rewarded-ad/${Uri.encodeComponent(title)}');
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
                          title,
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
                          : const Color(0xFF2D1518), // Dark red tint
                      borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 3)),
                    ),
                    child: Text(
                      prize,
                      style: TextStyle(
                        fontSize: AppResponsive.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.light
                            ? Colors.pink[900]
                            : Colors.red[300], // Lighter red for dark theme
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
                    winner,
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
                    'Consolation Prize 8000/-',
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 12)),

                  // Preview of consolation prizes (showing just 2 rows)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: consolationPrizes
                        .map((prize) => Container(
                              padding: AppResponsive.padding(context,
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light
                                    ? Colors.grey[200]
                                    : const Color(
                                        0xFF2A2A2A), // Darker grey for dark theme
                                borderRadius: BorderRadius.circular(
                                    AppResponsive.spacing(context, 4)),
                              ),
                              child: Text(
                                prize,
                                style: TextStyle(
                                  fontSize: AppResponsive.fontSize(context, 13),
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 8)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: consolationPrizes
                        .map((prize) => Container(
                              padding: AppResponsive.padding(context,
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light
                                    ? Colors.grey[200]
                                    : const Color(
                                        0xFF2A2A2A), // Darker grey for dark theme
                                borderRadius: BorderRadius.circular(
                                    AppResponsive.spacing(context, 4)),
                              ),
                              child: Text(
                                prize,
                                style: TextStyle(
                                  fontSize: AppResponsive.fontSize(context, 13),
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 16)),

                  // "See More" button - IMPROVED FOR DARK MODE
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .push('/rewarded-ad/${Uri.encodeComponent(title)}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.red[50]
                            : Colors.red[900], // Red background for dark theme
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.red[800]
                            : Colors.red[100], // Light text for dark theme
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
                          SizedBox(width: 4),
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

        // New Badge (only shown if isNew is true)
        if (isNew)
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
                    offset: Offset(0, 2),
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

  Widget _buildScanButton(ThemeData theme) {
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
      label: Text(
        'Barcode Scan',
        style: TextStyle(
          fontSize: AppResponsive.fontSize(context, 14),
        ),
      ),
    );
  }
}
