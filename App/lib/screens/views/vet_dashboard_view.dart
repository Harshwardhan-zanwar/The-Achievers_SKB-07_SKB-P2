import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VetDashboardView extends StatelessWidget {
  const VetDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E24),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildClinicalMetrics(),
              const SizedBox(height: 25),
              _buildAppointmentTitle(),
              const SizedBox(height: 15),
              _buildAppointmentList(),
              const SizedBox(height: 25),
              _buildRegionalHealthMap(),
              const SizedBox(height: 25),
              _buildRecoveryStatistics(),
              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dr. Aman Sharma',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text(
                  'On Duty • Central Clinic',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        _buildNotificationIcon(),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalMetrics() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Patients', '124', Icons.pets, Colors.tealAccent)),
        const SizedBox(width: 15),
        Expanded(child: _buildMetricCard('Success Rate', '94%', Icons.trending_up, Colors.greenAccent)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withOpacity(0.6), size: 28),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAppointmentTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Scheduled Appointments',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text('View Calendar', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
      ],
    );
  }

  Widget _buildAppointmentList() {
    return Column(
      children: [
        _buildAppointmentCard(
          'Rahul Deshmukh',
          'Gir Cow • 4 Years',
          '10:30 AM',
          'High Fever, Loss of Appetite',
          true,
        ),
        const SizedBox(height: 12),
        _buildAppointmentCard(
          'Suresh Kumar',
          'Buffalo • 2 Years',
          '01:15 PM',
          'Routine Vaccination (HS/BQ)',
          false,
        ),
        const SizedBox(height: 12),
        _buildAppointmentCard(
          'Anita Patil',
          'Jersey Cow • 6 Years',
          '04:00 PM',
          'Check-up: Post-Pregnancy',
          false,
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(String name, String detail, String time, String reason, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUrgent ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(time.split(' ')[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(time.split(' ')[1], style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.tealAccent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                  ],
                ),
              ],
            ),
          ),
          if (isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
              child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildRegionalHealthMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Disease Hotspots (Regional)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(double.infinity, 180),
                painter: RegionalMapPainter(),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.redAccent, size: 14),
                      SizedBox(width: 4),
                      Text('High Risk: Zone A', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryStatistics() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2E35),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Case Recovery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Weekly improvement in treated cattle health.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 15),
                _buildLegendItem(Colors.greenAccent, 'Recovered'),
                const SizedBox(height: 5),
                _buildLegendItem(Colors.orangeAccent, 'Critical'),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(color: Colors.greenAccent, value: 75, showTitle: false, radius: 10),
                  PieChartSectionData(color: Colors.orangeAccent, value: 15, showTitle: false, radius: 10),
                  PieChartSectionData(color: Colors.white.withOpacity(0.1), value: 10, showTitle: false, radius: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class RegionalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Base background
    canvas.drawRRect(RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(24)), paint);

    // Decorative grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Hotspots
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 30, Paint()..color = Colors.redAccent.withOpacity(0.2));
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 8, Paint()..color = Colors.redAccent);

    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 40, Paint()..color = Colors.orangeAccent.withOpacity(0.15));
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 8, Paint()..color = Colors.orangeAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
