import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_invoice_screen.dart';
import 'invoice_details_screen.dart';

class InvoiceListScreen extends StatelessWidget {
  final String vehicleId;
  final String customerName;
  final String phone;
  final String vehicleNumber;

  const InvoiceListScreen({
    super.key,
    required this.vehicleId,
    required this.customerName,
    required this.phone,
    required this.vehicleNumber,
  });

  static const _bg          = Color(0xFF0F0F0F);
  static const _surface     = Color(0xFF141414);
  static const _border      = Color(0xFF222222);
  static const _amber       = Color(0xFFF7A824);
  static const _textPrimary = Color(0xFFE0E0E0);
  static const _textMuted   = Color(0xFF555555);

  /// Converts any stored date string into DD-MM-YYYY.
  /// Handles "YYYY-MM-DD", "DD/MM/YYYY", "DD-MM-YYYY", and Timestamps.
  static String _formatDate(dynamic raw) {
    if (raw == null) return 'No Date';
    // Firestore Timestamp
    if (raw is Timestamp) {
      final dt = raw.toDate();
      return '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year.toString().substring(2)}';
    }
    final s = raw.toString().trim();
    // YYYY-MM-DD  →  DD-MM-YYYY
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final isoMatch = iso.firstMatch(s);
    if (isoMatch != null) {
      return '${isoMatch.group(3)}-${isoMatch.group(2)}-${isoMatch.group(1)!.substring(2)}';
    }
    // DD/MM/YYYY  →  DD-MM-YYYY
    final slash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final slashMatch = slash.firstMatch(s);
    if (slashMatch != null) {
      return '${slashMatch.group(1)}-${slashMatch.group(2)}-${slashMatch.group(3)}';
    }
    // Already DD-MM-YYYY or unrecognised — return as-is
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoices',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              vehicleNumber,
              style: const TextStyle(color: _textMuted, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 0.5),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .collection('invoices')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _amber),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width:  64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: _textMuted, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Invoices Found',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Invoices for this vehicle will appear here',
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final invoices = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              final data    = invoice.data() as Map<String, dynamic>;
              // ── FIX: formatted date ──────────────────────────────────────
              final date = _formatDate(data['date']);

              return _InvoiceCard(
                invoice:       invoice,
                date:          date,
                customerName:  customerName,
                phone:         phone,
                vehicleNumber: vehicleNumber,
                vehicleId:     vehicleId,
              );
            },
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final QueryDocumentSnapshot invoice;
  final String date;
  final String customerName;
  final String phone;
  final String vehicleNumber;
  final String vehicleId;

  const _InvoiceCard({
    required this.invoice,
    required this.date,
    required this.customerName,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleId,
  });

  static const _surface     = Color(0xFF141414);
  static const _border      = Color(0xFF222222);
  static const _amber       = Color(0xFFF7A824);
  static const _amberDim    = Color(0xFF1A1208);
  static const _textMuted   = Color(0xFF555555);

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _border),
        ),
        title: const Text(
          'Delete Invoice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to delete this invoice? This action cannot be undone.',
          style: TextStyle(color: _textMuted, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(vehicleId)
                  .collection('invoices')
                  .doc(invoice.id)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                  color: Color(0xFFE57373), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInvoiceScreen(
          vehicleId:    vehicleId,
          invoiceId:    invoice.id,
          existingData: invoice.data() as Map<String, dynamic>,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailsScreen(
                invoice:       invoice,
                customerName:  customerName,
                phone:         phone,
                vehicleNumber: vehicleNumber,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          splashColor:    Colors.white.withOpacity(0.03),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                /// ICON
                Container(
                  width:  46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _amberDim,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _amber.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: _amber, size: 22),
                ),

                const SizedBox(width: 14),

                /// INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${invoice['totalAmount']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      // ── FIX: overflow-safe km + date row ────────────────
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${invoice['kmTravelled']} km',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.calendar_today_rounded,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              date,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ACTIONS
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    GestureDetector(
                      onTap: () => _openEditScreen(context),
                      child: Container(
                        width:  36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _amber.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: _amber, size: 17),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    GestureDetector(
                      onTap: () => _showDeleteDialog(context),
                      child: Container(
                        width:  36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE57373).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFE57373).withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFE57373), size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        color: _textMuted, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}