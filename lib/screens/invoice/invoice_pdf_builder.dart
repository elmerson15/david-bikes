// invoice_pdf_builder.dart
// ─────────────────────────────────────────────────────────────────────────────
// Everything PDF-related:
//   • Asset loading  (logo, watermark, Tamil verse image)
//   • Row model building
//   • pw.MultiPage construction  (header / footer / body)
//   • Save to temp file + share via share_plus
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show
Canvas, Color, FontStyle, Offset, TextAlign, TextDirection,
TextPainter, TextSpan, TextStyle;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

import 'invoice_pdf_helpers.dart';

class InvoicePdfBuilder {
  final QueryDocumentSnapshot invoice;
  final String customerName;
  final String phone;
  final String vehicleNumber;

  const InvoicePdfBuilder({
    required this.invoice,
    required this.customerName,
    required this.phone,
    required this.vehicleNumber,
  });

  // ── Public entry point ────────────────────────────────────────────────────

  Future<void> generateAndShare() async {
    final pdf  = pw.Document();
    final data = invoice.data() as Map<String, dynamic>;

    // ── Extract Firestore fields ────────────────────────────────────────────
    final items         = invoice['items'] as List;
    final date          = data.containsKey('date')          ? '${invoice['date']}'          : 'No Date';
    final nextOilChange = data.containsKey('nextOilChange') ? '${invoice['nextOilChange']}' : 'Not Added';
    final kmTravelled   = data.containsKey('kmTravelled')   ? '${invoice['kmTravelled']}'   : '-';

    // ── Payment fields ──────────────────────────────────────────────────────
    final int totalAmount   = (data['totalAmount']   as num?)?.toInt() ?? 0;
    final int advanceAmount = (data['advanceAmount'] as num?)?.toInt() ?? 0;
    final int balanceDue    = (data['balanceDue']    as num?)?.toInt() ?? (totalAmount - advanceAmount);

    // ── Load assets ─────────────────────────────────────────────────────────
    final logoImage      = await _loadLogo();
    final watermarkImage = await _loadWatermarkImage();
    final verseImage     = await _renderVerseAsImage(
      '"உன் வழிகளில் எல்லாம் உன்னை காப்பேன்" - இயேசு',
    );

    // ── Fonts ───────────────────────────────────────────────────────────────
    final bold    = pw.Font.helveticaBold();
    final normal  = pw.Font.helvetica();
    final oblique = pw.Font.helveticaOblique();

    // ── Build row list ──────────────────────────────────────────────────────
    final rows = _buildRows(items);
    final double computedTotal = rows.fold<double>(
        0, (sum, r) => sum + (double.tryParse(r.amount) ?? 0));

    // Use Firestore totalAmount if stored, otherwise computed
    final double pdfTotal = totalAmount > 0
        ? totalAmount.toDouble()
        : computedTotal;

    // ── Shared column widths ────────────────────────────────────────────────
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(42),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FixedColumnWidth(45),
      3: const pw.FixedColumnWidth(60),
      4: const pw.FixedColumnWidth(70),
    };

    // ── Add MultiPage ───────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,

        // ── Header ─────────────────────────────────────────────────────────
        header: (pw.Context ctx) => ctx.pageNumber == 1
            ? _buildPage1Header(
          bold:           bold,
          normal:         normal,
          logoImage:      logoImage,
          watermarkImage: watermarkImage,
          verseImage:     verseImage,
          columnWidths:   columnWidths,
          date:           date,
          nextOilChange:  nextOilChange,
          kmTravelled:    kmTravelled,
        )
            : _buildContinuationHeader(ctx, bold, normal, columnWidths),

        // ── Footer (last page only) ─────────────────────────────────────────
        footer: (pw.Context ctx) =>
        (!ctx.pagesCount.isNaN && ctx.pageNumber == ctx.pagesCount)
            ? _buildLastPageFooter(
          bold:          bold,
          oblique:       oblique,
          columnWidths:  columnWidths,
          total:         pdfTotal,
          advanceAmount: advanceAmount,
          balanceDue:    balanceDue,
        )
            : pw.SizedBox.shrink(),

