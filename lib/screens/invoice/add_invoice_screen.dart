import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddInvoiceScreen extends StatefulWidget {
  final String vehicleId;

  const AddInvoiceScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final kmController = TextEditingController();
  final nextOilChangeController = TextEditingController();
  final advanceController = TextEditingController();

  List<Map<String, TextEditingController>> services = [];

  bool isLoading = false;
  int totalAmount = 0;
  int advanceAmount = 0;

  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF2E2E2E);
  static const _amber = Color(0xFFF7A824);
  static const _amberDim = Color(0xFF1A1208);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textMuted = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    addServiceRow();
  }

  @override
  void dispose() {
    kmController.dispose();
    nextOilChangeController.dispose();
    advanceController.dispose();

    for (var item in services) {
      item['service']?.dispose();
      item['quantity']?.dispose();
      item['rate']?.dispose();
      item['amount']?.dispose();
    }

    super.dispose();
  }

  void addServiceRow() {
    services.add({
      'service': TextEditingController(),
      'quantity': TextEditingController(text: '1'),
      'rate': TextEditingController(),
      'amount': TextEditingController(),
    });

    setState(() {});
  }

  void calculateTotal() {
    int total = 0;

    for (var item in services) {
      int qty = int.tryParse(item['quantity']!.text.trim()) ?? 0;
      int rate = int.tryParse(item['rate']!.text.trim()) ?? 0;
      int amount = qty * rate;

      item['amount']!.value = TextEditingValue(
        text: amount.toString(),
        selection: TextSelection.collapsed(
          offset: amount.toString().length,
        ),
      );

      total += amount;
    }

    setState(() {
      totalAmount = total;
    });
  }

  void deleteRow(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border),
          ),
          title: const Text(
            'Delete Row',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Delete this service row?',
            style: TextStyle(
              color: _textMuted,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                services[index]['service']?.dispose();
                services[index]['quantity']?.dispose();
                services[index]['rate']?.dispose();
                services[index]['amount']?.dispose();

                services.removeAt(index);

                calculateTotal();

                Navigator.pop(context);

                setState(() {});
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFEF9A9A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveInvoice() async {
    if (kmController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEF9A9A)),
          ),
          content: const Text(
            'Please enter KM Travelled',
            style: TextStyle(color: Color(0xFFEF9A9A)),
          ),
        ),
      );
      return;
    }
    try {
      setState(() => isLoading = true);

      List<Map<String, dynamic>> invoiceItems = [];

      for (var item in services) {
        invoiceItems.add({
          'service': item['service']!.text.trim(),
          'quantity': int.tryParse(item['quantity']!.text.trim()) ?? 0,
          'rate': int.tryParse(item['rate']!.text.trim()) ?? 0,
          'amount': int.tryParse(item['amount']!.text.trim()) ?? 0,
        });
      }

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('invoices')
          .add({
        'kmTravelled': kmController.text.trim(),
        'nextOilChange': nextOilChangeController.text.trim(),
        'items': invoiceItems,
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
        'balanceDue': totalAmount - advanceAmount,
        'createdAt': Timestamp.now(),
        'date': DateTime.now().toString().substring(0, 10),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _border),
          ),
          content: const Text(
            'Invoice saved successfully',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _surface,
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  InputDecoration inputDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _textMuted,
        fontSize: 13,
      ),
      prefixIcon: icon != null
          ? Icon(
        icon,
        color: _amber,
        size: 20,
      )
          : null,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _amber,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  InputDecoration compactInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _textMuted,
        fontSize: 12,
      ),
      filled: true,
      fillColor: Color(0xFF1C1C1C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _amber, width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceDue = totalAmount - advanceAmount;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Invoice',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: _border,
            height: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HERO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _amberDim,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _amber.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'INVOICE',
                    style: TextStyle(
                      color: _amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Service Billing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create a workshop invoice',
                    style: TextStyle(
                      color: Color(0xFF9A7E4A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'VEHICLE DETAILS',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            /// KM FIELD
            TextField(
              controller: kmController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _textPrimary),
              decoration: inputDecoration(
                hint: 'KM Travelled',
                icon: Icons.speed_rounded,
              ),
            ),

            const SizedBox(height: 14),

            /// NEXT OIL CHANGE FIELD
            TextField(
              controller: nextOilChangeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _textPrimary),
              decoration: inputDecoration(
                hint: 'Next Oil Change (KM)',
                icon: Icons.oil_barrel_rounded,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'SERVICES',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            /// SERVICE ROWS
            Column(
              children: List.generate(
                services.length,
                    (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// LINE 1 — Service name + delete button
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: services[index]['service'],
                                textCapitalization:
                                TextCapitalization.characters,
                                onChanged: (value) {
                                  services[index]['service']!.value =
                                      TextEditingValue(
                                        text: value.toUpperCase(),
                                        selection: TextSelection.collapsed(
                                          offset: value.length,
                                        ),
                                      );
                                },
                                style: const TextStyle(color: _textPrimary),
                                decoration: compactInputDecoration(
                                  hint: 'Service name',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => deleteRow(index),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF9A9A)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEF9A9A)
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF9A9A),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// LINE 2 — Qty, Rate, Amount
                        Row(
                          children: [
                            /// QTY
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Qty',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: services[index]['quantity'],
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 13,
                                    ),
                                    onChanged: (_) => calculateTotal(),
                                    decoration: compactInputDecoration(
                                      hint: '0',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            /// RATE
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rate',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: services[index]['rate'],
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 13,
                                    ),
                                    onChanged: (_) => calculateTotal(),
                                    decoration: compactInputDecoration(
                                      hint: '0',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            /// AMOUNT
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Amount',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: services[index]['amount'],
                                    enabled: false,
                                    style: const TextStyle(
                                      color: _amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    decoration: compactInputDecoration(
                                      hint: '0',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            /// ADD SERVICE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: addServiceRow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _surface,
                  foregroundColor: _amber,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _border),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add Service Row',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            /// PAYMENT SECTION LABEL
            const Text(
              'PAYMENT',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            /// ADVANCE PAYMENT FIELD
            TextField(
              controller: advanceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _textPrimary),
              onChanged: (val) {
                setState(() {
                  advanceAmount = int.tryParse(val.trim()) ?? 0;
                });
              },
              decoration: inputDecoration(
                hint: 'Advance Payment (₹)',
                icon: Icons.currency_rupee_rounded,
              ),
            ),

            const SizedBox(height: 20),

            /// TOTAL CARD
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: _amberDim,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _amber.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  /// Total Amount row
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
                    Container(height: 0.5, color: _amber.withOpacity(0.2)),
                    const SizedBox(height: 12),

                    /// Advance Paid row
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
                            color: Color(0xFF81C784),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(height: 0.5, color: _amber.withOpacity(0.2)),
                    const SizedBox(height: 12),

                    /// Balance Due row
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
                            color: balanceDue <= 0
                                ? const Color(0xFF81C784)
                                : _amber,
                            fontSize: 28,
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
                        'All services combined',
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

            const SizedBox(height: 20),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: _amber.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
                    : const Text(
                  'Save Invoice',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}