import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotto_app/data/services/lottery_info_service.dart';
import 'package:lotto_app/data/services/ai_prediction_loader_service.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/ai_prediction_state.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/ai_prediction_ui_components.dart';

class AiPredictionCard extends StatefulWidget {
  final int selectedPrizeType;
  final ValueChanged<int> onPrizeTypeChanged;
  
  const AiPredictionCard({
    super.key,
    required this.selectedPrizeType,
    required this.onPrizeTypeChanged,
  });

  @override
  State<AiPredictionCard> createState() => _AiPredictionCardState();
}

class _AiPredictionCardState extends State<AiPredictionCard> {
  AIPredictionState _state = const AIPredictionInitial();

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  @override
  void didUpdateWidget(AiPredictionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (AIPredictionLoaderService.shouldReloadForPrizeType(_state, widget.selectedPrizeType)) {
      _loadPrediction();
    }
  }

  Future<void> _loadPrediction() async {
    setState(() {
      _state = const AIPredictionLoading();
    });

    final newState = await AIPredictionLoaderService.loadPrediction(widget.selectedPrizeType);
    
    if (mounted) {
      setState(() {
        _state = newState;
      });
    }
  }

  void _onPrizeTypeChanged(int? newPrizeType) {
    if (newPrizeType != null && 
        newPrizeType != widget.selectedPrizeType &&
        LotteryInfoService.isValidPrizeType(newPrizeType)) {
      HapticFeedback.lightImpact();
      widget.onPrizeTypeChanged(newPrizeType);
      // Note: _loadPrediction will be called via didUpdateWidget
    }
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
            AIPredictionUIComponents.buildHeader(theme),
            const SizedBox(height: 20),
            AIPredictionUIComponents.buildPrizeTypeSelector(
              theme,
              widget.selectedPrizeType,
              _onPrizeTypeChanged,
            ),
            const SizedBox(height: 20),
            AIPredictionUIComponents.buildStateContent(theme, _state),
          ],
        ),
      ),
    );
  }
}