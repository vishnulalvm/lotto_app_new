import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotto_app/data/services/lottery_info_service.dart';
import 'package:lotto_app/data/services/ai_prediction_loader_service.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/ai_prediction_state.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/ai_prediction_ui_components.dart';

class AiPredictionCard extends StatefulWidget {
  final int? initialPrizeType;
  final ValueChanged<int>? onPrizeTypeChanged;
  
  const AiPredictionCard({
    super.key,
    this.initialPrizeType,
    this.onPrizeTypeChanged,
  });

  @override
  State<AiPredictionCard> createState() => _AiPredictionCardState();
}

class _AiPredictionCardState extends State<AiPredictionCard> {
  AIPredictionState _state = const AIPredictionInitial();
  late int _selectedPrizeType;

  @override
  void initState() {
    super.initState();
    _selectedPrizeType = widget.initialPrizeType ?? 5;
    _loadPrediction();
  }

  @override
  void didUpdateWidget(AiPredictionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if external prize type changes
    if (widget.initialPrizeType != null && 
        widget.initialPrizeType != oldWidget.initialPrizeType &&
        widget.initialPrizeType != _selectedPrizeType) {
      _selectedPrizeType = widget.initialPrizeType!;
      if (AIPredictionLoaderService.shouldReloadForPrizeType(_state, _selectedPrizeType)) {
        _loadPrediction();
      }
    }
  }

  Future<void> _loadPrediction() async {
    setState(() {
      _state = const AIPredictionLoading();
    });

    final newState = await AIPredictionLoaderService.loadPrediction(_selectedPrizeType);
    
    if (mounted) {
      setState(() {
        _state = newState;
      });
    }
  }

  void _onPrizeTypeChanged(int? newPrizeType) {
    if (newPrizeType != null && 
        newPrizeType != _selectedPrizeType &&
        LotteryInfoService.isValidPrizeType(newPrizeType)) {
      HapticFeedback.lightImpact();
      
      setState(() {
        _selectedPrizeType = newPrizeType;
      });
      
      // Notify parent if callback is provided
      widget.onPrizeTypeChanged?.call(newPrizeType);
      
      // Reload prediction for new prize type
      _loadPrediction();
    }
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
            AIPredictionUIComponents.buildHeader(theme),
            const SizedBox(height: 20),
            AIPredictionUIComponents.buildPrizeTypeSelector(
              theme,
              _selectedPrizeType,
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