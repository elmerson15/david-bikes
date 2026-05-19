// invoice_details_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// UI only: shows invoice info and a "Share Bill" button.
// All PDF generation is delegated to InvoicePdfBuilder.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'invoice_pdf_builder.dart';
import 'invoice_pdf_helpers.dart';

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

  static const _bg          = Color(0xFF0F172A);
  static const _surface     = Color(0xFF1E293B);
  static const _border      = Color(0xFF334155);
  static const _amber       = Color(0xFFF7A824);
  static const _amberDim    = Color(0xFF1A1208);
  static const _green       = Color(0xFF81C784);
  static const _textMuted   = Color(0xFF94A3B8);
  static const _cyan        = Color(0xFF00BCD4);

  @override
  Widget build(BuildContext context) {
    final data  = invoice.data() as Map<String, dynamic>;
    final items = invoice['items'] as List;

    final date          = data.containsKey('date')          ? '${invoice['date']}'          : 'No Date';
    final nextOilChange = data.containsKey('nextOilChange') ? '${invoice['nextOilChange']}' : 'Not Added';
    final kmTravelled   = data.containsKey('kmTravelled')   ? '${invoice['kmTravelled']}'   : '-';

    // Payment fields
    final int totalAmount   = (data['totalAmount']   as num?)?.toInt() ?? 0;
    final int advanceAmount = (data['advanceAmount'] as num?)?.toInt() ?? 0;
    final int balanceDue    = (data['balanceDue']    as num?)?.toInt() ?? (totalAmount - advanceAmount);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'INVOICE DETAILS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 0.5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Share button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => InvoicePdfBuilder(
                  invoice:       invoice,
                  customerName:  customerName,
                  phone:         phone,
                  vehicleNumber: vehicleNumber,
                ).generateAndShare(),
                icon:  const Icon(Icons.share_rounded),
                label: const Text('SHARE BILL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Customer info ─────────────────────────────────────────────
            Text(
              customerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              phone,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vehicleNumber,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            _infoText('Date : ${formatInvoiceDate(date)}'),
            const SizedBox(height: 6),
            _infoText('KM : $kmTravelled'),
            const SizedBox(height: 6),
            _infoText('Next Oil Change : $nextOilChange KM'),

            const SizedBox(height: 20),

            // ── Items table header ────────────────────────────────────────
            const Row(
              children: [
                Expanded(flex: 3, child: _HeaderCell('Service')),
                Expanded(child: _HeaderCell('Qty')),
                Expanded(child: _HeaderCell('Rate')),
                Expanded(child: _HeaderCell('Amount')),
              ],
            ),
            const Divider(color: Colors.white24),

            // ── Item rows ─────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item   = items[index];
                  final qty    = item['quantity'] ?? 1;
                  final rate   = item['rate'] ?? item['amount'] ?? 0;
                  final amount = (qty is num && rate is num)
                      ? (qty * rate).toStringAsFixed(0)
                      : '${item['amount'] ?? 0}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _rowText(item['service'] ?? ''),
                        ),
                        Expanded(child: _rowText('$qty')),
                        Expanded(child: _rowText('₹$rate')),
                        Expanded(child: _rowText('₹$amount')),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(color: Colors.white24),

            // ── Payment summary card ──────────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: _amberDim,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _amber.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  // Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          color: Color(0xFF9A7E4A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '₹$totalAmount',
                        style: const TextStyle(
                          color: _amber,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  if (advanceAmount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 0.5,
                      color: _amber.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),

                    // Advance Paid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ADVANCE PAID',
                          style: TextStyle(
                            color: Color(0xFF9A7E4A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '- ₹$advanceAmount',
                          style: const TextStyle(
                            color: _green,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(
                      height: 0.5,
                      color: _amber.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),

                    // Balance Due
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'BALANCE DUE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '₹$balanceDue',
                          style: TextStyle(
                            color: balanceDue <= 0 ? _green : _amber,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Full amount due',
                        style: TextStyle(
                          color: Color(0xFF6B5A3A),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoText(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );

  static Widget _rowText(String text) =>
      Text(text, style: const TextStyle(color: Colors.white));
}

/// Bold white column header cell.
class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );
}











// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:share_plus/share_plus.dart';
//
// // ─── BRAND COLORS ────────────────────────────────────────────────────────────
// const _kCyan    = PdfColor.fromInt(0xFF00BCD4);
// const _kBlack   = PdfColors.black;
// const _kWhite   = PdfColors.white;
// const _kGrey50  = PdfColor.fromInt(0xFFF7F7F7);
// const _kGrey200 = PdfColor.fromInt(0xFFEEEEEE);
// // ─────────────────────────────────────────────────────────────────────────────
//
// class InvoiceDetailsScreen extends StatelessWidget {
//   final QueryDocumentSnapshot invoice;
//   final String customerName;
//   final String phone;
//   final String vehicleNumber;
//
//   const InvoiceDetailsScreen({
//     super.key,
//     required this.invoice,
//     required this.customerName,
//     required this.phone,
//     required this.vehicleNumber,
//   });
//
//   // ── Asset Loaders ──────────────────────────────────────────────────────────
//
//   Future<pw.ImageProvider?> _loadLogo() async {
//     try {
//       final ByteData data = await rootBundle.load('assets/logo.jpg');
//       return pw.MemoryImage(data.buffer.asUint8List());
//     } catch (_) {
//       return null;
//     }
//   }
//
//   Future<Uint8List?> _loadWatermark() async {
//     try {
//       final ByteData data = await rootBundle.load('assets/watermark.jpg');
//       return data.buffer.asUint8List();
//     } catch (_) {
//       return null;
//     }
//   }
//
//   Future<pw.ImageProvider> _renderVerseAsImage(String verse) async {
//     const double canvasWidth  = 1400;
//     const double canvasHeight = 120;
//
//     final recorder  = ui.PictureRecorder();
//     final canvas    = Canvas(recorder);
//
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: verse,
//         style: const TextStyle(
//           fontSize: 42,
//           color: Color(0xFF555555),
//           fontFamily: 'NotoSansTamil',
//           fontStyle: FontStyle.italic,
//         ),
//       ),
//       textAlign: TextAlign.center,
//       textDirection: TextDirection.ltr,
//     );
//
//     textPainter.layout(maxWidth: canvasWidth);
//     textPainter.paint(canvas, Offset((canvasWidth - textPainter.width) / 2, 20));
//
//     final picture = recorder.endRecording();
//     final image   = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
//     final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//
//     return pw.MemoryImage(byteData!.buffer.asUint8List());
//   }
//
//   // ── PDF Generator ──────────────────────────────────────────────────────────
//
//   Future<void> generateAndSharePDF() async {
//     final pdf  = pw.Document();
//     final data = invoice.data() as Map<String, dynamic>;
//
//     final items         = invoice['items'] as List;
//     final date          = data.containsKey('date')          ? invoice['date']          : 'No Date';
//     final nextOilChange = data.containsKey('nextOilChange') ? invoice['nextOilChange'] : 'Not Added';
//     final kmTravelled   = data.containsKey('kmTravelled')   ? '${invoice['kmTravelled']}' : '-';
//
//     // ── Load assets ────────────────────────────────────────────────────────
//     final logoImage      = await _loadLogo();
//     final watermarkBytes = await _loadWatermark();
//     final verseImage     = await _renderVerseAsImage(
//       '"உன் வழிகளில் எல்லாம் உன்னை காப்பேன்" - இயேசு',
//     );
//
//     // ── Load fonts ─────────────────────────────────────────────────────────
//     final bold    = pw.Font.helveticaBold();
//     final normal  = pw.Font.helvetica();
//     final oblique = pw.Font.helveticaOblique();
//
//     // ── Build row models ───────────────────────────────────────────────────
//     final rows = List.generate(items.length, (i) {
//       final item   = items[i];
//       final qty    = item['quantity'] ?? 1;
//       final rate   = item['rate'] ?? item['amount'] ?? 0;
//       final amount = (qty is num && rate is num)
//           ? (qty * rate).toStringAsFixed(0)
//           : '${item['amount'] ?? 0}';
//       return _InvoiceRow(
//         sno:    '${i + 1}',
//         desc:   item['service'] ?? '',
//         qty:    '$qty',
//         rate:   '$rate',
//         amount: amount,
//       );
//     });
//
//     final total = rows.fold<double>(
//       0,
//           (sum, r) => sum + (double.tryParse(r.amount) ?? 0),
//     );
//
//     // ── Watermark PdfImage (reused across pages) ───────────────────────────
//     final PdfImage? wmPdfImage = watermarkBytes != null
//         ? PdfImage.jpeg(pdf.document, image: watermarkBytes)
//         : null;
//
//     // ── Column widths (shared) ─────────────────────────────────────────────
//     final columnWidths = <int, pw.TableColumnWidth>{
//       0: const pw.FixedColumnWidth(42),
//       1: const pw.FlexColumnWidth(4),
//       2: const pw.FixedColumnWidth(45),
//       3: const pw.FixedColumnWidth(60),
//       4: const pw.FixedColumnWidth(70),
//     };
//
//     // ── Helper: wrap page content with watermark ───────────────────────────
//     pw.Widget withWatermark({
//       required pw.Widget child,
//       required double pageW,
//       required double pageH,
//     }) {
//       const wmSize = 300.0;
//       return pw.CustomPaint(
//         size: PdfPoint(pageW, pageH),
//         painter: (PdfGraphics canvas, PdfPoint size) {
//           if (wmPdfImage != null) {
//             canvas.saveContext();
//             canvas.setGraphicState(PdfGraphicState(opacity: 0.08));
//             canvas.drawImage(
//               wmPdfImage,
//               (pageW - wmSize) / 2,
//               (pageH - wmSize) / 2,
//               wmSize,
//               wmSize,
//             );
//             canvas.restoreContext();
//           }
//         },
//         foregroundPainter: (_, __) {},
//         child: child,
//       );
//     }
//
//     // ── MultiPage ──────────────────────────────────────────────────────────
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.zero,
//
//         // ── Page header ────────────────────────────────────────────────────
//         header: (pw.Context ctx) {
//           if (ctx.pageNumber == 1) {
//             // Full premium header on page 1
//             return pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//               children: [
//                 // Top cyan strip
//                 _cyanStrip(),
//
//                 // Bible verse
//                 pw.Container(
//                   alignment: pw.Alignment.center,
//                   padding: const pw.EdgeInsets.only(top: 8, bottom: 6),
//                   child: pw.Image(verseImage, width: 320),
//                 ),
//
//                 // Logo + shop title
//                 pw.Container(
//                   color: _kWhite,
//                   padding: const pw.EdgeInsets.symmetric(
//                       horizontal: 30, vertical: 14),
//                   height: 100,
//                   child: pw.Stack(
//                     alignment: pw.Alignment.center,
//                     children: [
//                       // Centered title
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.center,
//                         children: [
//                           pw.Text(
//                             "DAVID'S BIKES",
//                             textAlign: pw.TextAlign.center,
//                             style: pw.TextStyle(
//                               font: bold,
//                               fontSize: 22,
//                               color: _kBlack,
//                               letterSpacing: 1.2,
//                             ),
//                           ),
//                           pw.SizedBox(height: 2),
//                           pw.Text(
//                             'BIKE SERVICE & MAINTENANCE',
//                             style: pw.TextStyle(
//                               font: normal,
//                               fontSize: 10,
//                               color: _kCyan,
//                               letterSpacing: 0.8,
//                             ),
//                           ),
//                           pw.SizedBox(height: 6),
//                           pw.Text(
//                             'Phone : 83443 41912',
//                             style: pw.TextStyle(
//                                 font: bold, fontSize: 8, color: _kBlack),
//                           ),
//                         ],
//                       ),
//                       // Logo pinned left
//                       if (logoImage != null)
//                         pw.Positioned(
//                           left: 0,
//                           child: pw.Container(
//                             width: 70,
//                             height: 70,
//                             child: pw.ClipRRect(
//                               horizontalRadius: 6,
//                               verticalRadius: 6,
//                               child:
//                               pw.Image(logoImage, fit: pw.BoxFit.cover),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//
//                 // INVOICE label
//                 pw.Container(
//                   color: _kWhite,
//                   alignment: pw.Alignment.center,
//                   padding: const pw.EdgeInsets.only(bottom: 6),
//                   child: pw.Text(
//                     'INVOICE',
//                     style: pw.TextStyle(
//                       font: bold,
//                       fontSize: 13,
//                       color: _kCyan,
//                       letterSpacing: 3,
//                     ),
//                   ),
//                 ),
//
//                 // Customer info table
//                 pw.Padding(
//                   padding:
//                   const pw.EdgeInsets.symmetric(horizontal: 20),
//                   child: pw.Table(
//                     border: pw.TableBorder.all(
//                         color: _kBlack, width: 0.8),
//                     columnWidths: {
//                       0: const pw.FlexColumnWidth(3),
//                       1: const pw.FlexColumnWidth(3),
//                     },
//                     children: [
//                       pw.TableRow(children: [
//                         _infoCell(
//                             'NAME :  $customerName',
//                             bold,
//                             fontSize: 9),
//                         _infoCell(
//                             'INVOICE DATE :  ${_formatDate(date)}',
//                             bold,
//                             fontSize: 9),
//                       ]),
//                       pw.TableRow(children: [
//                         _infoCell('PHONE NUMBER :  $phone', bold,
//                             fontSize: 9),
//                         _infoCell(
//                             'VEHICLE NO :  $vehicleNumber', bold,
//                             fontSize: 9),
//                       ]),
//                       pw.TableRow(children: [
//                         _infoCell(
//                             'KM TRAVELLED :  $kmTravelled km', bold,
//                             fontSize: 9),
//                         _infoCell(
//                             'NEXT OIL CHANGE :  $nextOilChange km',
//                             bold,
//                             fontSize: 9),
//                       ]),
//                     ],
//                   ),
//                 ),
//
//                 pw.SizedBox(height: 14),
//
//                 // Services table header (sticky on page 1)
//                 _tableHeader(columnWidths, bold),
//               ],
//             );
//           } else {
//             // Continuation header on subsequent pages
//             return pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//               children: [
//                 _cyanStrip(height: 14),
//                 pw.Container(
//                   color: _kWhite,
//                   padding: const pw.EdgeInsets.symmetric(
//                       horizontal: 20, vertical: 8),
//                   child: pw.Row(
//                     mainAxisAlignment:
//                     pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text(
//                         "DAVID'S BIKES  •  INVOICE CONTINUED",
//                         style: pw.TextStyle(
//                           font: bold,
//                           fontSize: 9,
//                           color: _kCyan,
//                           letterSpacing: 1.0,
//                         ),
//                       ),
//                       pw.Text(
//                         'Page ${ctx.pageNumber}',
//                         style: pw.TextStyle(
//                           font: normal,
//                           fontSize: 9,
//                           color: const PdfColor.fromInt(0xFF888888),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 pw.SizedBox(height: 4),
//                 // Repeat table header on every continuation page
//                 _tableHeader(columnWidths, bold),
//               ],
//             );
//           }
//         },
//
//         // ── Page footer (last page only) ───────────────────────────────────
//         footer: (pw.Context ctx) {
//           if (!ctx.pagesCount.isNaN && ctx.pageNumber == ctx.pagesCount) {
//             return pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//               children: [
//                 // Total row
//                 pw.Padding(
//                   padding:
//                   const pw.EdgeInsets.symmetric(horizontal: 8),
//                   child: pw.Table(
//                     border: pw.TableBorder(
//                       left: pw.BorderSide(
//                           color: _kBlack, width: 0.8),
//                       right: pw.BorderSide(
//                           color: _kBlack, width: 0.8),
//                       bottom: pw.BorderSide(
//                           color: _kBlack, width: 0.8),
//                       top: pw.BorderSide.none,
//                       horizontalInside: pw.BorderSide.none,
//                       verticalInside: pw.BorderSide.none,
//                     ),
//                     columnWidths: columnWidths,
//                     children: [
//                       pw.TableRow(
//                         decoration: const pw.BoxDecoration(
//                             color: _kBlack),
//                         children: [
//                           pw.Container(height: 30),
//                           pw.Container(height: 30),
//                           pw.Container(height: 30),
//                           pw.Padding(
//                             padding:
//                             const pw.EdgeInsets.symmetric(
//                                 horizontal: 6, vertical: 10),
//                             child: pw.Text(
//                               'TOTAL',
//                               textAlign: pw.TextAlign.right,
//                               style: pw.TextStyle(
//                                   font: bold,
//                                   fontSize: 10,
//                                   color: _kWhite),
//                             ),
//                           ),
//                           pw.Padding(
//                             padding:
//                             const pw.EdgeInsets.symmetric(
//                                 horizontal: 6, vertical: 10),
//                             child: pw.Text(
//                               'Rs. ${total.toStringAsFixed(0)}',
//                               textAlign: pw.TextAlign.right,
//                               style: pw.TextStyle(
//                                   font: bold,
//                                   fontSize: 10,
//                                   color: _kWhite),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 pw.SizedBox(height: 10),
//
//                 // Rupees in words
//                 pw.Padding(
//                   padding:
//                   const pw.EdgeInsets.symmetric(horizontal: 20),
//                   child: pw.Container(
//                     decoration: pw.BoxDecoration(
//                       border: pw.Border.all(
//                           color: _kBlack, width: 0.8),
//                     ),
//                     padding: const pw.EdgeInsets.symmetric(
//                         horizontal: 10, vertical: 6),
//                     child: pw.Text(
//                       'RUPEES IN WORDS :  ${_amountInWords(total)}',
//                       style: pw.TextStyle(
//                           font: bold, fontSize: 8, color: _kBlack),
//                     ),
//                   ),
//                 ),
//
//                 pw.SizedBox(height: 16),
//
//                 // Signature
//                 pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(
//                       horizontal: 20, vertical: 10),
//                   child: pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.end,
//                     children: [
//                       pw.Column(
//                         crossAxisAlignment:
//                         pw.CrossAxisAlignment.center,
//                         children: [
//                           pw.Text(
//                             'Thavithu Abraham',
//                             style: pw.TextStyle(
//                               font: oblique,
//                               fontSize: 13,
//                               color: _kBlack,
//                             ),
//                           ),
//                           pw.SizedBox(height: 2),
//                           pw.Container(
//                               width: 120,
//                               height: 0.8,
//                               color: _kBlack),
//                           pw.SizedBox(height: 3),
//                           pw.Text(
//                             'SIGNATURE',
//                             style: pw.TextStyle(
//                                 font: bold,
//                                 fontSize: 8,
//                                 color: _kBlack),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Bottom cyan strip
//                 _cyanStrip(),
//               ],
//             );
//           }
//           // No footer on page 1 or middle pages
//           return pw.SizedBox.shrink();
//         },
//
//         // ── Page body: service rows ────────────────────────────────────────
//         build: (pw.Context ctx) {
//           return [
//             pw.Padding(
//               padding: const pw.EdgeInsets.symmetric(horizontal: 8),
//               child: pw.Table(
//                 border: pw.TableBorder(
//                   left: pw.BorderSide(
//                       color: _kBlack, width: 0.8),
//                   right: pw.BorderSide(
//                       color: _kBlack, width: 0.8),
//                   bottom: pw.BorderSide.none,
//                   top: pw.BorderSide.none,
//                   horizontalInside: pw.BorderSide.none,
//                   verticalInside: pw.BorderSide.none,
//                 ),
//                 columnWidths: columnWidths,
//                 children: rows.asMap().entries.map((entry) {
//                   final i   = entry.key;
//                   final r   = entry.value;
//                   final bg  = i.isEven ? _kWhite : _kGrey50;
//
//                   return pw.TableRow(
//                     decoration: pw.BoxDecoration(color: bg),
//                     children: [
//                       _tableCell(r.sno,   normal, bg: bg, align: pw.TextAlign.center),
//                       _tableCell(r.desc,  normal, bg: bg),
//                       _tableCell(r.qty,   normal, bg: bg, align: pw.TextAlign.center),
//                       _tableCell('Rs. ${r.rate}', normal, bg: bg, align: pw.TextAlign.center),
//                       _tableCell('Rs. ${r.amount}', bold, bg: bg, align: pw.TextAlign.right),
//                     ],
//                   );
//                 }).toList(),
//               ),
//             ),
//           ];
//         },
//       ),
//     );
//
//     // ── Save & share ───────────────────────────────────────────────────────
//     final output = await getTemporaryDirectory();
//     final file   = File('${output.path}/invoice.pdf');
//     await file.writeAsBytes(await pdf.save());
//
//     await Share.shareXFiles(
//       [XFile(file.path)],
//       text: "DAVID'S BIKES Service Invoice",
//       subject: 'Service Bill',
//     );
//   }
//
//   // ── Helper: format date from yyyy-MM-dd to dd-MM-yyyy ─────────────────────
//   static String _formatDate(String raw) {
//     try {
//       return raw.split('-').reversed.join('-');
//     } catch (_) {
//       return raw;
//     }
//   }
//
//   // ── Helper: top/bottom cyan decorative strip ───────────────────────────────
//   static pw.Widget _cyanStrip({double height = 18}) {
//     return pw.Row(
//       children: [
//         pw.Container(
//             width: 30,
//             height: height,
//             color: const PdfColor.fromInt(0xFF000000)),
//         pw.Expanded(
//             child: pw.Container(height: height, color: _kCyan)),
//         pw.Container(
//             width: 30,
//             height: height,
//             color: const PdfColor.fromInt(0xFF000000)),
//       ],
//     );
//   }
//
//   // ── Helper: customer info cell ─────────────────────────────────────────────
//   static pw.Widget _infoCell(
//       String text,
//       pw.Font bold, {
//         double fontSize = 9,
//       }) {
//     return pw.Container(
//       color: _kWhite,
//       padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
//       child: pw.Text(
//         text,
//         style: pw.TextStyle(font: bold, fontSize: fontSize, color: _kBlack),
//       ),
//     );
//   }
//
//   // ── Helper: table header row ───────────────────────────────────────────────
//   static pw.Widget _tableHeader(
//       Map<int, pw.TableColumnWidth> columnWidths,
//       pw.Font bold,
//       ) {
//     pw.Widget hCell(String text,
//         {pw.TextAlign align = pw.TextAlign.left}) {
//       return pw.Padding(
//         padding:
//         const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
//         child: pw.Text(
//           text,
//           textAlign: align,
//           style: pw.TextStyle(
//               font: bold, fontSize: 10, color: _kWhite),
//         ),
//       );
//     }
//
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(horizontal: 8),
//       child: pw.Table(
//         border: pw.TableBorder(
//           top: pw.BorderSide(color: _kBlack, width: 0.8),
//           left: pw.BorderSide(color: _kBlack, width: 0.8),
//           right: pw.BorderSide(color: _kBlack, width: 0.8),
//           bottom: pw.BorderSide.none,
//           horizontalInside: pw.BorderSide.none,
//           verticalInside: pw.BorderSide.none,
//         ),
//         columnWidths: columnWidths,
//         children: [
//           pw.TableRow(
//             decoration: const pw.BoxDecoration(color: _kBlack),
//             children: [
//               hCell('S.NO',        align: pw.TextAlign.center),
//               hCell('DESCRIPTION'),
//               hCell('QTY',         align: pw.TextAlign.center),
//               hCell('RATE',        align: pw.TextAlign.center),
//               hCell('AMOUNT',      align: pw.TextAlign.right),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ── Helper: table data cell ────────────────────────────────────────────────
//   static pw.Widget _tableCell(
//       String text,
//       pw.Font font, {
//         PdfColor bg = _kWhite,
//         pw.TextAlign align = pw.TextAlign.left,
//         double fontSize = 10,
//       }) {
//     return pw.Container(
//       color: bg,
//       padding:
//       const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
//       child: pw.Text(
//         text,
//         textAlign: align,
//         style: pw.TextStyle(font: font, fontSize: fontSize, color: _kBlack),
//       ),
//     );
//   }
//
//   // ── Amount in words (supports up to 99,99,999) ─────────────────────────────
//   static String _amountInWords(double amount) {
//     final ones = [
//       '',        'One',      'Two',       'Three',    'Four',
//       'Five',    'Six',      'Seven',     'Eight',    'Nine',
//       'Ten',     'Eleven',   'Twelve',    'Thirteen', 'Fourteen',
//       'Fifteen', 'Sixteen',  'Seventeen', 'Eighteen', 'Nineteen',
//     ];
//     final tens = [
//       '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
//       'Sixty', 'Seventy', 'Eighty', 'Ninety',
//     ];
//
//     String _convertBelow100(int n) {
//       if (n <= 0) return '';
//       if (n < 20) return ones[n];
//       final t = tens[n ~/ 10];
//       final o = n % 10 > 0 ? ' ${ones[n % 10]}' : '';
//       return '$t$o';
//     }
//
//     String _convertBelow1000(int n) {
//       if (n <= 0) return '';
//       if (n < 100) return _convertBelow100(n);
//       final h = ones[n ~/ 100];
//       final rem = n % 100;
//       final rest = rem > 0 ? ' ${_convertBelow100(rem)}' : '';
//       return '$h Hundred$rest';
//     }
//
//     int n = amount.round().clamp(0, 9999999);
//     if (n == 0) return 'Zero Rupees Only';
//
//     String words = '';
//
//     // Lakhs (Indian numbering)
//     if (n >= 100000) {
//       final lakh = n ~/ 100000;
//       words += '${_convertBelow1000(lakh)} Lakh ';
//       n %= 100000;
//     }
//
//     // Thousands
//     if (n >= 1000) {
//       final thou = n ~/ 1000;
//       words += '${_convertBelow100(thou)} Thousand ';
//       n %= 1000;
//     }
//
//     // Hundreds
//     if (n >= 100) {
//       words += '${ones[n ~/ 100]} Hundred ';
//       n %= 100;
//     }
//
//     // Tens and ones
//     if (n > 0) {
//       words += _convertBelow100(n);
//     }
//
//     return '${words.trim()} Rupees Only';
//   }
//
//   // ── UI Screen ─────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final data  = invoice.data() as Map<String, dynamic>;
//     final items = invoice['items'] as List;
//
//     final date = data.containsKey('date') ? invoice['date'] : 'No Date';
//     final nextOilChange = data.containsKey('nextOilChange')
//         ? invoice['nextOilChange']
//         : 'Not Added';
//
//     double total = 0;
//     for (final item in items) {
//       final qty  = item['quantity'] ?? 1;
//       final rate = item['rate'] ?? item['amount'] ?? 0;
//       if (qty is num && rate is num) total += qty * rate;
//     }
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF0F172A),
//         elevation: 0,
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: const Text(
//           'INVOICE DETAILS',
//           style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Share button
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 onPressed: generateAndSharePDF,
//                 icon: const Icon(Icons.share),
//                 label: const Text('SHARE BILL'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00BCD4),
//                   foregroundColor: Colors.white,
//                   textStyle: const TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.bold),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10)),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//             // Customer info
//             Text(customerName,
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold)),
//             const SizedBox(height: 6),
//             Text(phone,
//                 style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold)),
//             const SizedBox(height: 4),
//             Text(vehicleNumber,
//                 style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             Text(
//               'Date : ${_formatDate(date)}',
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'KM : ${data.containsKey('kmTravelled') ? invoice['kmTravelled'] : '-'}',
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'Next Oil Change : $nextOilChange KM',
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Table header
//             const Row(
//               children: [
//                 Expanded(
//                     flex: 3,
//                     child: Text('Service',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 15))),
//                 Expanded(
//                     child: Text('Qty',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 15))),
//                 Expanded(
//                     child: Text('Rate',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 15))),
//                 Expanded(
//                     child: Text('Amount',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 15))),
//               ],
//             ),
//             const Divider(color: Colors.white24),
//
//             // Item list
//             Expanded(
//               child: ListView.builder(
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   final item   = items[index];
//                   final qty    = item['quantity'] ?? 1;
//                   final rate   = item['rate'] ?? item['amount'] ?? 0;
//                   final amount = (qty is num && rate is num)
//                       ? (qty * rate).toStringAsFixed(0)
//                       : '${item['amount'] ?? 0}';
//
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                             flex: 3,
//                             child: Text(item['service'] ?? '',
//                                 style: const TextStyle(
//                                     color: Colors.white))),
//                         Expanded(
//                             child: Text('$qty',
//                                 style: const TextStyle(
//                                     color: Colors.white))),
//                         Expanded(
//                             child: Text('Rs.$rate',
//                                 style: const TextStyle(
//                                     color: Colors.white))),
//                         Expanded(
//                             child: Text('Rs.$amount',
//                                 style: const TextStyle(
//                                     color: Colors.white))),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//
//             const Divider(color: Colors.white24),
//
//             // Total
//             Align(
//               alignment: Alignment.centerRight,
//               child: Text(
//                 'Total : Rs.${total.toStringAsFixed(0)}',
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ── Internal row model ─────────────────────────────────────────────────────────
// class _InvoiceRow {
//   final String sno;
//   final String desc;
//   final String qty;
//   final String rate;
//   final String amount;
//
//   const _InvoiceRow({
//     required this.sno,
//     required this.desc,
//     required this.qty,
//     required this.rate,
//     required this.amount,
//   });
// }