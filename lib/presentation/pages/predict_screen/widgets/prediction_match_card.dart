import 'package:flutter/material.dart';
import 'package:lotto_app/data/models/predict_screen/prediction_match_model.dart';
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
    // Check if we should reset for new day (before 4:30 PM)
    if (PredictionMatchService.shouldResetForNewDay()) {
      setState(() {
        _matchResult = null;
        _hasData = false;
        _isLoading = false;
      });
      return;
    }
    
    // Check if results should be available (after 4:30 PM)
    if (!PredictionMatchService.shouldShowResults()) {
      setState(() {
        _hasData = false;
        _isLoading = false;
      });
      return;
    }

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

  /// Fetches and compares predictions with results
  Future<PredictionMatchModel?> _fetchPredictionMatches() async {
    // Get today's prediction
    final prediction = await PredictionMatchService.getTodaysPrediction(widget.selectedPrizeType);
    if (prediction == null) return null;

    // Get today's results
    final homeResult = await PredictionMatchService.getTodaysResults();
    if (homeResult == null || !homeResult.isPublished) return null;

    // Try to get detailed results first
    final detailedResult = await PredictionMatchService.getDetailedResults(homeResult.uniqueId);
    
    List<String> matchedNumbers;
    bool hasDetailedData = false;

    if (detailedResult != null) {
      // Use detailed comparison
      matchedNumbers = PredictionMatchService.compareWithDetailedResults(
        prediction.predictedNumbers,
        detailedResult,
        widget.selectedPrizeType,
      );
      hasDetailedData = true;
    } else {
      // Use fallback comparison
      matchedNumbers = PredictionMatchService.compareWithBasicResults(
        prediction.predictedNumbers,
        homeResult,
      );
    }

    return matchedNumbers.isNotEmpty
        ? PredictionMatchModel.withMatches(prediction, matchedNumbers, hasDetailedData: hasDetailedData)
        : PredictionMatchModel.noMatches(prediction);
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
    // Show waiting message before 4:30 PM
    if (!PredictionMatchService.shouldShowResults()) {
      return PredictionMatchUIComponents.buildWaitingWidget(theme);
    }

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