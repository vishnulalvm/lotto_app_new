import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AutoScrollHelper {
  /// Scrolls to the first matching ticket in the filtered list
  ///
  /// Parameters:
  /// - [filteredLotteryNumbers]: List of filtered lottery numbers
  /// - [ticketGlobalKeys]: Map of global keys for each ticket
  /// - [searchQuery]: Current search query
  /// - [minSearchLength]: Minimum search length required
  /// - [isAutoScrolling]: Current auto-scrolling state
  /// - [lastSearchQuery]: Last search query for comparison
  /// - [mounted]: Widget mounted state
  /// - [onAutoScrollingChanged]: Callback to update auto-scrolling state
  /// - [onRetry]: Callback to retry scrolling
  static Future<void> scrollToFirstMatch({
    required List<Map<String, dynamic>> filteredLotteryNumbers,
    required Map<String, GlobalKey> ticketGlobalKeys,
    required String searchQuery,
    required int minSearchLength,
    required bool isAutoScrolling,
    required String lastSearchQuery,
    required bool mounted,
    required Function(bool) onAutoScrollingChanged,
    required VoidCallback onRetry,
  }) async {
    if (filteredLotteryNumbers.isEmpty ||
        ticketGlobalKeys.isEmpty ||
        isAutoScrolling) {
      return;
    }

    try {
      onAutoScrollingChanged(true);

      // Find the best match based on search query or use first match
      Map<String, dynamic>? targetMatch;

      if (searchQuery.isNotEmpty && searchQuery.length >= minSearchLength) {
        // Try to find the most relevant match for the search query
        targetMatch = filteredLotteryNumbers.firstWhere(
          (item) {
            final ticketNumber = item['number'].toString().toLowerCase();
            final searchLower = searchQuery.toLowerCase();
            return ticketNumber.contains(searchLower);
          },
          orElse: () => filteredLotteryNumbers.first,
        );
      } else {
        // Use first match if no specific search query
        targetMatch = filteredLotteryNumbers.first;
      }

      final ticketNumber = targetMatch['number'].toString();
      final category = targetMatch['category'].toString();
      final keyId = '${category}_$ticketNumber';

      final globalKey = ticketGlobalKeys[keyId];
      if (globalKey?.currentContext != null) {
        // Scroll to the widget with smooth animation
        await Scrollable.ensureVisible(
          globalKey!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.2,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );

        // Reset auto-scrolling flag after animation completes
        if (mounted) {
          // Provide subtle haptic feedback when auto-scroll completes
          HapticFeedback.selectionClick();
          onAutoScrollingChanged(false);
        }
      } else {
        // If context is not available yet, try again after a longer delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && searchQuery == lastSearchQuery) {
            onAutoScrollingChanged(false);
            onRetry();
          }
        });
      }
    } catch (e) {
      // Handle any scrolling errors gracefully
      if (mounted) {
        onAutoScrollingChanged(false);
      }
    }
  }

  /// Triggers auto-scroll if conditions are met
  static void triggerAutoScroll({
    required List<Map<String, dynamic>> filteredLotteryNumbers,
    required bool isAutoScrolling,
    required VoidCallback onScroll,
  }) {
    if (filteredLotteryNumbers.isNotEmpty && !isAutoScrolling) {
      onScroll();
    }
  }
}
