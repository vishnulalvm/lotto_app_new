import 'package:lotto_app/data/models/results_screen/results_screen.dart';

class LotteryResultTextFormatter {
  static String format(LotteryResultModel result) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('KERALA STATE LOTTERIES - RESULT');
    buffer.writeln(
        '${result.lotteryName.toUpperCase()} DRAW NO: ${result.drawNumber}');
    buffer.writeln(result.formattedDate);
    buffer.writeln();
    buffer.writeln('Download App: https://play.google.com/store/apps/details?id=app.solidapps.lotto');
    buffer.writeln();
    buffer.writeln('=' * 34);
    buffer.writeln();

    // Prizes in order
    final prizes = result.prizes;

    // First prize
    final firstPrize = result.getFirstPrize();
    if (firstPrize != null) {
      buffer.writeln('*${firstPrize.prizeTypeFormatted}*');
      buffer.writeln('Amount: ${firstPrize.formattedPrizeAmount}');
      for (final ticket in firstPrize.ticketsWithLocation) {
        buffer
            .writeln('${ticket.ticketNumber} (${ticket.location ?? 'N/A'})');
      }
      buffer.writeln();
    }

    // Consolation prize
    final consolationPrize = result.getConsolationPrize();
    if (consolationPrize != null) {
      buffer.writeln(
          '*${consolationPrize.prizeTypeFormatted}*');
      buffer.writeln('Amount: ${consolationPrize.formattedPrizeAmount}');
      final numbers = result.getPrizeTicketNumbers(consolationPrize).join('  ');
      buffer.writeln(numbers);
      buffer.writeln();
    }

    // Remaining prizes (2nd to 10th)
    final remainingPrizes = prizes
        .where((prize) =>
            prize.prizeType != '1st' && prize.prizeType != 'consolation')
        .toList();

    // Sort remaining prizes
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

    // Handle 2nd and 3rd prizes with location (like 1st prize)
    final secondPrize = remainingPrizes.where((p) => p.prizeType == '2nd').firstOrNull;
    final thirdPrize = remainingPrizes.where((p) => p.prizeType == '3rd').firstOrNull;

    if (secondPrize != null) {
      buffer.writeln('*${secondPrize.prizeTypeFormatted}*');
      buffer.writeln('Amount: ${secondPrize.formattedPrizeAmount}');
      if (secondPrize.ticketsWithLocation.isNotEmpty) {
        // Show with location like 1st prize
        for (final ticket in secondPrize.ticketsWithLocation) {
          buffer.writeln('${ticket.ticketNumber} (${ticket.location ?? 'N/A'})');
        }
      } else {
        // Fallback to regular numbers
        final numbers = result.getPrizeTicketNumbers(secondPrize).join('  ');
        buffer.writeln(numbers);
      }
      buffer.writeln();
    }

    if (thirdPrize != null) {
      buffer.writeln('*${thirdPrize.prizeTypeFormatted}*');
      buffer.writeln('Amount: ${thirdPrize.formattedPrizeAmount}');
      if (thirdPrize.ticketsWithLocation.isNotEmpty) {
        // Show with location like 1st prize
        for (final ticket in thirdPrize.ticketsWithLocation) {
          buffer.writeln('${ticket.ticketNumber} (${ticket.location ?? 'N/A'})');
        }
      } else {
        // Fallback to regular numbers
        final numbers = result.getPrizeTicketNumbers(thirdPrize).join('  ');
        buffer.writeln(numbers);
      }
      buffer.writeln();
    }

    // Handle remaining prizes (4th to 10th) - these typically don't have locations
    final lowerPrizes = remainingPrizes.where((p) =>
        p.prizeType != '2nd' && p.prizeType != '3rd').toList();

    if (lowerPrizes.isNotEmpty) {

      for (final prize in lowerPrizes) {
        buffer.writeln('*${prize.prizeTypeFormatted}*');
        buffer.writeln('Amount: ${prize.formattedPrizeAmount}');
        final numbers = result.getPrizeTicketNumbers(prize).join('  ');
        buffer.writeln(numbers);
        buffer.writeln();
      }
    }
    buffer.writeln();
    // Footer
    buffer.writeln('=' * 34);
    buffer.writeln();
    buffer
        .writeln('The prize winners are advised to verify the winning numbers');
    buffer
        .writeln('with the results published in the Kerala Government Gazette');
    buffer.writeln('and surrender the winning tickets within 90 days.');
    buffer.writeln();
    buffer.writeln('Contact: 0471-2305230');
    buffer.writeln('Email: cru.dir.lotteries@kerala.gov.in');
    buffer.writeln();
    buffer.writeln('View in App: https://lottokeralalotteries.com/app/lottery?id=${result.uniqueId}');
    return buffer.toString();
  }
}
