import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'views/home_view.dart';
import 'views/marketplace_view.dart';
import 'views/scanner_view.dart';
import 'views/prices_view.dart';
import 'views/more_view.dart';
import 'views/vet_dashboard_view.dart';

class MainShellScreen extends StatefulWidget {
  final String userRole;
  const MainShellScreen({super.key, this.userRole = 'Farmer'});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        widget.userRole == 'Veterinarian' 
            ? const VetDashboardView()
            : HomeView(onNavigateToMarket: () => setState(() => _currentIndex = 1)),
        const MarketplaceView(),
        const ScannerView(),
        const PricesView(),
        const MoreView(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30.0), // Optical adjustment
        child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _currentIndex = 2; // Show the scanner view
              });
            },
            backgroundColor: Colors.greenAccent.shade700,
            elevation: 8,
            shape: const CircleBorder(),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0F1E24), // Match dark theme
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, AppLocalizations.of(context)!.home, 0),
              _buildNavItem(Icons.storefront_outlined, AppLocalizations.of(context)!.marketplace, 1),
              const SizedBox(width: 48), // Space for FloatingActionButton
              _buildNavItem(Icons.currency_rupee_outlined, AppLocalizations.of(context)!.prices, 3),
              _buildNavItem(Icons.widgets_outlined, AppLocalizations.of(context)!.more, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.greenAccent : Colors.white54,
            size: isSelected ? 26 : 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.greenAccent : Colors.white54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }
}
