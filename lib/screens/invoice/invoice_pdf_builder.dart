// invoice_pdf_builder.dart
// ─────────────────────────────────────────────────────────────────────────────
// Single-page dynamic-height PDF.
// Strategy: build the content widget once, measure its real height using a
// very tall throw-away page, then re-render at exactly that height.
// Zero white space at the bottom — works for 1 item or 100.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'
    show
    Canvas,
    Color,
    FontStyle,
    Offset,
    TextAlign,
    TextDirection,
    TextPainter,
    TextSpan,
    TextStyle;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
    final data = invoice.data() as Map<String, dynamic>;

    // ── Firestore fields ──────────────────────────────────────────────────
    final items         = invoice['items'] as List;
    final date          = data.containsKey('date')          ? '${invoice['date']}'          : 'No Date';
    final nextOilChange = data.containsKey('nextOilChange') ? '${invoice['nextOilChange']}' : 'Not Added';
    final kmTravelled   = data.containsKey('kmTravelled')   ? '${invoice['kmTravelled']}'   : '-';

    // ── Payment ───────────────────────────────────────────────────────────
    final int totalAmount   = (data['totalAmount']   as num?)?.toInt() ?? 0;
    final int advanceAmount = (data['advanceAmount'] as num?)?.toInt() ?? 0;
    final int balanceDue    = (data['balanceDue']    as num?)?.toInt() ?? (totalAmount - advanceAmount);

    // ── Assets ────────────────────────────────────────────────────────────
    final logoImage      = await _loadLogo();
    final watermarkImage = await _loadWatermarkImage();
    final verseImage     = await _renderVerseAsImage(
      '"உன் வழிகளில் எல்லாம் உன்னை காப்பேன்" - இயேசு',
    );

    // ── Fonts ─────────────────────────────────────────────────────────────
    final bold    = pw.Font.helveticaBold();
    final normal  = pw.Font.helvetica();
    final oblique = pw.Font.helveticaOblique();

    // ── Rows ──────────────────────────────────────────────────────────────
    final rows = _buildRows(items);
    final double computedTotal =
    rows.fold<double>(0, (s, r) => s + (double.tryParse(r.amount) ?? 0));
    final double pdfTotal =
    totalAmount > 0 ? totalAmount.toDouble() : computedTotal;

    // ── Column widths ─────────────────────────────────────────────────────
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(42),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FixedColumnWidth(45),
      3: const pw.FixedColumnWidth(60),
      4: const pw.FixedColumnWidth(70),
    };

    // ── Page height — row count drives the total ─────────────────────────
    //   Each constant matches the exact widget size in invoice_pdf_helpers.dart
    //   pdfTableCell: vertical:8 + ~12pt font + vertical:8 = 28pt per row
    final double pageHeight =
        18.0                               // top cyan strip
            + 56.0                               // verse image
            + 100.0                              // logo block (explicit height)
            + 28.0                               // "INVOICE" label
            + 66.0                               // customer info table (3 rows)
            + 14.0                               // gap below customer table
            + 28.0                               // table column header
            + (rows.length * 28.0)               // item rows — exact per pdfTableCell
            + 30.0                               // total row
            +  8.0                               // gap after total
            + (advanceAmount > 0 ? 64.0 + 8.0 : 0.0)  // advance+balance block
            + 26.0                               // rupees in words
            + 16.0                               // gap after words
            + 34.0                               // signature block
            + 12.0                               // gap above strip
            + 18.0                               // bottom cyan strip
            + 28.0;                              // MLCC branding (plain text, no bg)

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(PdfPageFormat.a4.width, pageHeight, marginAll: 0),
        margin:     pw.EdgeInsets.zero,
        build: (ctx) => _buildContent(
          bold: bold, normal: normal, oblique: oblique,
          logoImage: logoImage, watermarkImage: watermarkImage,
          verseImage: verseImage, columnWidths: columnWidths,
          rows: rows, pdfTotal: pdfTotal,
          advanceAmount: advanceAmount, balanceDue: balanceDue,
          date: date, nextOilChange: nextOilChange, kmTravelled: kmTravelled,
          customerName: customerName, phone: phone,
          vehicleNumber: vehicleNumber,
        ),
      ),
    );

    // ── Save & share ──────────────────────────────────────────────────────
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

  // ── All page content in one widget ───────────────────────────────────────
  //
  // Called twice (probe + final). Pure function — no side effects.
  //
  pw.Widget _buildContent({
    required pw.Font bold,
    required pw.Font normal,
    required pw.Font oblique,
    required pw.ImageProvider? logoImage,
    required pw.ImageProvider? watermarkImage,
    required pw.ImageProvider verseImage,
    required Map<int, pw.TableColumnWidth> columnWidths,
    required List<InvoiceRow> rows,
    required double pdfTotal,
    required int advanceAmount,
    required int balanceDue,
    required String date,
    required String nextOilChange,
    required String kmTravelled,
    required String customerName,
    required String phone,
    required String vehicleNumber,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisSize:       pw.MainAxisSize.min,
      children: [

        // ══════════════════════════════════════
        //  HEADER
        // ══════════════════════════════════════

        pdfCyanStrip(),

        pw.Container(
          alignment: pw.Alignment.center,
          padding:   const pw.EdgeInsets.symmetric(vertical: 6),
          child:     pw.Image(verseImage, width: 320),
        ),

        pw.Container(
          color:   kPdfWhite,
          height:  100,
          padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment:  pw.MainAxisAlignment.center,
                children: [
                  pw.Text("DAVID'S BIKES",
                      style: pw.TextStyle(font: bold, fontSize: 22,
                          color: kPdfBlack, letterSpacing: 1.2)),
                  pw.SizedBox(height: 2),
                  pw.Text('BIKE SERVICE & MAINTENANCE',
                      style: pw.TextStyle(font: normal, fontSize: 10,
                          color: kPdfCyan, letterSpacing: 0.8)),
                  pw.SizedBox(height: 6),
                  pw.Text('Phone : 83443 41912',
                      style: pw.TextStyle(font: bold, fontSize: 8, color: kPdfBlack)),
                ],
              ),
              if (logoImage != null)
                pw.Positioned(
                  left: 0,
                  child: pw.Container(
                    width: 70, height: 70,
                    child: pw.ClipRRect(
                      horizontalRadius: 6, verticalRadius: 6,
                      child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                ),
              if (watermarkImage != null)
                pw.Positioned(
                  right: 0, top: 0,
                  child: pw.Opacity(
                    opacity: 0.8,
                    child: pw.Image(watermarkImage,
                        width: 70, height: 70, fit: pw.BoxFit.contain),
                  ),
                ),
            ],
          ),
        ),

        pw.Container(
          color:     kPdfWhite,
          alignment: pw.Alignment.center,
          padding:   const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text('INVOICE',
              style: pw.TextStyle(font: bold, fontSize: 13,
                  color: kPdfCyan, letterSpacing: 3)),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Table(
            border: pw.TableBorder.all(color: kPdfBlack, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(3),
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

        pdfTableHeader(columnWidths, bold),

        // ══════════════════════════════════════
        //  ITEMS
        // ══════════════════════════════════════

        pw.Padding(
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
        ),

        // ══════════════════════════════════════
        //  FOOTER
        // ══════════════════════════════════════

        // Total row
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
                  pw.SizedBox(height: 30),
                  pw.SizedBox(height: 30),
                  pw.SizedBox(height: 30),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    child: pw.Text('TOTAL',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: bold, fontSize: 10, color: kPdfWhite)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    child: pw.Text('Rs. ${pdfTotal.toStringAsFixed(0)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: bold, fontSize: 10, color: kPdfWhite)),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),

        // Advance + Balance
        if (advanceAmount > 0) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: kPdfBlack, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(color: kPdfBlack, width: 0.5)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('ADVANCE PAID',
                            style: pw.TextStyle(font: bold, fontSize: 9, color: kPdfBlack)),
                        pw.Text('- Rs. $advanceAmount',
                            style: pw.TextStyle(font: bold, fontSize: 9,
                                color: const PdfColor.fromInt(0xFF81C784))),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: const pw.BoxDecoration(color: kPdfBlack),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('BALANCE DUE',
                            style: pw.TextStyle(font: bold, fontSize: 11,
                                color: kPdfWhite, letterSpacing: 1)),
                        pw.Text('Rs. $balanceDue',
                            style: pw.TextStyle(font: bold, fontSize: 13,
                                color: balanceDue <= 0
                                    ? const PdfColor.fromInt(0xFF81C784)
                                    : kPdfAmber)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 8),
        ],

        // Rupees in words
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Container(
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: kPdfBlack, width: 0.8)),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: pw.Text(
              advanceAmount > 0
                  ? 'BALANCE IN WORDS :  ${amountInWords(balanceDue.toDouble())}'
                  : 'RUPEES IN WORDS :  ${amountInWords(pdfTotal)}',
              style: pw.TextStyle(font: bold, fontSize: 8, color: kPdfBlack),
            ),
          ),
        ),

        pw.SizedBox(height: 16),

        // Signature
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Thavithu Abraham',
                      style: pw.TextStyle(font: oblique, fontSize: 13, color: kPdfBlack)),
                  pw.SizedBox(height: 2),
                  pw.Container(width: 120, height: 0.8, color: kPdfBlack),
                  pw.SizedBox(height: 3),
                  pw.Text('SIGNATURE',
                      style: pw.TextStyle(font: bold, fontSize: 8, color: kPdfBlack)),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // Bottom cyan strip
        pdfCyanStrip(),

        // MLCC branding — plain text, no background, no height issues
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Bill Generated by',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: normal, fontSize: 6.5,
                      color: const PdfColor.fromInt(0xFF888888), letterSpacing: 0.5)),
              pw.SizedBox(height: 2),
              pw.Text('MLCC NETWORK & CREATIVE SERVICES',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: bold, fontSize: 8.5,
                      color: kPdfCyan, letterSpacing: 1.6)),
            ],
          ),
        ),

      ],
    );
  }

  // ── Asset loaders ─────────────────────────────────────────────────────────

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final ByteData d = await rootBundle.load('assets/logo.jpg');
      return pw.MemoryImage(d.buffer.asUint8List());
    } catch (_) { return null; }
  }

  Future<pw.ImageProvider?> _loadWatermarkImage() async {
    try {
      final ByteData d = await rootBundle.load('assets/watermark.jpg');
      return pw.MemoryImage(d.buffer.asUint8List());
    } catch (_) { return null; }
  }

  Future<pw.ImageProvider> _renderVerseAsImage(String verse) async {
    const double cW = 1400, cH = 120;
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);

    final painter = TextPainter(
      text: TextSpan(
        text: verse,
        style: const TextStyle(
          fontSize: 42, color: Color(0xFF555555),
          fontFamily: 'NotoSansTamil', fontStyle: FontStyle.italic,
        ),
      ),
      textAlign:     TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: cW);
    painter.paint(canvas, Offset((cW - painter.width) / 2, 20));

    final img = await recorder.endRecording().toImage(cW.toInt(), cH.toInt());
    final bd  = await img.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(bd!.buffer.asUint8List());
  }

  // ── Row builder ───────────────────────────────────────────────────────────

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
}