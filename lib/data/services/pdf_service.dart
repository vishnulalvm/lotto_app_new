import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
      throw Exception('Failed to generate and share the PDF result: $e');
    }
  }

  static Future<void> _loadFonts() async {
    if (_notoSansRegular == null || _notoSansBold == null) {
      try {
        final regularFontData =
            await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
        final boldFontData =
            await rootBundle.load('assets/fonts/NotoSans_Condensed-Bold.ttf');

        _notoSansRegular = pw.Font.ttf(regularFontData);
        _notoSansBold = pw.Font.ttf(boldFontData);
      } catch (e) {
        // Use default fonts if custom fonts fail to load
        _notoSansRegular = pw.Font.helvetica();
        _notoSansBold = pw.Font.helveticaBold();
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
    pw.Font baseFont = isBold
        ? (_notoSansBold ?? pw.Font.helveticaBold())
        : (_notoSansRegular ?? pw.Font.helvetica());

    return pw.TextStyle(
      font: baseFont,
      fontFallback: [_notoSansRegular ?? pw.Font.helvetica()],
      fontSize: fontSize ?? 10,
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
        // 1️⃣ Move margin & format into PageTheme
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 25), // Reduced vertical margin

          // 2️⃣ Draw the watermark on every page
          buildBackground: (pw.Context context) {
            return pw.Center(
              child: pw.Opacity(
                opacity: 0.08,
                child: pw.Text(
                  'LOTTO',
                  style: pw.TextStyle(
                    font: _notoSansBold, // your loaded bold font
                    fontFallback: [_notoSansRegular!], // ensures ₹ renders
                    fontSize: 100,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey400,
                  ),
                ),
              ),
            );
          },
        ),

        header: (pw.Context context) => _buildMinimalHeader(result),
        footer: (pw.Context context) =>
            _buildMinimalFooter(context.pageNumber, context.pagesCount),

        build: (pw.Context context) {
          final List<pw.Widget> contentWidgets = [];

          // 🔷 1️⃣ FIRST PRIZE (Top)
          final firstPrize = highTierPrizes.where(
            (p) => p.prizeType.toLowerCase() == '1st',
          ).firstOrNull;
          if (firstPrize != null) {
            contentWidgets.add(_buildClickableHorizontalHighTierPrize(firstPrize));
          }

          // 🔷 2️⃣ CONSOLATION PRIZE (only series shown)
          if (consolationPrize != null) {
            contentWidgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Consolation Prize Rs: ${_sanitizeText(consolationPrize.formattedPrizeAmount)}/- : ',
                      style: _safeTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Expanded(
                      child: pw.Wrap(
                        spacing: 10,
                        children: consolationPrize.seriesOnly
                            .map((series) => pw.Text(series,
                                style: _safeTextStyle(fontSize: 11)))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 🔷 3️⃣ SECOND & THIRD PRIZES (in a single row)
          final secondPrize = highTierPrizes.where(
            (p) => p.prizeType.toLowerCase() == '2nd',
          ).firstOrNull;
          final thirdPrize = highTierPrizes.where(
            (p) => p.prizeType.toLowerCase() == '3rd',
          ).firstOrNull;
          
          if (secondPrize != null || thirdPrize != null) {
            contentWidgets.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (secondPrize != null)
                    pw.Expanded(
                      flex: 1,
                      child: _buildClickableHorizontalHighTierPrize(secondPrize),
                    ),
                  if (secondPrize != null && thirdPrize != null)
                    pw.SizedBox(width: 20), // Space between prizes
                  if (thirdPrize != null)
                    pw.Expanded(
                      flex: 1,
                      child: _buildClickableHorizontalHighTierPrize(thirdPrize),
                    ),
                ],
              ),
            );
          }

          // 🔷 4️⃣ LOWER TIER PRIZES
          contentWidgets.addAll(
            lowerTierPrizes
                .expand((prize) => _buildClickableLowerTierPrizeWidgets(prize)),
          );

          // 🔷 5️⃣ URL LINK
          contentWidgets.add(pw.SizedBox(height: 20));
          contentWidgets.add(
            pw.Center(
              child: pw.UrlLink(
                destination: 'https://lottokeralalotteries.com/',
                child: pw.Text(
                  'Visit www.lottokeralalotteries.com',
                  style: pw.TextStyle(
                    font: _notoSansRegular,
                    fontSize: 12,
                    decoration: pw.TextDecoration.underline,
                    color: PdfColors.blue,
                  ),
                ),
              ),
            ),
          );

          return contentWidgets;
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
        pw.SizedBox(height: 3), // Reduced spacing
        pw.Text(
          '${_sanitizeText(result.lotteryName.toUpperCase())} LOTTERY NO: ${_sanitizeText(result.drawNumber)} DRAW held on: ${_sanitizeText(result.formattedDate)}',
          style: _safeTextStyle(fontSize: 11),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 3), // Reduced spacing
        pw.Divider(thickness: 1, color: PdfColors.grey700),
        pw.SizedBox(height: 10), // Reduced spacing
      ],
    );
  }


  // NEW: Horizontal layout for 1st and 2nd prizes
  static pw.Widget _buildHorizontalHighTierPrize(PrizeModel prize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Prize title and winning numbers on same line
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${_sanitizeText(prize.prizeTypeFormatted)} Rs: ${_sanitizeText(prize.formattedPrizeAmount)}/-: ', // Added colon at the end
                style: _safeTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: prize.ticketsWithLocation.map(
                    (ticket) => pw.Text(
                      '${_sanitizeText(ticket.ticketNumber)} (${_sanitizeText(ticket.location ?? 'N/A')})',
                      style: _safeTextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // Clickable version of horizontal high tier prize
  static pw.Widget _buildClickableHorizontalHighTierPrize(PrizeModel prize) {
    return pw.UrlLink(
      destination: 'https://www.lottokeralalotteries.com',
      child: _buildHorizontalHighTierPrize(prize),
    );
  }



  /// **NEW:** Returns a flat list of widgets for a single prize category.

  static List<pw.Widget> _buildLowerTierPrizeWidgets(PrizeModel prize) {
    final widgets = <pw.Widget>[];

    // Prize header
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8.0, bottom: 5.0),
        child: pw.Text(
          '${_sanitizeText(prize.prizeTypeFormatted)} – Rs: ${_sanitizeText(prize.formattedPrizeAmount)}/-',
          style: _safeTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    // Grid layout for all numbers
    const int columns = 15;
    final allNumbers = prize.allTicketNumbers;
    
    // Break numbers into rows of `columns` count
    final rows = <List<String>>[];
    for (var i = 0; i < allNumbers.length; i += columns) {
      final row = allNumbers.sublist(
        i,
        min(i + columns, allNumbers.length),
      );
      // Pad incomplete rows with empty strings for alignment
      while (row.length < columns) {
        row.add('');
      }
      rows.add(row);
    }

    // Create grid with clean alignment
    widgets.add(
      pw.Table(
        columnWidths: {
          for (var c = 0; c < columns; c++)
            c: const pw.FractionColumnWidth(1 / 15),
        },
        border: pw.TableBorder.all(
          width: 0.5,
          color: PdfColors.grey300,
        ),
        children: rows.map((row) {
          return pw.TableRow(
            children: row.map((number) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(2.0),
                child: pw.Center(
                  child: pw.Text(
                    _sanitizeText(number),
                    style: _safeTextStyle(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );

    return widgets;
  }

  // Clickable version of lower tier prize widgets
  static List<pw.Widget> _buildClickableLowerTierPrizeWidgets(
      PrizeModel prize) {
    return _buildLowerTierPrizeWidgets(prize)
        .map((widget) => pw.UrlLink(
              destination: 'https://www.lottokeralalotteries.com',
              child: widget,
            ))
        .toList();
  }

  // Helper method to create clickable text

  static pw.Widget _buildMinimalFooter(int pageNumber, int pageCount) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey500),
        pw.SizedBox(height: 2), // Further reduced spacing
        pw.Text(
          'The prize winners are advised to verify the winning numbers with the results published in the Kerala Government Gazette and surrender the winning tickets within 90 days.',
          style: _safeTextStyle(fontSize: 9, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2), // Further reduced spacing
        // Removed page number display
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
    final params = ShareParams(
      files: [XFile(file.path)],
      text: _sanitizeText(
          'Kerala Lottery Result: ${result.lotteryName} - Draw ${result.drawNumber}'),
      subject: _sanitizeText('Lottery Result - ${result.drawNumber}'),
    );
    await SharePlus.instance.share(params);
  }

  static Future<Uint8List> generateLotteryResultPdfBytes(
    LotteryResultModel result,
  ) async {
    await _loadFonts();
    final pdf = await _generateLotteryResultPdf(result);
    return await pdf.save();
  }
}