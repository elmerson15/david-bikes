import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddInvoiceScreen extends StatefulWidget {
  final String vehicleId;
  final String? invoiceId;
  final Map<String, dynamic>? existingData;

  const AddInvoiceScreen({
    super.key,
    required this.vehicleId,
    this.invoiceId,
    this.existingData,
  });

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final kmController            = TextEditingController();
  final nextOilChangeController = TextEditingController();
  final advanceController       = TextEditingController();

  // Each row has its own controllers for service/qty/rate/amount
  List<Map<String, TextEditingController>> services = [];

  bool isLoading     = false;
  int  totalAmount   = 0;
  int  advanceAmount = 0;

  // ── Firestore refs ───────────────────────────────────────────────────────
  // Services are stored as a top-level collection: services/{docId} = { name: "OIL CHANGE" }
  final CollectionReference _servicesCol =
  FirebaseFirestore.instance.collection('services');

  List<String> allServices = [];

  bool get isEditing => widget.invoiceId != null;

  static const _bg          = Color(0xFF0F0F0F);
  static const _surface     = Color(0xFF141414);
  static const _border      = Color(0xFF2E2E2E);
  static const _amber       = Color(0xFFF7A824);
  static const _amberDim    = Color(0xFF1A1208);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textMuted   = Color(0xFF888888);

  // ── lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadServices().then((_) {
      // Rebuild rows AFTER services are loaded so Autocomplete has data
      if (mounted) setState(() {});
    });

    if (isEditing && widget.existingData != null) {
      _prefill(widget.existingData!);
    } else {
      _addServiceRow();
    }
  }

  /// Loads the service name list from Firestore once.
  Future<void> _loadServices() async {
    final snap = await _servicesCol.get();
    allServices = snap.docs
        .map((d) => (d['name'] as String? ?? '').toUpperCase())
        .where((s) => s.isNotEmpty)
        .toSet() // deduplicate
        .toList()
      ..sort();
  }

  void _prefill(Map<String, dynamic> data) {
    kmController.text            = data['kmTravelled']   ?? '';
    nextOilChangeController.text = data['nextOilChange'] ?? '';
    advanceAmount                = (data['advanceAmount'] as num?)?.toInt() ?? 0;
    advanceController.text       = advanceAmount > 0 ? '$advanceAmount' : '';

    final items = data['items'] as List? ?? [];
    for (final item in items) {
      services.add({
        'service':  TextEditingController(text: (item['service'] ?? '').toString()),
        'quantity': TextEditingController(text: '${item['quantity'] ?? 1}'),
        'rate':     TextEditingController(text: '${item['rate']   ?? 0}'),
        'amount':   TextEditingController(text: '${item['amount'] ?? 0}'),
      });
    }
    if (services.isEmpty) _addServiceRow();
    _calculateTotal();
  }

  @override
  void dispose() {
    kmController.dispose();
    nextOilChangeController.dispose();
    advanceController.dispose();
    for (final row in services) {
      row.forEach((_, c) => c.dispose());
    }
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _addServiceRow() {
    services.add({
      'service':  TextEditingController(),
      'quantity': TextEditingController(text: '1'),
      'rate':     TextEditingController(),
      'amount':   TextEditingController(),
    });
    setState(() {});
  }

  void _calculateTotal() {
    int total = 0;
    for (final row in services) {
      final qty    = int.tryParse(row['quantity']!.text.trim()) ?? 0;
      final rate   = int.tryParse(row['rate']!.text.trim())     ?? 0;
      final amount = qty * rate;
      row['amount']!.value = TextEditingValue(
        text:      '$amount',
        selection: TextSelection.collapsed(offset: '$amount'.length),
      );
      total += amount;
    }
    setState(() => totalAmount = total);
  }

  void _deleteRow(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
        title: const Text('Delete Row',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: const Text('Delete this service row?',
            style: TextStyle(color: _textMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () {
              services[index].forEach((_, c) => c.dispose());
              services.removeAt(index);
              _calculateTotal();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Color(0xFFEF9A9A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (kmController.text.trim().isEmpty) {
      _showSnack('Please enter KM Travelled', error: true);
      return;
    }

    try {
      setState(() => isLoading = true);

      // Build items list & persist any new service names to Firestore
      final List<Map<String, dynamic>> invoiceItems = [];
      for (final row in services) {
        final name = row['service']!.text.trim().toUpperCase();
        invoiceItems.add({
          'service':  name,
          'quantity': int.tryParse(row['quantity']!.text.trim()) ?? 0,
          'rate':     int.tryParse(row['rate']!.text.trim())     ?? 0,
          'amount':   int.tryParse(row['amount']!.text.trim())   ?? 0,
        });

        if (name.isNotEmpty && !allServices.contains(name)) {
          await _servicesCol.add({'name': name});
          allServices.add(name);
        }
      }

      final payload = {
        'kmTravelled':   kmController.text.trim(),
        'nextOilChange': nextOilChangeController.text.trim(),
        'items':         invoiceItems,
        'totalAmount':   totalAmount,
        'advanceAmount': advanceAmount,
        'balanceDue':    totalAmount - advanceAmount,
        'date':          DateTime.now().toString().substring(0, 10),
      };

      final col = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('invoices');

      if (isEditing) {
        await col.doc(widget.invoiceId).update(payload);
      } else {
        await col.add({...payload, 'createdAt': Timestamp.now()});
      }

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(isEditing ? 'Invoice updated' : 'Invoice saved');
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: error ? const Color(0xFFEF9A9A) : _border),
        ),
        content: Text(msg,
            style: TextStyle(
                color: error ? const Color(0xFFEF9A9A) : Colors.white)),
      ),
    );
  }

  // ── decorations ──────────────────────────────────────────────────────────

  InputDecoration _inputDec({required String hint, IconData? icon}) =>
      InputDecoration(
        hintText:  hint,
        hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: _amber, size: 20) : null,
        filled:    true,
        fillColor: _surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: _amber, width: 1.2),
        ),
        border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  InputDecoration _compactDec({required String hint}) => InputDecoration(
    hintText:  hint,
    hintStyle: const TextStyle(color: _textMuted, fontSize: 12),
    filled:    true,
    fillColor: const Color(0xFF1C1C1C),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:   const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:   const BorderSide(color: _amber, width: 1.2),
    ),
    border:
    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  // ── service row ──────────────────────────────────────────────────────────

  Widget _buildServiceRow(int index) {
    // We use a ValueKey so Flutter creates a fresh Autocomplete widget
    // whenever the row is added/removed, preventing stale controller issues.
    return Container(
      key: ValueKey(services[index]['service'].hashCode),
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── service name + delete ──────────────────────────────────
          Row(
            children: [
              Expanded(child: _buildAutocomplete(index)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _deleteRow(index),
                child: Container(
                  width:  38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF9A9A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFEF9A9A).withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF9A9A), size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── qty / rate / amount ────────────────────────────────────
          Row(
            children: [
              _numField(label: 'Qty',    index: index, key: 'quantity'),
              const SizedBox(width: 8),
              _numField(label: 'Rate',   index: index, key: 'rate'),
              const SizedBox(width: 8),
              _amountField(index),
            ],
          ),
        ],
      ),
    );
  }

  /// The Autocomplete widget. Key fix: don't use `initialValue` — instead
  /// drive the field through `fieldViewBuilder` with the backing controller
  /// directly. This ensures `optionsBuilder` fires on every keystroke.
  Widget _buildAutocomplete(int index) {
    final backingController = services[index]['service']!;

    return RawAutocomplete<String>(
      // ── tie RawAutocomplete to our own controller & focus node ──────
      textEditingController: backingController,
      focusNode: FocusNode(),

      optionsBuilder: (TextEditingValue tv) {
        final query = tv.text.trim();
        if (query.isEmpty) return const Iterable<String>.empty();
        return allServices.where(
              (s) => s.toUpperCase().contains(query.toUpperCase()),
        );
      },

      displayStringForOption: (o) => o,

      onSelected: (String selection) {
        backingController.text = selection;
        setState(() {});
      },

      // ── dropdown ────────────────────────────────────────────────────
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color:        const Color(0xFF1C1C1C),
          elevation:    6,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(maxHeight: 200, maxWidth: 280),
            child: ListView.builder(
              padding:     const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap:  true,
              itemCount:   options.length,
              itemBuilder: (_, i) {
                final opt = options.elementAt(i);
                return InkWell(
                  onTap:        () => onSelected(opt),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Text(opt,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                );
              },
            ),
          ),
        ),
      ),

      // ── text field ──────────────────────────────────────────────────
      fieldViewBuilder: (ctx, fieldCtrl, focusNode, onEditingComplete) {
        return TextField(
          controller:         fieldCtrl,
          focusNode:          focusNode,
          textCapitalization: TextCapitalization.characters,
          onChanged: (val) {
            final upper = val.toUpperCase();
            if (val != upper) {
              fieldCtrl.value = TextEditingValue(
                text:      upper,
                selection: TextSelection.collapsed(offset: upper.length),
              );
            }
            // backing controller is already `fieldCtrl` via RawAutocomplete
          },
          style:       const TextStyle(color: _textPrimary, fontSize: 13),
          decoration:  _compactDec(hint: 'Service name'),
        );
      },
    );
  }

  Widget _numField(
      {required String label, required int index, required String key}) {
    final isRate = key == 'rate';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller:   services[index][key],
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _textPrimary, fontSize: 13),
            onChanged:    (_) => _calculateTotal(),
            decoration:   _compactDec(hint: isRate ? '₹0' : '0'),
          ),
        ],
      ),
    );
  }

  Widget _amountField(int index) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amount',
            style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: services[index]['amount'],
          enabled:    false,
          style: const TextStyle(
              color: _amber,
              fontWeight: FontWeight.bold,
              fontSize: 13),
          decoration: _compactDec(hint: '0'),
        ),
      ],
    ),
  );

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final balance = totalAmount - advanceAmount;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation:   0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Invoice' : 'Add Invoice',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── hero card ────────────────────────────────────────────
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:        _amberDim,
                borderRadius: BorderRadius.circular(22),
                border:
                Border.all(color: _amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INVOICE',
                      style: TextStyle(
                          color:       _amber,
                          fontSize:    11,
                          fontWeight:  FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(
                    isEditing ? 'Edit Invoice' : 'Service Billing',
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   22,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEditing
                        ? 'Update this workshop invoice'
                        : 'Create a workshop invoice',
                    style: const TextStyle(
                        color: Color(0xFF9A7E4A), fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionLabel('VEHICLE DETAILS'),
            const SizedBox(height: 12),

            TextField(
              controller:   kmController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _textPrimary),
              decoration: _inputDec(
                  hint: 'KM Travelled', icon: Icons.speed_rounded),
            ),
            const SizedBox(height: 14),
            TextField(
              controller:   nextOilChangeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _textPrimary),
              decoration: _inputDec(
                  hint: 'Next Oil Change (KM)',
                  icon: Icons.oil_barrel_rounded),
            ),

            const SizedBox(height: 28),
            _sectionLabel('SERVICES'),
            const SizedBox(height: 10),

            // ── service rows ─────────────────────────────────────────
            ...List.generate(
                services.length, (i) => _buildServiceRow(i)),

            const SizedBox(height: 6),

            SizedBox(
              width:  double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _addServiceRow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _surface,
                  foregroundColor: _amber,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _border),
                  ),
                ),
                icon:  const Icon(Icons.add_rounded),
                label: const Text('Add Service Row',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 28),
            _sectionLabel('PAYMENT'),
            const SizedBox(height: 12),

            TextField(
              controller:   advanceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _textPrimary),
              onChanged: (v) =>
                  setState(() => advanceAmount = int.tryParse(v.trim()) ?? 0),
              decoration: _inputDec(
                  hint: 'Advance Payment (₹)',
                  icon: Icons.currency_rupee_rounded),
            ),

            const SizedBox(height: 20),

            // ── total card ───────────────────────────────────────────
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color:        _amberDim,
                borderRadius: BorderRadius.circular(18),
                border:
                Border.all(color: _amber.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _totalRow('TOTAL AMOUNT', '₹$totalAmount',
                      valueColor: _amber, valueSize: 20),
                  if (advanceAmount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                        height: 0.5,
                        color: _amber.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    _totalRow('ADVANCE PAID', '- ₹$advanceAmount',
                        valueColor: const Color(0xFF81C784),
                        valueSize: 16),
                    const SizedBox(height: 12),
                    Container(
                        height: 0.5,
                        color: _amber.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    _totalRow(
                      'BALANCE DUE',
                      '₹$balance',
                      labelColor: Colors.white,
                      labelSize:  12,
                      labelWeight: FontWeight.w700,
                      valueColor:
                      balance <= 0 ? const Color(0xFF81C784) : _amber,
                      valueSize: 28,
                      valueWeight: FontWeight.w800,
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('All services combined',
                          style: TextStyle(
                              color: Color(0xFF6B5A3A), fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── save button ──────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: _amber.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  width:  22,
                  height: 22,
                  child:  CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black),
                )
                    : Text(
                  isEditing ? 'Update Invoice' : 'Save Invoice',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── small builder helpers ─────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        color:         _textMuted,
        fontSize:      11,
        fontWeight:    FontWeight.w600,
        letterSpacing: 1.2),
  );

  Widget _totalRow(
      String label,
      String value, {
        Color labelColor       = const Color(0xFF9A7E4A),
        double labelSize       = 11,
        FontWeight labelWeight = FontWeight.w600,
        Color valueColor       = _amber,
        double valueSize       = 20,
        FontWeight valueWeight = FontWeight.w700,
      }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color:         labelColor,
                  fontSize:      labelSize,
                  fontWeight:    labelWeight,
                  letterSpacing: 1.0)),
          Text(value,
              style: TextStyle(
                  color:      valueColor,
                  fontSize:   valueSize,
                  fontWeight: valueWeight)),
        ],
      );
}