import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/market_data_service.dart';

class MarketplaceView extends StatefulWidget {
  const MarketplaceView({super.key});

  @override
  State<MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<MarketplaceView> {
  String _selectedCategory = 'Medicines';
  final List<String> _categories = ['Medicines', 'Livestock', 'Equipment'];
  List<MarketItem> _allItems = [];
  List<MarketItem> _visibleItems = [];
  int _loadedCount = 8;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);
    
    try {
      // Add a tiny delay to ensure rootBundle is stable during restarts
      await Future.delayed(const Duration(milliseconds: 300));
      final items = await MarketDataService.loadItems(_selectedCategory);
      
      if (mounted) {
        setState(() {
          _allItems = items;
          _loadedCount = 8;
          _visibleItems = _allItems.take(_loadedCount).toList();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print("Marketplace Data Error: $e");
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _loadMore() {
    setState(() {
      _loadedCount += 8;
      _visibleItems = _allItems.take(_loadedCount).toList();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F1E24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Marketplace',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Offline High-Quality Farm Supplies',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Category Selector
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () async {
                      setState(() => _selectedCategory = category);
                      await _loadCategoryData();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.greenAccent.shade700 : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white.withOpacity(0.1)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Items Grid
            Expanded(
              child: _isLoadingData
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.greenAccent),
                          SizedBox(height: 16),
                          Text('Checking Inventory...', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    )
                  : _visibleItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 60),
                              const SizedBox(height: 16),
                              const Text('No Items Found', style: TextStyle(color: Colors.white54, fontSize: 16)),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadCategoryData,
                                child: const Text('Tap to Refresh', style: TextStyle(color: Colors.greenAccent)),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _visibleItems.length,
                                itemBuilder: (context, index) {
                                  return _buildMarketCard(_visibleItems[index]);
                                },
                              ),
                              if (_visibleItems.length < _allItems.length)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 30),
                                  child: Center(
                                    child: TextButton.icon(
                                      onPressed: _loadMore,
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                                      label: const Text('LOAD MORE', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                        side: BorderSide(color: Colors.greenAccent.withOpacity(0.3)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketCard(MarketItem item) {
    // Correct folder mapping to match the actual filesystem
    String subFolder;
    switch (_selectedCategory) {
      case 'Medicines':
        subFolder = 'medicines';
        break;
      case 'Livestock':
        subFolder = 'livestock';
        break;
      case 'Equipment':
        subFolder = 'equipment';
        break;
      default:
        subFolder = _selectedCategory.toLowerCase();
    }
    
    // Path now correctly includes the 'marketplace' root subfolder
    final String assetPath = "assets/images/marketplace/$subFolder/${item.imageName}";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white.withOpacity(0.05),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined, color: Colors.white12, size: 30),
                      SizedBox(height: 4),
                      Text('Offline Bundle', style: TextStyle(color: Colors.white10, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Processing offline purchase request...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
