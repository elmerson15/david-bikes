import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'vehicle_details_screen.dart';

class SearchVehicleScreen extends StatefulWidget {
  const SearchVehicleScreen({super.key});

  @override
  State<SearchVehicleScreen> createState() => _SearchVehicleScreenState();
}

class _SearchVehicleScreenState extends State<SearchVehicleScreen> {
  final searchController = TextEditingController();
  String searchText = '';

  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2E2E2E);
  static const _amber = Color(0xFFF7A824);
  static const _amberDim = Color(0xFF1A1208);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textMuted = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search',
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// SEARCH BAR
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase().trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by vehicle, name or phone...',
                  hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _amber, size: 22),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: _textMuted, size: 18),
                    onPressed: () {
                      searchController.clear();
                      setState(() => searchText = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// RESULTS
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('vehicles')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _amber),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _emptyState(
                      icon: Icons.directions_bike_rounded,
                      title: 'No Vehicles Found',
                      subtitle: 'No vehicles have been added yet',
                    );
                  }

                  final vehicles = snapshot.data!.docs;

                  final filtered = vehicles.where((vehicle) {
                    final name =
                    vehicle['customerName'].toString().toLowerCase();
                    final number =
                    vehicle['vehicleNumber'].toString().toLowerCase();
                    final phone = vehicle['phone'].toString().toLowerCase();
                    return name.contains(searchText) ||
                        number.contains(searchText) ||
                        phone.contains(searchText);
                  }).toList();

                  if (filtered.isEmpty) {
                    return _emptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No Results Found',
                      subtitle: 'Try a different name, number or phone',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// RESULT COUNT
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          '${filtered.length} vehicle${filtered.length == 1 ? '' : 's'} found',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final vehicle = filtered[index];
                            return _VehicleCard(vehicle: vehicle);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            child: Icon(icon, color: _textMuted, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: _textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final QueryDocumentSnapshot vehicle;

  const _VehicleCard({required this.vehicle});

  static const _surface = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2E2E2E);
  static const _amber = Color(0xFFF7A824);
  static const _amberDim = Color(0xFF1A1208);
  static const _textMuted = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleDetailsScreen(
                  vehicleId: vehicle.id,
                  customerName: vehicle['customerName'],
                  phone: vehicle['phone'],
                  vehicleNumber: vehicle['vehicleNumber'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.03),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                /// ICON
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _amberDim,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _amber.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.motorcycle,
                    color: _amber,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                /// INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['vehicleNumber'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              vehicle['customerName'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            vehicle['phone'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ARROW
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _amberDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _amber.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: _amber,
                    size: 18,
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