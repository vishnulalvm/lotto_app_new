// File: lib/services/pdf_service.dart
import 'dart:io';
import 'dart:math';
// Required for Uint8List
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// Make sure to import your data model.
// This is a placeholder, update with your actual path.
import 'package:lotto_app/data/models/results_screen/results_screen.dart';

class PdfService {
  // Cache fonts to avoid reloading
  static pw.Font? _notoSansRegular;
  static pw.Font? _notoSansBold;

  static Future<void> generateAndShareLotteryResult(
    LotteryResultModel result,
  ) async {
    try {
      await _loadFonts();
      final pdf = await _generateLotteryResultPdf(result);
      final file = await _savePdfToFile(pdf, result);
      await _sharePdf(file, result);
    } catch (e) {
      print('Exception in generateAndShareLotteryResult: $e');
      throw Exception('Failed to generate and share the PDF result: $e');
    }
  }

  static Future<void> _loadFonts() async {
    if (_notoSansRegular == null || _notoSansBold == null) {
      try {
        final regularFontData =
            await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
        final boldFontData =
            await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
        _notoSansRegular = pw.Font.ttf(regularFontData);
        _notoSansBold = pw.Font.ttf(boldFontData);
        print('Custom fonts loaded successfully.');
      } catch (e) {
        print('Failed to load custom fonts, using library default: $e');
        _notoSansRegular = null;
        _notoSansBold = null;
      }
    }
  }

