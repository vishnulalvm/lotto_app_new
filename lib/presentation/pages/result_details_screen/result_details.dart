// Updated LotteryResultDetailsScreen with PDF sharing functionality
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/services/pdf_service.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_event.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_state.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/dynamic_prize_sections_widget.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/search_bar.dart';

class LotteryResultDetailsScreen extends StatefulWidget {
  final String? uniqueId;

  const LotteryResultDetailsScreen({
    super.key,
    this.uniqueId,
  });

  @override
  State<LotteryResultDetailsScreen> createState() =>
      _LotteryResultDetailsScreenState();
}

class _LotteryResultDetailsScreenState
    extends State<LotteryResultDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  // Store all lottery numbers with their categories
  final List<Map<String, dynamic>> _allLotteryNumbers = [];

  // Add search functionality
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredLotteryNumbers = [];

  // Minimum search length
  static const int _minSearchLength = 4;

  // PDF generation state
  bool _isGeneratingPdf = false;
  // Save state tracking
  bool _isSaved = false;

  // Auto-scroll functionality
  final Map<String, GlobalKey> _ticketGlobalKeys = {};
  bool _isAutoScrolling = false;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();

    // Initialize saved results service
    _initializeSavedResultsService();

    // Load lottery result details if uniqueId is provided
    if (widget.uniqueId != null) {
      context.read<LotteryResultDetailsBloc>().add(
            LoadLotteryResultDetailsEvent(widget.uniqueId!),
          );

      // Check if result is already saved
      _checkIfSaved();
    }
  }

  Future<void> _initializeSavedResultsService() async {
    try {
      await SavedResultsService.init();
    } catch (e) {
      print('Error initializing SavedResultsService: $e');
    }
  }

  void _checkIfSaved() {
    if (widget.uniqueId != null) {
      setState(() {
        _isSaved = SavedResultsService.isResultSaved(widget.uniqueId!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeLotteryNumbers(LotteryResultModel result) {
    _allLotteryNumbers.clear();

    // Custom ordering: 1st prize, then consolation, then other prizes
    final prizes = result.prizes;

    // Add 1st prize numbers first
    final firstPrize = result.getFirstPrize();
    if (firstPrize != null) {
      _addPrizeNumbers(firstPrize);
    }

    // Add consolation prize numbers second
    final consolationPrize = result.getConsolationPrize();
    if (consolationPrize != null) {
      _addPrizeNumbers(consolationPrize);
    }

    // Add remaining prizes (2nd to 10th)
    final remainingPrizes = prizes
        .where((prize) =>
            prize.prizeType != '1st' && prize.prizeType != 'consolation')
        .toList();

    // Sort remaining prizes by prize type
    remainingPrizes.sort((a, b) {
      final prizeOrder = [
        '2nd',
        '3rd',
        '4th',
        '5th',
        '6th',
        '7th',
        '8th',
        '9th',
        '10th'
      ];
      final aIndex = prizeOrder.indexOf(a.prizeType);
      final bIndex = prizeOrder.indexOf(b.prizeType);
      return aIndex.compareTo(bIndex);
    });

    for (final prize in remainingPrizes) {
      _addPrizeNumbers(prize);
    }

    // Initialize filtered list
    _filteredLotteryNumbers = List.from(_allLotteryNumbers);
  }

  void _addPrizeNumbers(PrizeModel prize) {
    // For prizes with tickets array (individual tickets with locations)
    for (final ticket in prize.ticketsWithLocation) {
      _allLotteryNumbers.add({
        'number': ticket.ticketNumber,
        'category': prize.prizeTypeFormatted,
        'prize': prize.formattedPrizeAmount,
        'location': ticket.location ?? '',
      });
    }

    // For prizes with ticket_numbers string (grid format)
    for (final ticketNumber in prize.allTicketNumbers) {
      // Skip if already added from tickets array
      if (!prize.ticketsWithLocation
          .any((t) => t.ticketNumber == ticketNumber)) {
        _allLotteryNumbers.add({
          'number': ticketNumber,
          'category': prize.prizeTypeFormatted,
          'prize': prize.formattedPrizeAmount,
          'location': '',
        });
      }
    }
  }

  // Updated method to handle search functionality with minimum length
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _lastSearchQuery = _searchQuery;

      // Only perform search if query is empty or meets minimum length
      if (_searchQuery.isEmpty) {
        _filteredLotteryNumbers = List.from(_allLotteryNumbers);
        _clearTicketKeys();
      } else if (_searchQuery.length >= _minSearchLength) {
        _filteredLotteryNumbers = _allLotteryNumbers.where((item) {
          final ticketNumber = item['number'].toString().toLowerCase();
          final searchLower = _searchQuery.toLowerCase();
          return ticketNumber.contains(searchLower);
        }).toList();
        
        // Generate GlobalKeys for matched tickets
        _generateTicketKeys();
        
        // Schedule auto-scroll after widget rebuild completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Add additional delay to ensure widgets are fully built with new keys
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && _searchQuery == _lastSearchQuery && _filteredLotteryNumbers.isNotEmpty) {
              _triggerAutoScroll();
            }
          });
        });
      } else {
        // If query is less than minimum length, show all numbers
        _filteredLotteryNumbers = List.from(_allLotteryNumbers);
        _clearTicketKeys();
      }
    });
  }

  // Generate GlobalKeys for matched tickets
  void _generateTicketKeys() {
    _ticketGlobalKeys.clear();
    
    for (final item in _filteredLotteryNumbers) {
      final ticketNumber = item['number'].toString();
      final category = item['category'].toString();
      final keyId = '${category}_$ticketNumber';
      _ticketGlobalKeys[keyId] = GlobalKey();
    }
  }

  // Clear ticket keys
  void _clearTicketKeys() {
    _ticketGlobalKeys.clear();
  }

  // Trigger auto-scroll to first match
  void _triggerAutoScroll() {
    if (_filteredLotteryNumbers.isNotEmpty && !_isAutoScrolling) {
      _scrollToFirstMatch();
    }
  }

  // Scroll to the first matching ticket
  void _scrollToFirstMatch() {
    if (_filteredLotteryNumbers.isEmpty || _ticketGlobalKeys.isEmpty || _isAutoScrolling) {
      return;
    }

    try {
      _isAutoScrolling = true;
      
      // Find the best match based on search query or use first match
      Map<String, dynamic>? targetMatch;
      
      if (_searchQuery.isNotEmpty && _searchQuery.length >= _minSearchLength) {
        // Try to find the most relevant match for the search query
        targetMatch = _filteredLotteryNumbers.firstWhere(
          (item) {
            final ticketNumber = item['number'].toString().toLowerCase();
            final searchLower = _searchQuery.toLowerCase();
            return ticketNumber.contains(searchLower);
          },
          orElse: () => _filteredLotteryNumbers.first,
        );
      } else {
        // Use first match if no specific search query
        targetMatch = _filteredLotteryNumbers.first;
      }
      
      final ticketNumber = targetMatch['number'].toString();
      final category = targetMatch['category'].toString();
      final keyId = '${category}_$ticketNumber';
      
      final globalKey = _ticketGlobalKeys[keyId];
      if (globalKey?.currentContext != null) {
        // Scroll to the widget with smooth animation
        Scrollable.ensureVisible(
          globalKey!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.2,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        ).then((_) {
          // Reset auto-scrolling flag after animation completes
          if (mounted) {
            setState(() {
              _isAutoScrolling = false;
            });
          }
        });
      } else {
        // If context is not available yet, try again after a longer delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _searchQuery == _lastSearchQuery) {
            setState(() {
              _isAutoScrolling = false;
            });
            _scrollToFirstMatch();
          }
        });
      }
    } catch (e) {
      // Handle any scrolling errors gracefully
      if (mounted) {
        setState(() {
          _isAutoScrolling = false;
        });
      }
    }
  }


  Future<void> _toggleSaveResult(LotteryResultModel result) async {
    try {
      if (_isSaved) {
        // Remove from saved
        final success =
            await SavedResultsService.removeSavedResult(result.uniqueId);
        if (success) {
          setState(() {
            _isSaved = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.bookmark_remove, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Removed from saved results'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Save result
        final success = await SavedResultsService.saveLotteryResult(result);
        if (success) {
          setState(() {
            _isSaved = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.bookmark_added, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Saved to your collection'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    // Navigate to saved results screen
                    context.go('/saved-results');
                  },
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Failed to save result'),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Add method to clear search
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _filteredLotteryNumbers = List.from(_allLotteryNumbers);
    });
  }

  // Helper method to check if search is active
  bool get _isSearchActive =>
      _searchQuery.isNotEmpty && _searchQuery.length >= _minSearchLength;

  // PDF sharing functionality
  Future<void> _shareResultAsPdf(LotteryResultModel result) async {
    if (_isGeneratingPdf) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Generating PDF...'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }

      // Generate and share PDF
      await PdfService.generateAndShareLotteryResult(result);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('PDF generated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to generate PDF: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _shareResultAsPdf(result),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  // Method to format lottery result as text
  String _formatLotteryResultText(LotteryResultModel result) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('KERALA STATE LOTTERIES - RESULT (LOTTO APP)');
    buffer.writeln('${result.lotteryName.toUpperCase()} DRAW NO: ${result.drawNumber}');
    buffer.writeln('DRAW HELD ON: ${result.formattedDate}');
    buffer.writeln('=' * 36);
    buffer.writeln();
    
    // Prizes in order
    final prizes = result.prizes;
    
    // First prize
    final firstPrize = result.getFirstPrize();
    if (firstPrize != null) {
      buffer.writeln('${firstPrize.prizeTypeFormatted} Rs : ${firstPrize.formattedPrizeAmount}/-');
      for (final ticket in firstPrize.ticketsWithLocation) {
        buffer.writeln('  ${ticket.ticketNumber} (${ticket.location ?? 'N/A'})');
      }
      buffer.writeln();
    }
    
    // Consolation prize
    final consolationPrize = result.getConsolationPrize();
    if (consolationPrize != null) {
      buffer.writeln('${consolationPrize.prizeTypeFormatted} Rs : ${consolationPrize.formattedPrizeAmount}/-');
      final numbers = consolationPrize.allTicketNumbers.join(', ');
      buffer.writeln('  $numbers');
      buffer.writeln();
    }
    
    // Remaining prizes (2nd to 10th)
    final remainingPrizes = prizes
        .where((prize) => prize.prizeType != '1st' && prize.prizeType != 'consolation')
        .toList();
    
    // Sort remaining prizes
    remainingPrizes.sort((a, b) {
      final prizeOrder = ['2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
      final aIndex = prizeOrder.indexOf(a.prizeType);
      final bIndex = prizeOrder.indexOf(b.prizeType);
      return aIndex.compareTo(bIndex);
    });
    
    buffer.writeln('FOR THE TICKETS ENDING WITH THE FOLLOWING NUMBERS:');
    buffer.writeln();
    
    for (final prize in remainingPrizes) {
      buffer.writeln('${prize.prizeTypeFormatted} – Rs: ${prize.formattedPrizeAmount}/-');
      final numbers = prize.allTicketNumbers.join(', ');
      buffer.writeln('  $numbers');
      buffer.writeln();
    }
    
    // Footer
    buffer.writeln('=' * 50);
    buffer.writeln('The prize winners are advised to verify the winning numbers');
    buffer.writeln('with the results published in the Kerala Government Gazette');
    buffer.writeln('and surrender the winning tickets within 90 days.');
    buffer.writeln();
    buffer.writeln('Contact: 0471-2305230');
    buffer.writeln('Email: cru.dir.lotteries@kerala.gov.in');
    buffer.writeln('Visit: https://lottokeralalotteries.com/');
    
    return buffer.toString();
  }

  // Method to copy result text and show share options
  Future<void> _copyAndShareResult(LotteryResultModel result) async {
    try {
      final resultText = _formatLotteryResultText(result);
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: resultText));
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
              
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Result copied to clipboard'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => _shareResultText(result),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to copy: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Method to share result text
  Future<void> _shareResultText(LotteryResultModel result) async {
    try {
      final resultText = _formatLotteryResultText(result);
      final subject = 'Kerala Lottery Result: ${result.lotteryName} - Draw ${result.drawNumber}';
      
      await Share.share(
        resultText,
        subject: subject,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to share: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, context),
      body: Stack(
        children: [
          BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
            builder: (context, state) {
              if (state is LotteryResultDetailsLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is LotteryResultDetailsError) {
                return _buildErrorWidget(theme, state.message);
              } else if (state is LotteryResultDetailsLoaded) {
                // Initialize lottery numbers
                _initializeLotteryNumbers(state.data.result);

                return _buildLoadedContent(theme, state.data.result);
              } else {
                return _buildInitialWidget(theme);
              }
            },
          ),
          // Add FloatingSearchBar only when data is loaded
          BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
            builder: (context, state) {
              if (state is LotteryResultDetailsLoaded &&
                  _allLotteryNumbers.isNotEmpty) {
                return FloatingSearchBar(
                  hintText: 'Eg. PV409930,',
                  onChanged: (query) {
                    // Implement real-time search
                    _performSearch(query);
                  },
                  onSubmitted: (query) {
                    // Implement search on submit
                    _performSearch(query);
                  },
                  bottomPadding: 20.0,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(ThemeData theme, LotteryResultModel result) {
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.uniqueId != null) {
          context.read<LotteryResultDetailsBloc>().add(
                RefreshLotteryResultDetailsEvent(widget.uniqueId!),
              );
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(theme, result),
              const SizedBox(height: 6),
              // Show search results info if searching
              if (_isSearchActive) _buildSearchResultsInfo(theme),
              // Show search instruction if query is too short
              if (_searchQuery.isNotEmpty && !_isSearchActive)
                _buildSearchInstructionInfo(theme),
              const SizedBox(height: 6),
              DynamicPrizeSectionsWidget(
                key: ValueKey('prize_sections_${result.uniqueId}'),
                result: result,
                allLotteryNumbers: _isSearchActive
                    ? _filteredLotteryNumbers
                    : _allLotteryNumbers,
                highlightedTicketNumber: _isSearchActive ? _searchQuery : '',
                ticketGlobalKeys: _ticketGlobalKeys,
              ),
              const SizedBox(height: 6),
              _buildContactSection(theme),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Found ${_filteredLotteryNumbers.length} result${_filteredLotteryNumbers.length != 1 ? 's' : ''} for "$_searchQuery"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _clearSearch();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInstructionInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enter at least $_minSearchLength digits to search (${_searchQuery.length}/$_minSearchLength)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme, LotteryResultModel result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                result.formattedDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.tag,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                result.formattedDrawNumber,
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
              child: Text(
                'Visit Official Website',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  AppBar _buildAppBar(ThemeData theme, BuildContext context) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
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
        // Copy Button
        BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
          builder: (context, state) {
            if (state is LotteryResultDetailsLoaded) {
              return IconButton(
                icon: Icon(
                  Icons.content_copy,
                  color: theme.appBarTheme.actionsIconTheme?.color,
                ),
                onPressed: () => _copyAndShareResult(state.data.result),
                tooltip: 'Copy result',
              );
            }
            return IconButton(
              icon: Icon(Icons.content_copy,
                  color: theme.appBarTheme.actionsIconTheme?.color),
              onPressed: null, // Disabled when no data
            );
          },
        ),
        // Updated Share Button with PDF generation
        BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
          builder: (context, state) {
            if (state is LotteryResultDetailsLoaded) {
              return IconButton(
                icon: _isGeneratingPdf
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.appBarTheme.actionsIconTheme?.color ??
                                theme.primaryColor,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.share,
                        color: theme.appBarTheme.actionsIconTheme?.color,
                      ),
                onPressed: _isGeneratingPdf
                    ? null
                    : () => _shareResultAsPdf(state.data.result),
                tooltip: 'Share as PDF',
              );
            }
            return IconButton(
              icon: Icon(Icons.share,
                  color: theme.appBarTheme.actionsIconTheme?.color),
              onPressed: null, // Disabled when no data
            );
          },
        ),
        // Updated Save/Bookmark Button
        BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
          builder: (context, state) {
            if (state is LotteryResultDetailsLoaded) {
              return IconButton(
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: _isSaved
                      ? theme.primaryColor
                      : theme.appBarTheme.actionsIconTheme?.color,
                ),
                onPressed: () => _toggleSaveResult(state.data.result),
                tooltip: _isSaved ? 'Remove from saved' : 'Save result',
              );
            }
            return IconButton(
              icon: Icon(Icons.bookmark_outline,
                  color: theme.appBarTheme.actionsIconTheme?.color),
              onPressed: null, // Disabled when no data
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed Loading Result',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
         
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.uniqueId != null) {
                  context.read<LotteryResultDetailsBloc>().add(
                        LoadLotteryResultDetailsEvent(widget.uniqueId!),
                      );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Lottery Result Selected',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a lottery result to view details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
