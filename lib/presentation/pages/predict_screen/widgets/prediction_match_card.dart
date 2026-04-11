import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/data/models/predict_screen/prediction_match_model.dart';
import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';
import 'package:lotto_app/data/services/prediction_match_service.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/prediction_match_ui_components.dart';

class PredictionMatchCard extends StatefulWidget {
  final int selectedPrizeType;
  final List<RepeatedNumber> repeatedNumbers;

  const PredictionMatchCard({
    super.key,
    required this.selectedPrizeType,
    this.repeatedNumbers = const [],
  });

  @override
  State<PredictionMatchCard> createState() => PredictionMatchCardState();
}

class PredictionMatchCardState extends State<PredictionMatchCard> {
  bool _isLoading = false;
  PredictionMatchModel? _matchResult;
  bool _hasData = false;

  /// Public method to update prize type from external components
  /// Note: comparison always covers all prize types (5th–9th), no reload needed
  void updatePrizeType(int newPrizeType) {
    // No-op: prize type doesn't affect the match comparison (always checks 5th–9th)
  }

  @override
  void initState() {
    super.initState();
    _loadPredictionMatches();
  }

  @override
  void didUpdateWidget(PredictionMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload only when repeated numbers change (new lottery draw data)
    final repeatedNumbersChanged =
        oldWidget.repeatedNumbers.length != widget.repeatedNumbers.length ||
            !_areRepeatedNumbersEqual(
                oldWidget.repeatedNumbers, widget.repeatedNumbers);

    if (repeatedNumbersChanged) {
      _loadPredictionMatches();
    }
  }