  static String _sanitizeText(String text) {
    if (text.isEmpty) return '';
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static pw.TextStyle _safeTextStyle({
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) {
    final isBold = fontWeight == pw.FontWeight.bold;
    pw.Font? selectedFont = isBold ? _notoSansBold : _notoSansRegular;
    selectedFont ??= _notoSansRegular; // Fallback if bold isn't loaded

    return pw.TextStyle(
      font: selectedFont,
      fontSize:
          fontSize ?? 10, // Default to a smaller font size for minimalist look
      fontWeight: fontWeight ?? pw.FontWeight.normal,
      color: color ?? PdfColors.black,
    );
  }

  /// **RE-ARCHITECTED PDF GENERATION LOGIC**
  static Future<pw.Document> _generateLotteryResultPdf(
    LotteryResultModel result,
  ) async {
    final pdf = pw.Document();

    final highTierPrizes = result.prizes
        .where((p) => ['1st', '2nd', '3rd'].contains(p.prizeType.toLowerCase()))
        .toList();
    final consolationPrize = result.getConsolationPrize();
    final lowerTierPrizes = result.prizes
        .where((p) => !['1st', '2nd', '3rd', 'consolation']
            .contains(p.prizeType.toLowerCase()))
        .toList();

    // Sort all prizes to maintain a consistent order
    final prizeOrder = [
      '1st',
      'consolation',
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
    highTierPrizes.sort((a, b) => prizeOrder
        .indexOf(a.prizeType.toLowerCase())
        .compareTo(prizeOrder.indexOf(b.prizeType.toLowerCase())));
    lowerTierPrizes.sort((a, b) => prizeOrder
        .indexOf(a.prizeType.toLowerCase())
        .compareTo(prizeOrder.indexOf(b.prizeType.toLowerCase())));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 30, horizontal: 25),
        header: (pw.Context context) => _buildMinimalHeader(result),
        footer: (pw.Context context) =>
            _buildMinimalFooter(context.pageNumber, context.pagesCount),
        build: (pw.Context context) {
          // **FIX:** Build a single flat list of widgets to allow page breaks anywhere.
          final List<pw.Widget> widgets = [];

          // --- High Tier Prizes ---
          widgets.addAll(
              highTierPrizes.map((prize) => _buildHighTierPrize(prize)));

          // --- Consolation Prize ---
          if (consolationPrize != null) {
            widgets.add(_buildConsolationPrize(consolationPrize));
          }

          widgets.add(pw.SizedBox(height: 15));
          widgets.add(pw.Text(
            'FOR THE TICKETS ENDING WITH THE FOLLOWING NUMBERS',
            style: _safeTextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            textAlign: pw.TextAlign.center,
          ));
          widgets.add(pw.SizedBox(height: 10));

          // --- Lower Tier Prizes ---
          // Use `expand` to flatten the list of lists into a single list
          widgets.addAll(lowerTierPrizes
              .expand((prize) => _buildLowerTierPrizeWidgets(prize)));

          return widgets;
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildMinimalHeader(LotteryResultModel result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'KERALA STATE LOTTERIES - RESULT',
          style: _safeTextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${_sanitizeText(result.lotteryName.toUpperCase())} LOTTERY NO: ${_sanitizeText(result.drawNumber)} DRAW held on: ${_sanitizeText(result.formattedDate)}',
          style: _safeTextStyle(fontSize: 11),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Divider(thickness: 1, color: PdfColors.grey700),
        pw.SizedBox(height: 15),
      ],
    );
  }

  static pw.Widget _buildHighTierPrize(PrizeModel prize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(
          '${_sanitizeText(prize.prizeTypeFormatted)} Rs : ${_sanitizeText(prize.formattedPrizeAmount)}/-',
          style: _safeTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        ...prize.ticketsWithLocation.map(
          (ticket) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20.0),
            child: pw.Text(
              '${_sanitizeText(ticket.ticketNumber)} (${_sanitizeText(ticket.location ?? 'N/A')})',
              style:
                  _safeTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      ]),
    );
  }

  static pw.Widget _buildConsolationPrize(PrizeModel prize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${_sanitizeText(prize.prizeTypeFormatted)} Rs : ${_sanitizeText(prize.formattedPrizeAmount)}/-',
            style: _safeTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20.0),
            child: pw.Wrap(
              spacing: 12,
              runSpacing: 4,
              children: prize.allTicketNumbers
                  .map((number) => pw.Text(_sanitizeText(number),
                      style: _safeTextStyle(fontSize: 11)))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  /// **NEW:** Returns a flat list of widgets for a single prize category.

  /// Replace your lower-tier builder with this, choosing `columns = 8` (or any count).
  static List<pw.Widget> _buildLowerTierPrizeWidgets(PrizeModel prize) {
    const int columns = 8; // ← increase this to fit more per row
    final widgets = <pw.Widget>[];

    // Prize header
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8.0, bottom: 5.0),
        child: pw.Text(
          '${_sanitizeText(prize.prizeTypeFormatted)} – Rs: ${_sanitizeText(prize.formattedPrizeAmount)}/-',
          style: _safeTextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    // Break numbers into rows of `columns` count
    final rows = <List<String>>[];
    for (var i = 0; i < prize.allTicketNumbers.length; i += columns) {
      rows.add(
        prize.allTicketNumbers.sublist(
          i,
          min(i + columns, prize.allTicketNumbers.length),
        ),
      );
    }

    // Render as a flowing table
    widgets.add(
      pw.Table.fromTextArray(
        data: rows,
        cellStyle: _safeTextStyle(fontSize: 10),
        cellAlignment: pw.Alignment.center,
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(width: 0.2, color: PdfColors.grey400),
        ),
        columnWidths: {
          for (var c = 0; c < columns; c++)
            c: pw.FractionColumnWidth(1 / columns),
        },
      ),
    );

    return widgets;
  }

  static pw.Widget _buildMinimalFooter(int pageNumber, int pageCount) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey500),
        pw.SizedBox(height: 5),
        pw.Text(
          'The prize winners are advised to verify the winning numbers with the results published in the Kerala Government Gazette and surrender the winning tickets within 90 days.',
          style: _safeTextStyle(fontSize: 9, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page $pageNumber of $pageCount',
            style: _safeTextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  // --- FILE SAVING AND SHARING (Unchanged) ---
  static Future<File> _savePdfToFile(
    pw.Document pdf,
    LotteryResultModel result,
  ) async {
    final output = await getTemporaryDirectory();
    final fileName =
        'lottery_result_${_sanitizeText(result.lotteryCode)}_${result.drawNumber}.pdf';
    final file = File('${output.path}/$fileName');
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  static Future<void> _sharePdf(File file, LotteryResultModel result) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: _sanitizeText(
          'Kerala Lottery Result: ${result.lotteryName} - Draw ${result.drawNumber}'),
      subject: _sanitizeText('Lottery Result - ${result.drawNumber}'),
    );
  }

  static Future<Uint8List> generateLotteryResultPdfBytes(
    LotteryResultModel result,
  ) async {
    await _loadFonts();
    final pdf = await _generateLotteryResultPdf(result);
    return await pdf.save();
  }
}
