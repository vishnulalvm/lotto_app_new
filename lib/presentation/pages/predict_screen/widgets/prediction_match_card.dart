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
  State<PredictionMatchCard> createState() => PredictionMatchCardState();
}

class PredictionMatchCardState extends State<PredictionMatchCard> {
  bool _isLoading = false;
  PredictionMatchModel? _matchResult;
  bool _hasData = false;
  late int _currentPrizeType;

  /// Public method to update prize type from external components
  void updatePrizeType(int newPrizeType) {
    if (_currentPrizeType != newPrizeType) {
      _currentPrizeType = newPrizeType;
      _loadPredictionMatches();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPrizeType = widget.selectedPrizeType;
    _loadPredictionMatches();
  }

  @override
  void didUpdateWidget(PredictionMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPrizeType != widget.selectedPrizeType) {
      _currentPrizeType = widget.selectedPrizeType;
      _loadPredictionMatches();
    }
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

  /// Fetches and compares ALL predictions (5 prize types) with results
  Future<PredictionMatchModel?> _fetchPredictionMatches() async {
    
    
    // Get ALL predictions for prize types 5-9
    final allPredictions = <AiPredictionModel>[];
    for (int prizeType = 5; prizeType <= 9; prizeType++) {
      final prediction = await PredictionMatchService.getTodaysPrediction(prizeType);
      if (prediction != null) {
        allPredictions.add(prediction);
      } else {
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
    if (firstPrediction.date == homeResult.date) {
    } else {
    }

    // Try to get detailed results first
    final detailedResult = await PredictionMatchService.getDetailedResults(homeResult.uniqueId);
    
    Map<String, String> matchedNumbersWithPrizeType = {};
    bool hasDetailedData = false;

    if (detailedResult != null) {
      // Use comprehensive detailed comparison
      matchedNumbersWithPrizeType = PredictionMatchService.compareAllPredictionsWithDetailedResults(
        allPredictions,
        detailedResult,
      );
      hasDetailedData = true;
    } else {
      // Use fallback comparison
      matchedNumbersWithPrizeType = PredictionMatchService.compareAllPredictionsWithBasicResults(
        allPredictions,
        homeResult,
      );
    }


    return matchedNumbersWithPrizeType.isNotEmpty
        ? PredictionMatchModel.withMatches(allPredictions, matchedNumbersWithPrizeType, homeResult.lotteryName, hasDetailedData: hasDetailedData)
        : PredictionMatchModel.noMatches(allPredictions, homeResult.lotteryName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
          color:theme.cardColor,
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
      return PredictionMatchUIComponents.buildNoMatchWidget(theme, _matchResult!);
    }

    return PredictionMatchUIComponents.buildMatchFoundWidget(theme, _matchResult!);
  }
}