  /// Helper to compare repeated numbers lists
  bool _areRepeatedNumbersEqual(
      List<RepeatedNumber> a, List<RepeatedNumber> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].number != b[i].number || a[i].count != b[i].count) {
        return false;
      }
    }
    return true;
  }

  /// Loads prediction matches using the service layer
  Future<void> _loadPredictionMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final matchResult = await _fetchPredictionMatches();

      setState(() {
        _matchResult = matchResult;
        _hasData = matchResult != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _matchResult = null;
        _hasData = false;
        _isLoading = false;
      });
    }
  }

  /// Fetches and compares ALL predictions (5 prize types) + repeated numbers + cached variants with results
  Future<PredictionMatchModel?> _fetchPredictionMatches() async {
    // Get ALL predictions for prize types 5-9
    final allPredictions = <AiPredictionModel>[];
    for (int prizeType = 5; prizeType <= 9; prizeType++) {
      final prediction =
          await PredictionMatchService.getTodaysPrediction(prizeType);
      if (prediction != null) {
        allPredictions.add(prediction);
      }
    }

    if (allPredictions.isEmpty) {
      return null;
    }

    // Get results
    final homeResult = await PredictionMatchService.getTodaysResults();
    if (homeResult == null) {
      return null;
    }
    if (!homeResult.isPublished) {
      return null;
    }

    // Verify date matching
    final firstPrediction = allPredictions.first;
    if (firstPrediction.date != homeResult.date) {
      // Dates don't match - return null to show "no data" state
      return null;
    }

    // Collect ALL numbers to check (AI predictions + repeated numbers + cached variants)
    final allNumbersToCheck = <String>{};

    // 1. Add AI prediction numbers
    for (final prediction in allPredictions) {
      allNumbersToCheck.addAll(prediction.predictedNumbers);
    }

    // 2. Add most repeated numbers
    for (final repeatedNumber in widget.repeatedNumbers) {
      allNumbersToCheck.add(repeatedNumber.number);
    }

    // 3. Add cached number variants
    final cachedVariants = await _loadCachedNumberVariants();
    allNumbersToCheck.addAll(cachedVariants);

    // Try to get detailed results first
    final detailedResult =
        await PredictionMatchService.getDetailedResults(homeResult.uniqueId);

    Map<String, String> matchedNumbersWithPrizeType = {};
    bool hasDetailedData = false;

    if (detailedResult != null) {
      // Use comprehensive detailed comparison with ALL numbers
      matchedNumbersWithPrizeType = _compareNumbersWithDetailedResults(
        allNumbersToCheck.toList(),
        detailedResult,
      );
      hasDetailedData = true;
    } else {
      // Use fallback comparison with ALL numbers
      matchedNumbersWithPrizeType = _compareNumbersWithBasicResults(
        allNumbersToCheck.toList(),
        homeResult,
      );
    }

    return matchedNumbersWithPrizeType.isNotEmpty
        ? PredictionMatchModel.withMatches(
            allPredictions, matchedNumbersWithPrizeType, homeResult.lotteryName,
            homeResult.uniqueId,
            hasDetailedData: hasDetailedData)
        : PredictionMatchModel.noMatches(
            allPredictions, homeResult.lotteryName, homeResult.uniqueId);
  }

  /// Loads cached number variants from SharedPreferences
  Future<List<String>> _loadCachedNumberVariants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final variantsJson = prefs.getString('number_variants_last_results');

      if (variantsJson != null) {
        final List<dynamic> decoded = jsonDecode(variantsJson);
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Ignore errors, just return empty list
    }
    return [];
  }

  /// Compares numbers with detailed results
  Map<String, String> _compareNumbersWithDetailedResults(
    List<String> numbersToCheck,
    dynamic detailedResult,
  ) {
    final matchedNumbersWithPrizeType = <String, String>{};

    // Get all winning numbers from ALL prize types (5th to 9th)
    final allWinningNumbers = <String, String>{}; // number -> prize type

    for (int prizeType = 5; prizeType <= 9; prizeType++) {
      final prizeTypeString = _getPrizeTypeString(prizeType);
      final targetPrizes = detailedResult.getPrizesByType(prizeTypeString);

      for (final prize in targetPrizes) {
        final prizeNumbers = prize.getAllTicketNumbers();
        for (final number in prizeNumbers) {
          allWinningNumbers[number] = prizeTypeString;
        }
      }
    }

    // Compare ALL numbers against ALL winning numbers
    for (final number in numbersToCheck) {
      if (allWinningNumbers.containsKey(number)) {
        final winningPrizeType = allWinningNumbers[number]!;
        matchedNumbersWithPrizeType[number] = winningPrizeType;
      }
    }

    return matchedNumbersWithPrizeType;
  }

  /// Compares numbers with basic results (fallback)
  /// Checks last 4 digits of first prize, consolation, and all available prize numbers
  Map<String, String> _compareNumbersWithBasicResults(
    List<String> numbersToCheck,
    dynamic homeResult,
  ) {
    final matchedNumbersWithPrizeType = <String, String>{};

    // Map of last-4-digit number -> prize label
    final winningNumbers = <String, String>{};

    // 1st prize
    final firstPrizeNumber = homeResult.firstPrize.ticketNumber;
    if (firstPrizeNumber.length >= 4) {
      winningNumbers[firstPrizeNumber.substring(firstPrizeNumber.length - 4)] =
          '1st';
    }

    // Consolation prizes
    if (homeResult.hasConsolationPrizes) {
      for (final number in homeResult.consolationTicketsList) {
        if (number.length >= 4) {
          winningNumbers[number.substring(number.length - 4)] = 'Consolation';
        }
      }
    }

    // Compare ALL numbers against winning numbers
    for (final number in numbersToCheck) {
      if (winningNumbers.containsKey(number)) {
        matchedNumbersWithPrizeType[number] = winningNumbers[number]!;
      }
    }

    return matchedNumbersWithPrizeType;
  }

  /// Converts prize type number to string
  String _getPrizeTypeString(int prizeType) {
    switch (prizeType) {
      case 5:
        return '5th';
      case 6:
        return '6th';
      case 7:
        return '7th';
      case 8:
        return '8th';
      case 9:
        return '9th';
      default:
        return '5th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: theme.primaryColor,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return PredictionMatchUIComponents.buildLoadingWidget();
    }

    if (!_hasData || _matchResult == null) {
      return PredictionMatchUIComponents.buildNoDataWidget(theme);
    }

    if (!_matchResult!.hasMatches) {
      return PredictionMatchUIComponents.buildNoMatchWidget(
          theme, _matchResult!);
    }

    return PredictionMatchUIComponents.buildMatchFoundWidget(
        theme, _matchResult!);
  }
}
