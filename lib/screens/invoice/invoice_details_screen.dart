import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

// ─── COLORS ──────────────────────────────────────────────────────────────────
const _kCyan    = PdfColor.fromInt(0xFF00BCD4);
const _kBlack   = PdfColors.black;
const _kWhite   = PdfColors.white;
const _kLightBg = PdfColor.fromInt(0xFFF5F5F5);
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot invoice;
  final String customerName;
  final String phone;
  final String vehicleNumber;

  const InvoiceDetailsScreen({
    super.key,
    required this.invoice,
    required this.customerName,
    required this.phone,
    required this.vehicleNumber,
  });

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _loadWatermark() async {
    try {
      final ByteData data =
      await rootBundle.load('assets/watermark.jpg');

      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
  Future<pw.ImageProvider> _renderVerseAsImage(String verse) async {

    const double canvasWidth = 1400;
    const double canvasHeight = 120;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: verse,
        style: const TextStyle(
          fontSize: 42,
          color: Color(0xFF555555),
          fontFamily: 'NotoSansTamil',
          fontStyle: FontStyle.italic,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: canvasWidth);

    final dx = (canvasWidth - textPainter.width) / 2;

    textPainter.paint(
      canvas,
      Offset(dx, 20),
    );

    final picture = recorder.endRecording();

    final image = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );

    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    return pw.MemoryImage(
      byteData!.buffer.asUint8List(),
    );
  }

  Future<void> generateAndSharePDF() async {
    final pdf   = pw.Document();
    final items = invoice['items'] as List;
    final date  = invoice.data().toString().contains('date')
        ? invoice['date']
        : 'No Date';

    final nextOilChange =
    invoice.data().toString().contains('nextOilChange')
        ? invoice['nextOilChange']
        : 'Not Added';

    final logoImage          = await _loadLogo();
    final watermarkBytes     = await _loadWatermark();

    final verseImage = await _renderVerseAsImage(
      '"உன் வழிகளில் எல்லாம் உன்னை காப்பேன்" - இயேசு',
    );

    final bold      = pw.Font.helveticaBold();
    final normal    = pw.Font.helvetica();
    final oblique   = pw.Font.helveticaOblique();

    final tamilRegular = pw.Font.ttf(
      (await rootBundle.load('assets/fonts/Latha.ttf'))
          .buffer
          .asByteData(),
    );

    // ── number of items for serial ─────────────────────────────────────────
    // Each item map is expected to have: 'service', 'quantity', 'rate'
    // 'amount' = quantity × rate  (calculated here so old docs still work)

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {

          // ── helper: thin bordered cell ─────────────────────────────────
          pw.Widget cell(
              String text, {
                pw.Font? font,
                double fontSize = 9,
                PdfColor color = _kBlack,
                pw.TextAlign align = pw.TextAlign.left,
                bool boldIt = false,
                PdfColor bg = _kWhite,
                pw.EdgeInsets padding =
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              }) {
            return pw.Container(
              color: bg,
              padding: padding,
              child: pw.Text(
                text,
                textAlign: align,
                style: pw.TextStyle(
                  font: boldIt ? bold : (font ?? normal),
                  fontSize: fontSize,
                  color: color,
                ),
              ),
            );
          }

          // ── compute rows ───────────────────────────────────────────────
          final rows = List.generate(items.length, (i) {
            final item = items[i];
            final qty    = item['quantity'] ?? 1;
            final rate   = item['rate']     ?? item['amount'] ?? 0;
            final amount = (qty is num && rate is num)
                ? (qty * rate).toStringAsFixed(0)
                : '${item['amount'] ?? 0}';
            return (
            sno: '${i + 1}',
            desc: item['service'] ?? '',
            qty: '$qty',
            rate: '$rate',
            amount: amount,
            );
          });

          // total
          final total = rows.fold<double>(
            0,
                (sum, r) => sum + (double.tryParse(r.amount) ?? 0),
          );

          // ── watermark painter ──────────────────────────────────────────
          const wmSize = 300.0;
          final pageW  = PdfPageFormat.a4.width;
          final pageH  = PdfPageFormat.a4.height;

          // Decode PNG bytes into a PdfImage the canvas can draw
          final PdfImage? wmPdfImage = watermarkBytes != null
              ? PdfImage.jpeg(
            pdf.document,
            image: watermarkBytes,
          )
              : null;

          return pw.CustomPaint(
            size: PdfPoint(pageW, pageH),
            painter: (PdfGraphics canvas, PdfPoint size) {
              if (wmPdfImage != null) {
                canvas.saveContext();
                canvas.setGraphicState(PdfGraphicState(opacity: 0.08));
                final left   = (pageW - wmSize) / 2;
                final bottom = (pageH - wmSize) / 2;
                canvas.drawImage(
                  wmPdfImage,
                  left,
                  bottom,
                  wmSize,
                  wmSize,
                );
                canvas.restoreContext();
              }
            },
            foregroundPainter: (PdfGraphics canvas, PdfPoint size) {},
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [

                // ── TOP CYAN STRIP ─────────────────────────────────────────
                _cyanStrip(height: 18),

                // ── BIBLE VERSE ────────────────────────────────────────────

                // ── BIBLE VERSE ────────────────────────────────────────────
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.only(top: 8, bottom: 6),
                  child: pw.Image(
                    verseImage,
                    width: 320,
                  ),
                ),
                // pw.Container(
                //   color: _kWhite,
                //   alignment: pw.Alignment.center,
                //   padding: const pw.EdgeInsets.only(top: 8, bottom: 2),
                //   child: pw.Text(
                //     '"உன் வழிகளில் எல்லாம் உன்னை காப்பேன்" - இயேசு',
                //     textAlign: pw.TextAlign.center,
                //     style: pw.TextStyle(
                //       font: tamilRegular,
                //       fontFallback: [oblique],
                //       fontSize: 8,
                //       color: const PdfColor.fromInt(0xFF555555),
                //     ),
                //   ),
                // ),

                // ── HEADER: logo + shop info ───────────────────────────────
                // ── HEADER: logo + shop info ───────────────────────────────
                pw.Container(
                  color: _kWhite,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 30, vertical: 16),
                  height: 102,
                  child: pw.Stack(
                    alignment: pw.Alignment.center,
                    children: [

                      // Centered title block (full width)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            "DAVID'S BIKES",
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 22,
                              color: _kBlack,
                              letterSpacing: 1.2,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'BIKE SERVICE & MAINTENANCE',
                            style: pw.TextStyle(
                              font: normal,
                              fontSize: 10,
                              color: _kCyan,
                              letterSpacing: 0.8,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Phone : 83443 41912',
                            style: pw.TextStyle(
                                font: bold, fontSize: 8, color: _kBlack),
                          ),
                        ],
                      ),

                      // Logo pinned to the left
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
                    ],
                  ),
                ),

                // ── "INVOICE" centred label ────────────────────────────────
                pw.Container(
                  color: _kWhite,
                  alignment: pw.Alignment.center,
                  padding:
                  const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 13,
                      color: _kCyan,
                      letterSpacing: 3,
                    ),
                  ),
                ),

                // ── CUSTOMER INFO TABLE ────────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Table(
                    border: pw.TableBorder.all(color: _kBlack, width: 0.8),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(children: [
                        cell('NAME :  $customerName', boldIt: true, fontSize: 9),
                        cell(
                          'INVOICE DATE :  ${date.split('-').reversed.join('-')}',
                          boldIt: true,
                          fontSize: 9,
                        ),
                      ]),
                      pw.TableRow(children: [
                        cell('PHONE NUMBER :  $phone',
                            boldIt: true, fontSize: 9),
                        cell('VEHICLE NO :  $vehicleNumber',
                            boldIt: true, fontSize: 9),
                      ]),
                      pw.TableRow(children: [
                        cell(
                          'KM TRAVELLED :  ${invoice['kmTravelled']} km',
                          boldIt: true,
                          fontSize: 9,
                        ),
                        cell(
                          'NEXT OIL CHANGE :  $nextOilChange km',
                          boldIt: true,
                          fontSize: 9,
                        ),
                      ]),
                    ],
                  ),
                ),

                pw.SizedBox(height: 14),

                // ── SERVICES TABLE ─────────────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Table(
                    border: pw.TableBorder(
                      top: pw.BorderSide(color: _kBlack, width: 0.8),
                      left: pw.BorderSide(color: _kBlack, width: 0.8),
                      right: pw.BorderSide(color: _kBlack, width: 0.8),
                      bottom: pw.BorderSide(color: _kBlack, width: 0.8),
                      horizontalInside: pw.BorderSide.none,
                      verticalInside: pw.BorderSide.none,
                    ),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(42),
                      1: const pw.FlexColumnWidth(4),
                      2: const pw.FixedColumnWidth(45),
                      3: const pw.FixedColumnWidth(60),
                      4: const pw.FixedColumnWidth(70),
                    },
                    children: [

                      // HEADER
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: _kBlack,
                        ),
                        children: [

                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: pw.Text(
                              'S.NO',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                color: _kWhite,
                              ),
                            ),
                          ),

                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: pw.Text(
                              'DESCRIPTION',
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                color: _kWhite,
                              ),
                            ),
                          ),

                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: pw.Text(
                              'QTY',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                color: _kWhite,
                              ),
                            ),
                          ),

                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: pw.Text(
                              'RATE',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                color: _kWhite,
                              ),
                            ),
                          ),

                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: pw.Text(
                              'AMOUNT',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                color: _kWhite,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ITEMS
                      ...rows.map((r) {

                        final isEven = rows.indexOf(r).isEven;

                        final bg = isEven
                            ? _kWhite
                            : const PdfColor.fromInt(0xFFF7F7F7);

                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: bg,
                          ),
                          children: [

                            pw.Container(
                              color: bg,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: pw.Text(
                                r.sno,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  font: normal,
                                  fontSize: 10,
                                  color: _kBlack,
                                ),
                              ),
                            ),

                            pw.Container(
                              color: bg,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: pw.Text(
                                r.desc,
                                style: pw.TextStyle(
                                  font: normal,
                                  fontSize: 10,
                                  color: _kBlack,
                                ),
                              ),
                            ),

                            pw.Container(
                              color: bg,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: pw.Text(
                                r.qty,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  font: normal,
                                  fontSize: 10,
                                  color: _kBlack,
                                ),
                              ),
                            ),

                            pw.Container(
                              color: bg,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: pw.Text(
                                'Rs. ${r.rate}',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  font: normal,
                                  fontSize: 10,
                                  color: _kBlack,
                                ),
                              ),
                            ),

                            pw.Container(
                              color: bg,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: pw.Text(
                                'Rs. ${r.amount}',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 10,
                                  color: _kBlack,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      // EMPTY ROWS FOR FULL PAGE HEIGHT
                      ...List.generate(
                        (14 - rows.length).clamp(0, 14),
                            (_) => pw.TableRow(
                          children: [

                            pw.Container(
                              height: 28,
                              color: _kWhite,
                            ),

                            pw.Container(
                              height: 28,
                              color: _kWhite,
                            ),

                            pw.Container(
                              height: 28,
                              color: _kWhite,
                            ),

                            pw.Container(
                              height: 28,
                              color: _kWhite,
                            ),

                            pw.Container(
                              height: 28,
                              color: _kWhite,
                            ),
                          ],
                        ),
                      ),

                      // TOTAL ROW
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: _kBlack,
                        ),
                        children: [

                          pw.Container(),

                          pw.Container(),

                          pw.Container(),

                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            child: pw.Text(
                              'TOTAL',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                color: _kWhite,
                              ),
                            ),
                          ),

                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            child: pw.Text(
                              'Rs. ${total.toStringAsFixed(0)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                color: _kWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // ── RUPEES IN WORDS ────────────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _kBlack, width: 0.8),
                    ),
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: pw.Text(
                      'RUPEES IN WORDS :  ${_amountInWords(total)}',
                      style: pw.TextStyle(
                          font: bold, fontSize: 8, color: _kBlack),
                    ),
                  ),
                ),

                pw.Spacer(),

                // ── SIGNATURE ROW ──────────────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  child: pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment:
                        pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Thavithu Abraham',
                            style: pw.TextStyle(
                              font: oblique,
                              fontSize: 13,
                              color: _kBlack,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Container(
                              width: 120, height: 0.8, color: _kBlack),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'SIGNATURE',
                            style: pw.TextStyle(
                                font: bold, fontSize: 8, color: _kBlack),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── BOTTOM CYAN STRIP ──────────────────────────────────────
                _cyanStrip(height: 18),
              ],
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file   = File('${output.path}/invoice.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "DAVID'S BIKES Service Invoice",
      subject: 'Service Bill',
    );
  }

  // ── cyan decorative strip ──────────────────────────────────────────────────
  static pw.Widget _cyanStrip({double height = 16}) {
    return pw.Row(
      children: [
        pw.Container(
            width: 30, height: height,
            color: const PdfColor.fromInt(0xFF000000)),
        pw.Expanded(
            child: pw.Container(height: height, color: _kCyan)),
        pw.Container(
            width: 30, height: height,
            color: const PdfColor.fromInt(0xFF000000)),
      ],
    );
  }

  // ── table header cell ──────────────────────────────────────────────────────
  static pw.Widget _thCell(
      String text,
      pw.Font bold, {
        pw.TextAlign align = pw.TextAlign.left,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
            font: bold, fontSize: 9, color: _kWhite, letterSpacing: 0.5),
      ),
    );
  }

  // ── very simple rupees-in-words (covers up to 99,999) ─────────────────────
  static String _amountInWords(double amount) {
    final ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
      'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    int n = amount.round();
    if (n == 0) return 'Zero Rupees Only';

    String words = '';
    if (n >= 1000) {
      words += '${ones[n ~/ 1000]} Thousand ';
      n %= 1000;
    }
    if (n >= 100) {
      words += '${ones[n ~/ 100]} Hundred ';
      n %= 100;
    }
    if (n >= 20) {
      words += '${tens[n ~/ 10]} ';
      n %= 10;
    }
    if (n > 0) words += '${ones[n]} ';

    return '${words.trim()} Rupees Only';
  }

  // ── UI Screen ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final items = invoice['items'] as List;
    final date  = invoice.data().toString().contains('date')
        ? invoice['date']
        : 'No Date';

    final nextOilChange =
    invoice.data().toString().contains('nextOilChange')
        ? invoice['nextOilChange']
        : 'Not Added';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'INVOICE DETAILS',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: generateAndSharePDF,
                icon: const Icon(Icons.share),
                label: const Text('SHARE BILL'),
              ),
            ),
            const SizedBox(height: 25),
            Text(customerName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(phone,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(vehicleNumber,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Date : ${date.split('-').reversed.join('-')}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("KM : ${invoice['kmTravelled']}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            Text(
              "Next Oil Change : $nextOilChange KM",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),
            const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Service',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))),
                Expanded(
                    child: Text('Qty',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))),
                Expanded(
                    child: Text('Rate',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))),
                Expanded(
                    child: Text('Amount',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final qty    = item['quantity'] ?? 1;
                  final rate   = item['rate']     ?? item['amount'] ?? 0;
                  final amount = (qty is num && rate is num)
                      ? (qty * rate).toStringAsFixed(0)
                      : '${item['amount'] ?? 0}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text(item['service'] ?? '',
                                style:
                                const TextStyle(color: Colors.white))),
                        Expanded(
                            child: Text('$qty',
                                style:
                                const TextStyle(color: Colors.white))),
                        Expanded(
                            child: Text('Rs.$rate',
                                style:
                                const TextStyle(color: Colors.white))),
                        Expanded(
                            child: Text('Rs.$amount',
                                style:
                                const TextStyle(color: Colors.white))),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total : Rs.${invoice['totalAmount']}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}