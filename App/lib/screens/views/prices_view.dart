import 'package:flutter/material.dart';
import 'dart:ui';

class PricesView extends StatelessWidget {
  const PricesView({super.key});

  final List<Map<String, dynamic>> _dairyProducts = const [
    {
      'name': 'Fresh Cow Milk',
      'price': '₹55/L',
      'trend': 'up',
      'change': '+₹2',
      'image': 'https://images.unsplash.com/photo-1550583724-125581f778d3?q=80&w=400',
    },
    {
      'name': 'Buffalo Milk',
      'price': '₹75/L',
      'trend': 'up',
      'change': '+₹5',
      'image': 'https://images.unsplash.com/photo-1563636619-e910ef4a958b?q=80&w=400',
    },
    {
      'name': 'Desi Ghee',
      'price': '₹650/kg',
      'trend': 'down',
      'change': '-₹10',
      'image': 'https://plus.unsplash.com/premium_photo-1695230432321-4f1659938b8d?q=80&w=400',
    },
    {
      'name': 'Fresh Paneer',
      'price': '₹350/kg',
      'trend': 'stable',
      'change': '0',
      'image': 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?q=80&w=400',
    },
    {
      'name': 'Curd (Dahi)',
      'price': '₹90/kg',
      'trend': 'up',
      'change': '+₹3',
      'image': 'https://images.unsplash.com/photo-1485962391945-424240a5a3bc?q=80&w=400',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F1E24),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Dairy Price Intelligence',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Real-time market rates & AI analysis',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // AI Suggestion Card
              _buildAISuggestionCard(),
              const SizedBox(height: 30),

              // Product Grid Title
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Market Prices', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Updated 2h ago', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),

              // Product Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _dairyProducts.length,
                itemBuilder: (context, index) {
                  final product = _dairyProducts[index];
                  return _buildPriceCard(product);
                },
              ),
              const SizedBox(height: 30),

              // Market Trends Card (Simplified)
              _buildTrendAnalysis(),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAISuggestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900.withOpacity(0.8), Colors.indigo.shade900.withOpacity(0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 12),
              const Text('AI Selling Strategy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: const Text('ADVICE', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Best Selling Time: Next 48 Hours',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Market trends indicate a 5-7% hike in Buffalo Milk demand by Wednesday. Hold your stock for 2 more days to maximize profit.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Full Market Report'),
          )
        ],
      ),
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> product) {
    bool isUp = product['trend'] == 'up';
    bool isDown = product['trend'] == 'down';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                product['image'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(product['price'], style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    _buildTrendBadge(product['trend'], product['change']),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrendBadge(String trend, String change) {
    Color color = Colors.grey;
    IconData icon = Icons.remove;
    
    if (trend == 'up') {
      color = Colors.greenAccent;
      icon = Icons.trending_up;
    } else if (trend == 'down') {
      color = Colors.redAccent;
      icon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(change, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Sentiment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildSentimentRow('Demand', 0.85, Colors.greenAccent),
          const SizedBox(height: 12),
          _buildSentimentRow('Supply', 0.45, Colors.orangeAccent),
          const SizedBox(height: 12),
          _buildSentimentRow('Sustainability', 0.70, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildSentimentRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
