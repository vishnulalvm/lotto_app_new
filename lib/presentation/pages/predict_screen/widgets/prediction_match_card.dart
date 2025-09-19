import 'package:flutter/material.dart';
import 'package:lotto_app/data/models/predict_screen/prediction_match_model.dart';
import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';
import 'package:lotto_app/data/services/prediction_match_service.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/prediction_match_ui_components.dart';

class PredictionMatchCard extends StatefulWidget {
  final int selectedPrizeType;
  
  const PredictionMatchCard({
    super.key,
    required this.selectedPrizeType,
  });

  @override
  State<PredictionMatchCard> createState() => _PredictionMatchCardState();
}

class _PredictionMatchCardState extends State<PredictionMatchCard> {
  bool _isLoading = false;
  PredictionMatchModel? _matchResult;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _loadPredictionMatches();
  }

  @override
  void didUpdateWidget(PredictionMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPrizeType != widget.selectedPrizeType) {
      _loadPredictionMatches();
    }
  }

  /// Loads prediction matches using the service layer
  Future<void> _loadPredictionMatches() async {
    debugPrint('🚀 [PredictionMatchCard] Starting to load prediction matches for prize type: ${widget.selectedPrizeType}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      final matchResult = await _fetchPredictionMatches();
      debugPrint('📊 [PredictionMatchCard] Match result: ${matchResult != null ? "Found" : "None"}, hasMatches: ${matchResult?.hasMatches}');
      if (matchResult != null) {
        int totalPredictions = 0;
        for (final prediction in matchResult.allPredictions) {
          totalPredictions += prediction.predictedNumbers.length;
        }
        debugPrint('🎯 [PredictionMatchCard] Matched numbers: ${matchResult.matchedNumbers}, Total predictions checked: $totalPredictions');
      }
      
      setState(() {
        _matchResult = matchResult;
        _hasData = matchResult != null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [PredictionMatchCard] Error loading matches: $e');
      setState(() {
        _matchResult = null;
        _hasData = false;
        _isLoading = false;
      });
    }
  }

  /// Fetches and compares ALL predictions (5 prize types) with results
  Future<PredictionMatchModel?> _fetchPredictionMatches() async {
    final now = DateTime.now();
    final isAfter430PM = now.hour > 16 || (now.hour == 16 && now.minute >= 30);
    
    debugPrint('📝 [PredictionMatchCard] === COMPREHENSIVE PREDICTION MATCH PROCESS START ===');
    debugPrint('🕐 [PredictionMatchCard] Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    debugPrint('⏰ [PredictionMatchCard] After 4:30 PM: $isAfter430PM');
    debugPrint('🎲 [PredictionMatchCard] Getting ALL predictions for prize types 5-9');
    
    // Get ALL predictions for prize types 5-9
    final allPredictions = <AiPredictionModel>[];
    for (int prizeType = 5; prizeType <= 9; prizeType++) {
      final prediction = await PredictionMatchService.getTodaysPrediction(prizeType);
      if (prediction != null) {
        allPredictions.add(prediction);
        debugPrint('✅ [PredictionMatchCard] Got prediction for prize type $prizeType: ${prediction.predictedNumbers.length} numbers');
      } else {
        debugPrint('❌ [PredictionMatchCard] No prediction found for prize type $prizeType');
      }
    }
    
    if (allPredictions.isEmpty) {
      debugPrint('❌ [PredictionMatchCard] No predictions found for any prize type');
      return null;
    }

    // Get results
    final homeResult = await PredictionMatchService.getTodaysResults();
    if (homeResult == null) {
      debugPrint('❌ [PredictionMatchCard] No home results found');
      return null;
    }
    if (!homeResult.isPublished) {
      debugPrint('⚠️ [PredictionMatchCard] Results not published yet for date: ${homeResult.date}');
      return null;
    }
    debugPrint('✅ [PredictionMatchCard] RESULT: date=${homeResult.date}, lottery=${homeResult.lotteryName}');
    
    // Verify date matching
    final firstPrediction = allPredictions.first;
    if (firstPrediction.date == homeResult.date) {
      debugPrint('🎯 [PredictionMatchCard] ✅ DATES MATCH: Comparing ${firstPrediction.date} predictions vs ${homeResult.date} result');
    } else {
      debugPrint('⚠️ [PredictionMatchCard] ❌ DATE MISMATCH: Comparing ${firstPrediction.date} predictions vs ${homeResult.date} result');
    }

    // Try to get detailed results first
    final detailedResult = await PredictionMatchService.getDetailedResults(homeResult.uniqueId);
    
    Map<String, String> matchedNumbersWithPrizeType = {};
    bool hasDetailedData = false;

    if (detailedResult != null) {
      debugPrint('🔍 [PredictionMatchCard] Using detailed comparison for ALL prize types');
      // Use comprehensive detailed comparison
      matchedNumbersWithPrizeType = PredictionMatchService.compareAllPredictionsWithDetailedResults(
        allPredictions,
        detailedResult,
      );
      hasDetailedData = true;
    } else {
      debugPrint('🔍 [PredictionMatchCard] Using basic comparison (fallback)');
      // Use fallback comparison
      matchedNumbersWithPrizeType = PredictionMatchService.compareAllPredictionsWithBasicResults(
        allPredictions,
        homeResult,
      );
    }

    debugPrint('🎯 [PredictionMatchCard] FINAL COMPREHENSIVE RESULT: ${matchedNumbersWithPrizeType.length} matches found');
    for (final entry in matchedNumbersWithPrizeType.entries) {
      debugPrint('🏆 [PredictionMatchCard] Match: ${entry.key} from ${entry.value} prize');
    }
    debugPrint('🏆 [PredictionMatchCard] Using lottery name for UI: ${homeResult.lotteryName}');
    debugPrint('📝 [PredictionMatchCard] === COMPREHENSIVE PREDICTION MATCH PROCESS END ===');

    return matchedNumbersWithPrizeType.isNotEmpty
        ? PredictionMatchModel.withMatches(allPredictions, matchedNumbersWithPrizeType, homeResult.lotteryName, hasDetailedData: hasDetailedData)
        : PredictionMatchModel.noMatches(allPredictions, homeResult.lotteryName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      return PredictionMatchUIComponents.buildNoMatchWidget(theme, _matchResult!);
    }

    return PredictionMatchUIComponents.buildMatchFoundWidget(theme, _matchResult!);
  }
}