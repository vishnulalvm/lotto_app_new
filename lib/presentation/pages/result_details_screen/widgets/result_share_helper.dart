import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/services/pdf_service.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/lottery_result_text_formatter.dart';

class ResultShareHelper {
  /// Shares the lottery result as a PDF file
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing SnackBars
  /// - [result]: LotteryResultModel to share
  /// - [isGenerating]: Current PDF generation state
  /// - [onGeneratingChanged]: Callback to update PDF generation state
  /// - [mounted]: Widget mounted state
  static Future<void> shareResultAsPdf({
    required BuildContext context,
    required LotteryResultModel result,
    required bool isGenerating,
    required Function(bool) onGeneratingChanged,
    required bool mounted,
  }) async {
    if (isGenerating) return;

    onGeneratingChanged(true);

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

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('PDF generated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
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
              onPressed: () => shareResultAsPdf(
                context: context,
                result: result,
                isGenerating: isGenerating,
                onGeneratingChanged: onGeneratingChanged,
                mounted: mounted,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        onGeneratingChanged(false);
      }
    }
  }

  /// Copies the lottery result text to clipboard and shows share option
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing SnackBars
  /// - [result]: LotteryResultModel to copy
  /// - [mounted]: Widget mounted state
  static Future<void> copyAndShareResult({
    required BuildContext context,
    required LotteryResultModel result,
    required bool mounted,
  }) async {
    try {
      final resultText = LotteryResultTextFormatter.format(result);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: resultText));

      if (mounted && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Result copied to clipboard'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => shareResultText(
                context: context,
                result: result,
                mounted: mounted,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to copy: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Shares the lottery result as text using the platform share dialog
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing SnackBars
  /// - [result]: LotteryResultModel to share
  /// - [mounted]: Widget mounted state
  static Future<void> shareResultText({
    required BuildContext context,
    required LotteryResultModel result,
    required bool mounted,
  }) async {
    try {
      final resultText = LotteryResultTextFormatter.format(result);

      final shareParams = ShareParams(
        text: resultText,
        subject: 'Lottery Results',
      );

      final shareResult = await SharePlus.instance.share(shareParams);

      if (!mounted || !context.mounted) return;

      if (shareResult.status == ShareResultStatus.unavailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing is unavailable on this platform'),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to share: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
