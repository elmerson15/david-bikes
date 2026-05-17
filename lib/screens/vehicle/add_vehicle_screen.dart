import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() =>
      _AddVehicleScreenState();
}

class _AddVehicleScreenState
    extends State<AddVehicleScreen> {

  final customerNameController =
  TextEditingController();

  final phoneController =
  TextEditingController();

  final vehicleNumberController =
  TextEditingController();

  bool isLoading = false;

  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF222222);
  static const _amber = Color(0xFFF7A824);
  static const _textPrimary = Color(0xFFE0E0E0);
  static const _textMuted = Color(0xFF666666);

  Future<void> saveVehicle() async {

    try {

      setState(() {
        isLoading = true;
      });

      String customerName =
      customerNameController.text.trim();

      String phone =
      phoneController.text.trim();

      String vehicleNumber =
      vehicleNumberController.text
          .trim()
          .toUpperCase()
          .replaceAll(" ", "");

      // VALIDATION

      if (customerName.isEmpty ||
          phone.isEmpty ||
          vehicleNumber.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please Fill All Fields",
            ),
          ),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      // CHECK DUPLICATE VEHICLE

      final existingVehicle =
      await FirebaseFirestore.instance
          .collection('vehicles')
          .where(
        'vehicleNumber',
        isEqualTo: vehicleNumber,
      )
          .get();

      if (existingVehicle.docs.isNotEmpty) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Vehicle Already Exists",
            ),
          ),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      // SAVE VEHICLE

      await FirebaseFirestore.instance
          .collection('vehicles')
          .add({

        'customerName': customerName,

        'phone': phone,

        'vehicleNumber': vehicleNumber,

        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehicle Added"),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {

    return InputDecoration(

      labelText: label,

      labelStyle: const TextStyle(
        color: _textMuted,
      ),

      prefixIcon: Icon(
        icon,
        color: _amber,
        size: 20,
      ),

      filled: true,
      fillColor: _surface,

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _amber,
          width: 1.2,
        ),
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          "Add Vehicle",
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

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color(0xFF1A1208),

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
                      "NEW ENTRY",
                      style: TextStyle(
                        color: _amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Vehicle Registration",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Add customer and bike details",
                      style: TextStyle(
                        color: Color(0xFF6B5A3A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "CUSTOMER DETAILS",
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 16),

              TextField(

                controller: customerNameController,

                style: const TextStyle(
                  color: _textPrimary,
                ),

                decoration: inputDecoration(
                  label: "Customer Name",
                  icon:
                  Icons.person_outline_rounded,
                ),
              ),

              const SizedBox(height: 18),

              TextField(

                controller: phoneController,

                keyboardType:
                TextInputType.phone,

                style: const TextStyle(
                  color: _textPrimary,
                ),

                decoration: inputDecoration(
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                ),
              ),

              const SizedBox(height: 18),

              TextField(

                controller:
                vehicleNumberController,

                textCapitalization:
                TextCapitalization.characters,

                style: const TextStyle(
                  color: _textPrimary,
                ),

                onChanged: (value) {

                  String formatted =
                  value
                      .toUpperCase()
                      .replaceAll(" ", "");

                  vehicleNumberController.value =
                      TextEditingValue(
                        text: formatted,

                        selection:
                        TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                },

                decoration: inputDecoration(
                  label: "Vehicle Number",

                  icon:
                  Icons
                      .directions_bike_outlined,
                ),
              ),

              const SizedBox(height: 34),

              SizedBox(

                width: double.infinity,
                height: 56,

                child: ElevatedButton(

                  onPressed:
                  isLoading
                      ? null
                      : saveVehicle,

                  style: ElevatedButton.styleFrom(

                    backgroundColor: _amber,

                    foregroundColor: Colors.black,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,

                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                      : const Text(
                    "Save Vehicle",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}