import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../services/connectivity_service.dart';
import '../../services/database_service.dart';
import '../recommendation_screen.dart';

class HomeView extends StatefulWidget {
  final VoidCallback? onNavigateToMarket;
  const HomeView({super.key, this.onNavigateToMarket});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isLoadingWeather = true;
  double _temperature = 0.0;
  String _weatherComment = "Loading...";
  bool _isOffline = false;
  int _weatherCode = 0;
  List<FlSpot> _hourlySpots = [];
  String _locationName = "Nagpur"; // Default
  List<dynamic> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _initWeather();
    _loadHistory();
    connectivityService.connectionStream.listen((online) {
      if (mounted) setState(() => _isOffline = !online);
    });
  }

  void _loadHistory() {
    setState(() {
      _recentScans = databaseService.getHistory().reversed.take(3).toList();
    });
  }

  Future<void> _initWeather() async {
    await _getCurrentLocation();
    await _fetchWeather();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationName = "Nagpur (Services Off)");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _locationName = "Nagpur (Permission Denied)");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationName = "Nagpur (Location Disabled)");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      if (mounted) {
        setState(() {
          _locationName = "Current Location";
        });
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', position.latitude);
      await prefs.setDouble('lon', position.longitude);
    } catch (e) {
      if (mounted) setState(() => _locationName = "Nagpur (Default)");
    }
  }

  Future<void> _fetchWeather() async {
    final prefs = await SharedPreferences.getInstance();
    double lat = prefs.getDouble('lat') ?? 21.1458; // Nagpur Lat
    double lon = prefs.getDouble('lon') ?? 79.0882; // Nagpur Lon

    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,weathercode');
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final hourly = data['hourly'];

        // Prepare Graph Data (Next 24 hours)
        List<FlSpot> spots = [];
        List<dynamic> temps = hourly['temperature_2m'];
        for (int i = 0; i < 24; i++) {
          spots.add(FlSpot(i.toDouble(), (temps[i] as num).toDouble()));
        }

        if (mounted) {
          setState(() {
            _temperature = (current['temperature'] as num).toDouble();
            _weatherCode = current['weathercode'] as int;
            _hourlySpots = spots;
            _weatherComment = _getWeatherDescription(_weatherCode, _temperature);
            _isLoadingWeather = false;
            _isOffline = false;
          });
        }

        // Cache for next session
        prefs.setDouble('cached_temp', _temperature);
        prefs.setInt('cached_code', _weatherCode);
        prefs.setString('cached_spots', jsonEncode(spots.map((e) => {'x': e.x, 'y': e.y}).toList()));
      } else {
        _useStaticFallback(prefs);
      }
    } catch (e) {
      _useStaticFallback(prefs);
    }
  }

  void _useStaticFallback(SharedPreferences prefs) {
    if (!mounted) return;
    
    // Hardcoded Nagpur Static Data as ultimate fallback
    const double staticTemp = 28.5;
    const int staticCode = 0; // Sunny
    final List<FlSpot> staticSpots = [
      const FlSpot(0, 24), const FlSpot(4, 22), const FlSpot(8, 26), 
      const FlSpot(12, 31), const FlSpot(16, 32), const FlSpot(20, 29), const FlSpot(24, 25)
    ];

    setState(() {
      _temperature = prefs.getDouble('cached_temp') ?? staticTemp;
      _weatherCode = prefs.getInt('cached_code') ?? staticCode;
      
      String? spotsJson = prefs.getString('cached_spots');
      if (spotsJson != null) {
        List<dynamic> list = jsonDecode(spotsJson);
        _hourlySpots = list.map((e) => FlSpot((e['x'] as num).toDouble(), (e['y'] as num).toDouble())).toList();
      } else {
        _hourlySpots = staticSpots;
      }
      
      _weatherComment = "Static Mode: Good for grazing.";
      _isLoadingWeather = false;
      _isOffline = true;
    });
  }

  String _getWeatherDescription(int code, double temp) {
    if (code >= 95) return "Stormy. Keep livestock indoors.";
    if (code >= 61) return "Rainy. Ensure dry bedding for cattle.";
    if (code >= 1 && code <= 3) return "Partly cloudy. Great for grazing.";
    if (temp > 35) return "Intense heat. Provide extra water.";
    return "Clear skies. Good day for outdoor activities.";
  }

  LinearGradient _getWeatherTheme() {
    if (_isOffline) return LinearGradient(colors: [Colors.grey.shade900, Colors.blueGrey.shade800]);
    
    // WMO Codes mapping
    if (_weatherCode >= 95) { // Thunderstorm
      return const LinearGradient(
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        begin: Alignment.topLeft, end: Alignment.bottomRight
      );
    }
    if (_weatherCode >= 51 && _weatherCode <= 67) { // Rain/Drizzle
      return const LinearGradient(
        colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
        begin: Alignment.topLeft, end: Alignment.bottomRight
      );
    }
    if (_weatherCode >= 1 && _weatherCode <= 3) { // Cloudy
      return const LinearGradient(
        colors: [Color(0xFF3E5151), Color(0xFFDECBA4)],
        begin: Alignment.topLeft, end: Alignment.bottomRight
      );
    }
    // Default / Sunny (Code 0)
    return const LinearGradient(
      colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
      begin: Alignment.topLeft, end: Alignment.bottomRight
    );
  }

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
              // Offline Banner
              if (_isOffline)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: const Center(
                    child: Text('OFFLINE MODE: Using Local AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.goodMorning, style: const TextStyle(fontSize: 16, color: Colors.white60)),
                      Text(AppLocalizations.of(context)!.farmer, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(_locationName, style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, color: Colors.white),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Weather Intelligence Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: _getWeatherTheme(),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: _isLoadingWeather
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Weather Intelligence', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Icon(_isOffline ? Icons.wifi_off : Icons.gps_fixed, color: Colors.white.withOpacity(0.8), size: 18),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('${_temperature.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Celsius', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                  Text(_weatherComment, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // 24 Hour Graph
                          const Text('Next 24 Hours (°C)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _hourlySpots,
                                    isCurved: true,
                                    color: Colors.white.withOpacity(0.8),
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Rest of the sections (Insights, AI, Marketplace Link)
              Row(
                children: [
                  Expanded(child: _buildInsightCard('Cattle Count', '142', Icons.pets, Colors.orangeAccent)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInsightCard('Health Alerts', '2', Icons.warning_amber_rounded, Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('AI Cattle Advice'),
              const SizedBox(height: 16),
              _buildSimpleTile(
                Icons.smart_toy, 
                Colors.greenAccent, 
                'Nutrient Deficiency Detected', 
                'Based on recent scans, 3 cows require extra calcium supplements today.'
              ),
              const SizedBox(height: 24),

              // Recent Scans Section
              if (_recentScans.isNotEmpty) ...[
                _buildSectionTitle(AppLocalizations.of(context)!.recentScans),
                const SizedBox(height: 16),
                ..._recentScans.map((scan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecommendationScreen(data: Map<String, dynamic>.from(scan)))),
                    child: _buildSimpleTile(
                      Icons.history, 
                      Colors.blueAccent, 
                      scan['disease'] ?? 'Unknown Scan', 
                      '${AppLocalizations.of(context)!.confidence}: ${scan['confidence']}%'
                    ),
                  ),
                )),
                const SizedBox(height: 24),
              ],

              _buildSectionTitle(AppLocalizations.of(context)!.marketplace),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: widget.onNavigateToMarket,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade900, Colors.teal.shade900],
                      begin: Alignment.topLeft, end: Alignment.bottomRight
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.storefront, color: Colors.greenAccent, size: 36),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Explore Marketplace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Buy medicines & equipment', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
  }

  Widget _buildSimpleTile(IconData icon, Color color, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
