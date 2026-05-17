import 'package:flutter/material.dart';

import '../invoice/recent_bills_screen.dart';
import '../vehicle/add_vehicle_screen.dart';
import '../vehicle/search_vehicle_screen.dart';
import '../vehicle/vehicle_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 24),
              _buildHeroCard(),
              const SizedBox(height: 28),
              const Text(
                'QUICK ACCESS',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildGrid(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _amberDim,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _amber.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.motorcycle,
            color: _amber,
            size: 24,
          ),
        ),
        Expanded(
          child: Column(
            children: const [
              Text(
                "David's Bikes",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Bike Service Center',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 46),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _amberDim,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DASHBOARD',
                style: TextStyle(
                  color: _amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Active',
                      style: TextStyle(
                        color: _amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Welcome Back!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage vehicles, customers & billing',
            style: TextStyle(
              color: Color(0xFF9A7E4A),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 0.5,
            color: _amber.withOpacity(0.2),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _heroStat(label: 'Vehicles', icon: Icons.directions_bike_rounded),
              _heroDivider(),
              _heroStat(label: 'Invoices', icon: Icons.receipt_long_rounded),
              _heroDivider(),
              _heroStat(label: 'Search', icon: Icons.search_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({required String label, required IconData icon}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _amber, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9A7E4A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 0.5,
      height: 16,
      color: _amber.withOpacity(0.2),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final items = [
      _CardData(
        title: 'Add Vehicle',
        subtitle: 'Register new bike',
        icon: Icons.add_circle_outline_rounded,
        iconColor: const Color(0xFF5BA4F5),
        iconBg: const Color(0xFF0D2A4A),
        iconBorder: const Color(0xFF1A4A7A),
        screen: const AddVehicleScreen(),
      ),
      _CardData(
        title: 'Vehicle List',
        subtitle: 'View all bikes',
        icon: Icons.directions_bike_rounded,
        iconColor: const Color(0xFF5DD87A),
        iconBg: const Color(0xFF0A2A14),
        iconBorder: const Color(0xFF1A4A2A),
        screen: const VehicleListScreen(),
      ),
      _CardData(
        title: 'Search',
        subtitle: 'Find a vehicle',
        icon: Icons.search_rounded,
        iconColor: const Color(0xFFB39DDB),
        iconBg: const Color(0xFF1A1030),
        iconBorder: const Color(0xFF2E1F5A),
        screen: const SearchVehicleScreen(),
      ),
      _CardData(
        title: 'Recent Bills',
        subtitle: 'View invoices',
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFFEF9A9A),
        iconBg: const Color(0xFF2A0D0D),
        iconBorder: const Color(0xFF4A1A1A),
        screen: const RecentBillsScreen(),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _DashCard(
        data: items[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => items[i].screen),
        ),
      ),
    );
  }
}

class _CardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color iconBorder;
  final Widget screen;
  const _CardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.iconBorder,
    required this.screen,
  });
}

class _DashCard extends StatelessWidget {
  final _CardData data;
  final VoidCallback onTap;
  const _DashCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.04),
        highlightColor: Colors.white.withOpacity(0.02),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E2E2E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: data.iconBorder),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 26),
              ),
              const Spacer(),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: data.iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: data.iconColor,
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}