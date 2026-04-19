import 'package:audioplayers/audioplayers.dart';
import '../l10n/app_localizations.dart';

class RecommendationScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const RecommendationScreen({super.key, required this.data});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    // 10.0.2.2 is Android Emulator localhost, using localhost for Windows
    final fullUrl = "http://localhost:8000$url";
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(fullUrl));
      setState(() => _isPlaying = true);
    }
    
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.data;
    final String disease = data['disease'] ?? 'Unknown Condition';
    final double risk = (data['risk_percent'] ?? 0.0).toDouble();
    final int urgency = data['urgency_days'] ?? 3;
    final String firstAid = data['first_aid'] ?? 'Consult a vet immediately.';
    final List actionPlan = data['action_plan'] ?? [];
    final List vets = data['nearby_vets'] ?? [];
    final Map? marketplace = data['marketplace'];
    final List meds = marketplace != null ? marketplace['recommended_products'] : [];
    final String? audioUrl = data['audio_url'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E24),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Diagnostic Summary Header
            _buildResultHeader(disease, risk, urgency),
            const SizedBox(height: 20),

            // 2. Audio Explanation Button (Local Language)
            if (audioUrl != null)
              _buildAudioExplanationCard(audioUrl, data['audio_summary_hi'] ?? ""),
            
            const SizedBox(height: 24),

            // 3. Clinical Indicators
            Row(
              children: [
                _buildStatCard(AppLocalizations.of(context)!.confidence, '${data['confidence']}%', Icons.verified_user, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Input Mode', data['input_mode'] ?? 'Fusion', Icons.psychology, Colors.purple),
              ],
            ),
            const SizedBox(height: 30),

            // 4. Medicine & Treatment List
            const Text('Recommended Medicines', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMedicineCard(meds),
            const SizedBox(height: 30),

            // 5. Treatment Steps
            Text(AppLocalizations.of(context)!.firstAid, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoCard(firstAid, Icons.medical_services, Colors.redAccent),
            const SizedBox(height: 12),
            ...actionPlan.map((step) => _buildStepRow(step.toString())),
            const SizedBox(height: 30),

            // 6. Nearby Veterinarians
            const Text('Nearby Vet Clinics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...vets.map((vet) => _buildVetCard(vet)),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioExplanationCard(String url, String translation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _playAudio(url),
            iconSize: 40,
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Audio Summary (Hindi)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(translation, style: const TextStyle(color: Colors.white60, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(List meds) {
    if (meds.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: meds.map((m) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.medication, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 12),
              Text(m.toString(), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildResultHeader(String disease, double risk, int urgency) {
    Color riskColor = risk > 75 ? Colors.redAccent : (risk > 40 ? Colors.orangeAccent : Colors.greenAccent);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: risk / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(riskColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${risk.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('RISK', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(disease, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: riskColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  urgency == 0 ? 'STATUS: HEALTHY' : 'URGENT: TREAT IN $urgency DAYS',
                  style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildStepRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildVetCard(Map<String, dynamic> vet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.local_hospital, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vet['name'] ?? 'Clinic', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(vet['distance'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.greenAccent),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}
