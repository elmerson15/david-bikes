import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bikes/screens/invoice/invoice_details_screen.dart';

class RecentBillsScreen extends StatelessWidget {
  const RecentBillsScreen({super.key});

  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF222222);
  static const _amber = Color(0xFFF7A824);
  static const _amberDim = Color(0xFF1A1208);
  static const _textPrimary = Color(0xFFE0E0E0);
  static const _textMuted = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recent Bills',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 0.5),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collectionGroup('invoices').snapshots(),
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: _textMuted,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Bills Found',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Recent invoices will appear here',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final invoices = snapshot.data!.docs;

          invoices.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = aData['date']?.toString() ?? '';
            final bDate = bData['date']?.toString() ?? '';
            return bDate.compareTo(aDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              final data = invoice.data() as Map<String, dynamic>;
              final date =
              data.containsKey('date') ? invoice['date'] : 'No Date';

              return FutureBuilder<DocumentSnapshot>(
                future: invoice.reference.parent.parent!.get(),
                builder: (context, customerSnap) {
                  String customerName = 'Loading...';
                  String phone = '';
                  String vehicleNumber = '';

                  if (customerSnap.connectionState ==
                      ConnectionState.done) {
                    if (customerSnap.hasData &&
                        customerSnap.data!.exists) {
                      final customerData =
                      customerSnap.data!.data()
                      as Map<String, dynamic>;

                      customerName =
                          customerData['customerName'] ?? 'Unknown';
                      phone = customerData['phone'] ?? '';
                      vehicleNumber =
                          customerData['vehicleNumber'] ?? '';
                    } else {
                      customerName = 'Unknown';
                    }
                  }

                  return _BillCard(
                    invoice: invoice,
                    date: date,
                    customerName: customerName,
                    phone: phone,
                    vehicleNumber: vehicleNumber,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final QueryDocumentSnapshot invoice;
  final String date;
  final String customerName;
  final String phone;
  final String vehicleNumber;

  const _BillCard({
    required this.invoice,
    required this.date,
    required this.customerName,
    required this.phone,
    required this.vehicleNumber,
  });

  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF222222);
  static const _amber = Color(0xFFF7A824);
  static const _amberDim = Color(0xFF1A1208);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailsScreen(
              invoice: invoice,
              customerName: customerName,
              phone: phone,
              vehicleNumber: vehicleNumber,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _amberDim,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color:
                          _amber.withOpacity(0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: _amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${invoice['totalAmount']}',
                          style: const TextStyle(
                            color: _amber,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.speed_rounded,
                              color: Colors.white54,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${invoice['kmTravelled']} km',
                              style:
                              const TextStyle(
                                color:
                                Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _amberDim,
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                      color:
                      _amber.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: _amber,
                        size: 11,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        date,
                        style: const TextStyle(
                          color: _amber,
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}