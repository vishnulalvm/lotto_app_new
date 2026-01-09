import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lottery_draw_cubit.dart';

/// Custom widget for selecting lottery and series
/// Displays two dropdowns side by side below the app bar
class LotterySeriesSelector extends StatefulWidget {
  const LotterySeriesSelector({super.key});

  @override
  State<LotterySeriesSelector> createState() => _LotterySeriesSelectorState();
}

class _LotterySeriesSelectorState extends State<LotterySeriesSelector> {
  // Lottery data with their unique letters
  static const Map<String, String> lotteryLetters = {
    'KARUNYA PLUS': 'P',
    'SUVARNA KERALAM': 'R',
    'KARUNYA': 'K',
    'SAMRUDHI': 'M',
    'BHAGYATHARA': 'B',
    'STHREE SAKTHI': 'S',
    'DHANALEKSHMI': 'D',
  };

  // Series types - mapped internally
  static const List<String> seriesType1 = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M'
  ];

  static const List<String> seriesType2 = [
    'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  // Series display strings (show actual letters)
  static const String series1Display = 'A B C D E F G H J K L M';
  static const String series2Display = 'N O P R S T U V W X Y Z';
  static const List<String> seriesOptions = [series1Display, series2Display];

  String? selectedLottery;
  String? selectedSeries;

  @override
  void initState() {
    super.initState();
    // Set default values
    selectedLottery = _getLotteryNameForToday();
    selectedSeries = series1Display; // Default to Series 1

    // Update the cubit with the initial lottery letter and series after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final letter = lotteryLetters[selectedLottery];
      if (letter != null && selectedLottery != null) {
        context.read<LotteryDrawCubit>().updateLotteryLetter(
          letter,
          lotteryName: selectedLottery!,
        );
      }
      // Set initial series letters (Series 1)
      context.read<LotteryDrawCubit>().updateSeriesLetters(seriesType1);
    });
  }

  /// Gets the lottery name based on the current day
  String _getLotteryNameForToday() {
    final now = DateTime.now();

    // If it's before 3 PM, show today's lottery
    // If it's after 3 PM, show tomorrow's lottery
    final targetDate = now.hour >= 15 ? now.add(const Duration(days: 1)) : now;
    final weekday = targetDate.weekday;

    switch (weekday) {
      case DateTime.sunday:
        return 'SAMRUDHI';
      case DateTime.monday:
        return 'BHAGYATHARA';
      case DateTime.tuesday:
        return 'STHREE SAKTHI';
      case DateTime.wednesday:
        return 'DHANALEKSHMI';
      case DateTime.thursday:
        return 'KARUNYA PLUS';
      case DateTime.friday:
        return 'SUVARNA KERALAM';
      case DateTime.saturday:
        return 'KARUNYA';
      default:
        return 'KARUNYA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF000000),
      child: Row(
        children: [
          // Lottery dropdown
          Expanded(
            child: _buildDropdown(
              value: selectedLottery,
              items: lotteryLetters.keys.toList(),
              hint: 'Select Lottery',
              onChanged: (value) {
                // Haptic feedback on selection
                HapticFeedback.selectionClick();

                setState(() {
                  selectedLottery = value;
                });
                // Update the cubit with the new lottery letter and name
                if (value != null) {
                  final letter = lotteryLetters[value];
                  if (letter != null) {
                    context.read<LotteryDrawCubit>().updateLotteryLetter(
                      letter,
                      lotteryName: value,
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // Series dropdown
          Expanded(
            child: _buildDropdown(
              value: selectedSeries,
              items: seriesOptions,
              hint: 'Select Series',
              onChanged: (value) {
                // Haptic feedback on selection
                HapticFeedback.selectionClick();

                setState(() {
                  selectedSeries = value;
                });
                // Update the cubit with the new series letters
                if (value != null) {
                  final letters = value == series1Display ? seriesType1 : seriesType2;
                  context.read<LotteryDrawCubit>().updateSeriesLetters(letters);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF2a2a2a),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 24,
          ),
          dropdownColor: const Color(0xFF1a1a1a),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList();
          },
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