        // ── Body: service rows ──────────────────────────────────────────────
        build: (pw.Context ctx) => [
          _buildItemsTable(rows, columnWidths, normal, bold),
        ],
      ),
    );

    // ── Save & share ────────────────────────────────────────────────────────
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files:   [XFile(file.path)],
        text:    "DAVID'S BIKES Service Invoice",
        subject: 'Service Bill',
      ),
    );
  }

  // ── Asset Loaders ─────────────────────────────────────────────────────────

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final ByteData d = await rootBundle.load('assets/logo.jpg');
      return pw.MemoryImage(d.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // Returns a pw.ImageProvider so it can be used directly in pw.Image
  Future<pw.ImageProvider?> _loadWatermarkImage() async {
    try {
      final ByteData d = await rootBundle.load('assets/watermark.jpg');
      return pw.MemoryImage(d.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<pw.ImageProvider> _renderVerseAsImage(String verse) async {
    const double cW = 1400, cH = 120;
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);

    final painter = TextPainter(
      text: TextSpan(
        text: verse,
        style: const TextStyle(
          fontSize: 42,
          color: Color(0xFF555555),
          fontFamily: 'NotoSansTamil',
          fontStyle: FontStyle.italic,
        ),
      ),
      textAlign:     TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: cW);
    painter.paint(canvas, Offset((cW - painter.width) / 2, 20));

    final img  = await recorder.endRecording().toImage(cW.toInt(), cH.toInt());
    final bd   = await img.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(bd!.buffer.asUint8List());
  }

  // ── Row Builder ───────────────────────────────────────────────────────────

  List<InvoiceRow> _buildRows(List items) {
    return List.generate(items.length, (i) {
      final item   = items[i];
      final qty    = item['quantity'] ?? 1;
      final rate   = item['rate']     ?? item['amount'] ?? 0;
      final amount = (qty is num && rate is num)
          ? (qty * rate).toStringAsFixed(0)
          : '${item['amount'] ?? 0}';
      return InvoiceRow(
        sno:    '${i + 1}',
        desc:   item['service'] ?? '',
        qty:    '$qty',
        rate:   '$rate',
        amount: amount,
      );
    });
  }

  // ── Page 1 Header ─────────────────────────────────────────────────────────

  pw.Widget _buildPage1Header({
    required pw.Font bold,
    required pw.Font normal,
    required pw.ImageProvider? logoImage,
    required pw.ImageProvider? watermarkImage,
    required pw.ImageProvider verseImage,
    required Map<int, pw.TableColumnWidth> columnWidths,
    required String date,
    required String nextOilChange,
    required String kmTravelled,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Top strip
        pdfCyanStrip(),

        // Verse
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 8, bottom: 6),
          child: pw.Image(verseImage, width: 320),
        ),

        // Logo + shop title + watermark top-right
        pw.Container(
          color: kPdfWhite,
          padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          height: 100,
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              // Centered title block
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "DAVID'S BIKES",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 22,
                      color: kPdfBlack,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'BIKE SERVICE & MAINTENANCE',
                    style: pw.TextStyle(
                      font: normal,
                      fontSize: 10,
                      color: kPdfCyan,
                      letterSpacing: 0.8,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Phone : 83443 41912',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 8,
                      color: kPdfBlack,
                    ),
                  ),
                ],
              ),
              // Logo pinned left
              if (logoImage != null)
                pw.Positioned(
                  left: 0,
                  child: pw.Container(
                    width: 70,
                    height: 70,
                    child: pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 6,
                      child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                ),
              // Watermark pinned top-right (faint)
              if (watermarkImage != null)
                pw.Positioned(
                  right: 0,
                  top: 0,
                  child: pw.Opacity(
                    opacity: 0.8,
                    child: pw.Image(
                      watermarkImage,
                      width: 70,
                      height: 70,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // INVOICE label
        pw.Container(
          color: kPdfWhite,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            'INVOICE',
            style: pw.TextStyle(
              font: bold,
              fontSize: 13,
              color: kPdfCyan,
              letterSpacing: 3,
            ),
          ),
        ),

        // Customer info table
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Table(
            border: pw.TableBorder.all(color: kPdfBlack, width: 0.8),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(children: [
                pdfInfoCell('NAME :  $customerName',                      bold, fontSize: 9),
                pdfInfoCell('INVOICE DATE :  ${formatInvoiceDate(date)}', bold, fontSize: 9),
              ]),
              pw.TableRow(children: [
                pdfInfoCell('PHONE NUMBER :  $phone',       bold, fontSize: 9),
                pdfInfoCell('VEHICLE NO :  $vehicleNumber', bold, fontSize: 9),
              ]),
              pw.TableRow(children: [
                pdfInfoCell('KM TRAVELLED :  $kmTravelled km',      bold, fontSize: 9),
                pdfInfoCell('NEXT OIL CHANGE :  $nextOilChange km', bold, fontSize: 9),
              ]),
            ],
          ),
        ),

        pw.SizedBox(height: 14),

        // Table header row
        pdfTableHeader(columnWidths, bold),
      ],
    );
  }

  // ── Continuation Header (page 2+) ─────────────────────────────────────────

  pw.Widget _buildContinuationHeader(
      pw.Context ctx,
      pw.Font bold,
      pw.Font normal,
      Map<int, pw.TableColumnWidth> columnWidths,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pdfCyanStrip(height: 14),
        pw.Container(
          color: kPdfWhite,
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "DAVID'S BIKES  -  INVOICE CONTINUED",
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 9,
                  color: kPdfCyan,
                  letterSpacing: 1.0,
                ),
              ),
              pw.Text(
                'Page ${ctx.pageNumber}',
                style: pw.TextStyle(
                  font: normal,
                  fontSize: 9,
                  color: const PdfColor.fromInt(0xFF888888),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pdfTableHeader(columnWidths, bold),
      ],
    );
  }

  // ── Last Page Footer ──────────────────────────────────────────────────────

  pw.Widget _buildLastPageFooter({
    required pw.Font bold,
    required pw.Font oblique,
    required Map<int, pw.TableColumnWidth> columnWidths,
    required double total,
    required int advanceAmount,
    required int balanceDue,
  }) {
    const kPdfGreen = PdfColor.fromInt(0xFF81C784);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── Total row (closes the table border) ───────────────────────────
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8),
          child: pw.Table(
            border: pw.TableBorder(
              left:             pw.BorderSide(color: kPdfBlack, width: 0.8),
              right:            pw.BorderSide(color: kPdfBlack, width: 0.8),
              bottom:           pw.BorderSide(color: kPdfBlack, width: 0.8),
              top:              pw.BorderSide.none,
              horizontalInside: pw.BorderSide.none,
              verticalInside:   pw.BorderSide.none,
            ),
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: kPdfBlack),
                children: [
                  pw.Container(height: 30),
                  pw.Container(height: 30),
                  pw.Container(height: 30),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 10),
                    child: pw.Text(
                      'TOTAL',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 10,
                        color: kPdfWhite,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 10),
                    child: pw.Text(
                      'Rs. ${total.toStringAsFixed(0)}',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 10,
                        color: kPdfWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),

        // ── Advance Paid & Balance Due (only when advance > 0) ────────────
        if (advanceAmount > 0) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: kPdfBlack, width: 0.8),
                borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                children: [
                  // Advance Paid row
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom:
                        pw.BorderSide(color: kPdfBlack, width: 0.5),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'ADVANCE PAID',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 9,
                            color: kPdfBlack,
                          ),
                        ),
                        pw.Text(
                          '- Rs. $advanceAmount',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 9,
                            color: kPdfGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Balance Due row
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: const pw.BoxDecoration(color: kPdfBlack),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'BALANCE DUE',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 11,
                            color: kPdfWhite,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.Text(
                          'Rs. $balanceDue',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 13,
                            color: balanceDue <= 0 ? kPdfGreen : kPdfAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 8),
        ],

        // ── Rupees in words ───────────────────────────────────────────────
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: kPdfBlack, width: 0.8),
            ),
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            child: pw.Text(
              advanceAmount > 0
                  ? 'BALANCE IN WORDS :  ${amountInWords(balanceDue.toDouble())}'
                  : 'RUPEES IN WORDS :  ${amountInWords(total)}',
              style: pw.TextStyle(
                font: bold,
                fontSize: 8,
                color: kPdfBlack,
              ),
            ),
          ),
        ),

        pw.SizedBox(height: 16),

        // ── Signature ─────────────────────────────────────────────────────
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 20, vertical: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Thavithu Abraham',
                    style: pw.TextStyle(
                      font: oblique,
                      fontSize: 13,
                      color: kPdfBlack,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(width: 120, height: 0.8, color: kPdfBlack),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'SIGNATURE',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 8,
                      color: kPdfBlack,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom strip
        pdfCyanStrip(),
      ],
    );
  }

  // ── Items Table Body (no watermark — moved to header) ─────────────────────

  pw.Widget _buildItemsTable(
      List<InvoiceRow> rows,
      Map<int, pw.TableColumnWidth> columnWidths,
      pw.Font normal,
      pw.Font bold,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8),
      child: pw.Table(
        border: pw.TableBorder(
          left:             pw.BorderSide(color: kPdfBlack, width: 0.8),
          right:            pw.BorderSide(color: kPdfBlack, width: 0.8),
          bottom:           pw.BorderSide.none,
          top:              pw.BorderSide.none,
          horizontalInside: pw.BorderSide.none,
          verticalInside:   pw.BorderSide.none,
        ),
        columnWidths: columnWidths,
        children: rows.asMap().entries.map((e) {
          final bg = e.key.isEven ? kPdfWhite : kPdfGrey50;
          final r  = e.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              pdfTableCell(r.sno,             normal, bg: bg, align: pw.TextAlign.center),
              pdfTableCell(r.desc,            normal, bg: bg),
              pdfTableCell(r.qty,             normal, bg: bg, align: pw.TextAlign.center),
              pdfTableCell('Rs. ${r.rate}',   normal, bg: bg, align: pw.TextAlign.center),
              pdfTableCell('Rs. ${r.amount}', bold,   bg: bg, align: pw.TextAlign.right),
            ],
          );
        }).toList(),
      ),
    );
  }
}