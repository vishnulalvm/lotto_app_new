import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../data/services/pattern_analysis_service.dart';
import '../../../../data/models/results_screen/results_screen.dart';

class PatternStatisticsCard extends StatefulWidget {
  final List<LotteryResultModel>? historicalResults;
  final bool showMockData;
  final bool forceEmptyState;

  const PatternStatisticsCard({
    super.key,
    this.historicalResults,
    this.showMockData = true,
    this.forceEmptyState = false,
  });

  @override
  State<PatternStatisticsCard> createState() => _PatternStatisticsCardState();
}

class _PatternStatisticsCardState extends State<PatternStatisticsCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<PatternStatistic> _patterns = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _loadPatternData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadPatternData() {
    if (widget.forceEmptyState) {
      _patterns = [];
    } else if (widget.historicalResults != null && widget.historicalResults!.isNotEmpty) {
      _patterns = PatternAnalysisService.getTopPatterns(widget.historicalResults!);
    } else if (widget.showMockData) {
      _patterns = PatternAnalysisService.getMockPatternData();
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Card(
              color: theme.cardTheme.color,
              elevation: theme.cardTheme.elevation,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 20),
                    if (_patterns.isEmpty)
                      _buildEmptyState(theme)
                    else ...[
                      _buildTopPatterns(theme),
                      if (_isExpanded) ...[
                        const SizedBox(height: 16),
                        _buildAllPatterns(theme),
                      ],
                      const SizedBox(height: 12),
                      _buildExpandButton(theme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[400]!, Colors.purple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'most_repeated_patterns'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'pattern_analysis_subtitle'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopPatterns(ThemeData theme) {
    final topThree = _patterns.take(3).toList();
    
    return Column(
      children: topThree.asMap().entries.map((entry) {
        final index = entry.key;
        final pattern = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildHorizontalPatternCard(theme, pattern, index),
        );
      }).toList(),
    );
  }

  Widget _buildAllPatterns(ThemeData theme) {
    final remainingPatterns = _patterns.skip(3).toList();
    
    if (remainingPatterns.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: remainingPatterns.asMap().entries.map((entry) {
        final index = entry.key;
        final pattern = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildHorizontalPatternCard(theme, pattern, index + 3),
        );
      }).toList(),
    );
  }

  Widget _buildHorizontalPatternCard(ThemeData theme, PatternStatistic pattern, int index) {
    final colors = _getPatternColors(index);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive dimensions based on screen size
    double cardHeight = 120;
    double iconSize = 20;
    double titleFontSize = 16;
    double descriptionFontSize = 12;
    double countFontSize = 16;
    double exampleFontSize = 13;
    
    if (screenHeight < 600) {
      // Small screens (older phones)
      cardHeight = 100;
      iconSize = 18;
      titleFontSize = 14;
      descriptionFontSize = 11;
      countFontSize = 14;
      exampleFontSize = 12;
    } else if (screenHeight > 800) {
      // Large screens (tablets, large phones)
      cardHeight = 140;
      iconSize = 24;
      titleFontSize = 18;
      descriptionFontSize = 14;
      countFontSize = 18;
      exampleFontSize = 15;
    } else if (screenWidth > 400) {
      // Wide screens
      cardHeight = 130;
      iconSize = 22;
      titleFontSize = 17;
      descriptionFontSize = 13;
      countFontSize = 17;
      exampleFontSize = 14;
    }
    
    return Container(
      height: cardHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0], colors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Pattern name, icon and rank badge
          Row(
            children: [
              Text(
                pattern.icon,
                style: TextStyle(fontSize: iconSize),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pattern.patternType,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildRankBadge(index + 1),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Description
          Text(
            pattern.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: descriptionFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Count and Examples in a row
          Row(
            children: [
              // Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${pattern.count} ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: countFontSize,
                        ),
                      ),
                      TextSpan(
                        text: 'times'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Example Numbers
              if (pattern.examples.isNotEmpty) ...[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: pattern.examples.take(4).map((example) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            example,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontSize: exampleFontSize,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExpandButton(ThemeData theme) {
    if (_patterns.length <= 3) return const SizedBox.shrink();
    
    return Center(
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isExpanded ? 'show_less'.tr() : 'show_more_patterns'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.purple[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.purple[600],
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'no_patterns_found'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'no_patterns_subtitle'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'check_back_later'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getPatternColors(int index) {
    final colorSchemes = [
      [Colors.purple[400]!, Colors.purple[600]!],     // Rank 1
      [Colors.blue[400]!, Colors.blue[600]!],         // Rank 2
      [Colors.green[400]!, Colors.green[600]!],       // Rank 3
      [Colors.orange[400]!, Colors.orange[600]!],     // Rank 4
      [Colors.teal[400]!, Colors.teal[600]!],         // Rank 5
      [Colors.indigo[400]!, Colors.indigo[600]!],     // Rank 6+
    ];
    
    return colorSchemes[index.clamp(0, colorSchemes.length - 1)];
  }
}