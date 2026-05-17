import 'package:flutter/material.dart';

import '../invoice/add_invoice_screen.dart';
import '../invoice/invoice_list_screen.dart';

class VehicleDetailsScreen extends StatelessWidget {

  final String vehicleId;
  final String customerName;
  final String phone;
  final String vehicleNumber;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    required this.customerName,
    required this.phone,
    required this.vehicleNumber,
  });

  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF222222);
  static const _amber = Color(0xFFF7A824);
  static const _amberDim = Color(0xFF1A1208);
  static const _textPrimary = Color(0xFFE0E0E0);
  static const _textMuted = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          "Vehicle Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: _amberDim,
                  borderRadius:
                  BorderRadius.circular(24),

                  border: Border.all(
                    color: const Color(0xFF3A2A0A),
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'CUSTOMER',
                      style: TextStyle(
                        color: _amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [

                        const Icon(
                          Icons.phone_outlined,
                          color: _amber,
                          size: 18,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          phone,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.black
                            .withOpacity(0.18),

                        borderRadius:
                        BorderRadius.circular(14),

                        border: Border.all(
                          color: _border,
                        ),
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons
                                .directions_bike_outlined,
                            color: _amber,
                            size: 18,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              vehicleNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "QUICK ACTIONS",
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 18),

              _actionButton(
                context: context,
                title: "Add Invoice",
                subtitle:
                "Create new service invoice",
                icon: Icons.receipt_long_rounded,

                onTap: () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          AddInvoiceScreen(
                            vehicleId: vehicleId,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _actionButton(
                context: context,
                title: "Invoice History",
                subtitle:
                "View previous billing records",

                icon: Icons.history_rounded,

                onTap: () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          InvoiceListScreen(

                            vehicleId: vehicleId,

                            customerName:
                            customerName,

                            phone:
                            phone,

                            vehicleNumber:
                            vehicleNumber,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(20),

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(20),

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(20),

            border: Border.all(
              color: _border,
            ),
          ),

          child: Row(
            children: [

              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color:
                  _amber.withOpacity(0.12),

                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Icon(
                  icon,
                  color: _amber,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: _textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}