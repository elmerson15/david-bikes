// invoice_pdf_helpers.dart
// ─────────────────────────────────────────────────────────────────────────────
// Shared: brand colors, row model, PDF widget helpers, amount-in-words.
// Imported by both invoice_pdf_builder.dart and invoice_details_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

// ── Brand Colors ──────────────────────────────────────────────────────────────
const kPdfCyan   = PdfColor.fromInt(0xFF00BCD4);
const kPdfBlack  = PdfColors.black;
const kPdfWhite  = PdfColors.white;
const kPdfGrey50 = PdfColor.fromInt(0xFFF7F7F7);

// ── Row Model ─────────────────────────────────────────────────────────────────
class InvoiceRow {
  final String sno;
  final String desc;
  final String qty;
  final String rate;
  final String amount;

  const InvoiceRow({
    required this.sno,
    required this.desc,
    required this.qty,
    required this.rate,
    required this.amount,
  });
}

// ── PDF Widget Helpers ────────────────────────────────────────────────────────

/// Top / bottom decorative cyan strip.
pw.Widget pdfCyanStrip({double height = 18}) {
  return pw.Row(
    children: [
      pw.Container(
          width: 30, height: height,
          color: const PdfColor.fromInt(0xFF000000)),
      pw.Expanded(
          child: pw.Container(height: height, color: kPdfCyan)),
      pw.Container(
          width: 30, height: height,
          color: const PdfColor.fromInt(0xFF000000)),
    ],
  );
}

/// Customer info table cell (bold text, white bg).
pw.Widget pdfInfoCell(
  String text,
  pw.Font bold, {
  double fontSize = 9,
}) {
  return pw.Container(
    color: kPdfWhite,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(font: bold, fontSize: fontSize, color: kPdfBlack),
    ),
  );
}

/// Black header row for the services table.
pw.Widget pdfTableHeader(
  Map<int, pw.TableColumnWidth> columnWidths,
  pw.Font bold,
) {
  pw.Widget hCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: bold, fontSize: 10, color: kPdfWhite),
      ),
    );
  }

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8),
    child: pw.Table(
      border: pw.TableBorder(
        top:              pw.BorderSide(color: kPdfBlack, width: 0.8),
        left:             pw.BorderSide(color: kPdfBlack, width: 0.8),
        right:            pw.BorderSide(color: kPdfBlack, width: 0.8),
        bottom:           pw.BorderSide.none,
        horizontalInside: pw.BorderSide.none,
        verticalInside:   pw.BorderSide.none,
      ),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: kPdfBlack),
          children: [
            hCell('S.NO',        align: pw.TextAlign.center),
            hCell('DESCRIPTION'),
            hCell('QTY',         align: pw.TextAlign.center),
            hCell('RATE',        align: pw.TextAlign.center),
            hCell('AMOUNT',      align: pw.TextAlign.right),
          ],
        ),
      ],
    ),
  );
}

/// Standard body cell for the services table.
pw.Widget pdfTableCell(
  String text,
  pw.Font font, {
  PdfColor bg            = kPdfWhite,
  pw.TextAlign align     = pw.TextAlign.left,
  double fontSize        = 10,
}) {
  return pw.Container(
    color: bg,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(font: font, fontSize: fontSize, color: kPdfBlack),
    ),
  );
}

// ── Utilities ─────────────────────────────────────────────────────────────────

/// Converts yyyy-MM-dd → dd-MM-yyyy.
String formatInvoiceDate(String raw) {
  try {
    return raw.split('-').reversed.join('-');
  } catch (_) {
    return raw;
  }
}

/// Converts a rupee amount to Indian-English words (up to ₹99,99,999).
String amountInWords(double amount) {
  const ones = [
    '',        'One',      'Two',       'Three',    'Four',
    'Five',    'Six',      'Seven',     'Eight',    'Nine',
    'Ten',     'Eleven',   'Twelve',    'Thirteen', 'Fourteen',
    'Fifteen', 'Sixteen',  'Seventeen', 'Eighteen', 'Nineteen',
  ];
  const tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
    'Sixty', 'Seventy', 'Eighty', 'Ninety',
  ];

  String below100(int n) {
    if (n <= 0) return '';
    if (n < 20) return ones[n];
    final t = tens[n ~/ 10];
    final o = n % 10 > 0 ? ' ${ones[n % 10]}' : '';
    return '$t$o';
  }

  String below1000(int n) {
    if (n <= 0) return '';
    if (n < 100) return below100(n);
    final h   = ones[n ~/ 100];
    final rem = n % 100;
    final rest = rem > 0 ? ' ${below100(rem)}' : '';
    return '$h Hundred$rest';
  }

  int n = amount.round().clamp(0, 9999999);
  if (n == 0) return 'Zero Rupees Only';

  String words = '';
  if (n >= 100000) { words += '${below1000(n ~/ 100000)} Lakh ';    n %= 100000; }
  if (n >= 1000)   { words += '${below100(n ~/ 1000)} Thousand ';   n %= 1000;   }
  if (n >= 100)    { words += '${ones[n ~/ 100]} Hundred ';         n %= 100;    }
  if (n > 0)       { words += below100(n); }

  return '${words.trim()} Rupees Only';
}