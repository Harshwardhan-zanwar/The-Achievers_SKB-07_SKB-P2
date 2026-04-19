import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/database_service.dart';
import '../../services/diagnosis_service.dart';
import '../../providers/language_provider.dart';

enum ScanMode { vision, voice, fusion }

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  CameraController? _cameraController;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = "";
  ScanMode _currentMode = ScanMode.fusion;
  bool _isProcessing = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await [Permission.camera, Permission.microphone].request();
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();
    }
    await _speech.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) => setState(() {
          _text = val.recognizedWords;
        }));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _handleScan() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      XFile? imageFile;
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
          throw "Camera not initialized.";
        }
        imageFile = await _cameraController!.takePicture();
        if (imageFile == null) throw "Failed to capture image.";
      }

      // 1. Check Connectivity
      bool isOnline = await connectivityService.checkConnection();
      Map<String, dynamic> data;

      if (!isOnline) {
        // --- OFFLINE MODE ---
        if (imageFile == null) throw "No image or text for offline mode.";
        final bytes = await imageFile.readAsBytes();
        data = await diagnosisService.performDiagnosis(
          imageBytes: bytes,
          voiceQuery: _text.isNotEmpty ? _text : null,
        );
      } else {
        // --- ONLINE MODE ---
        final uri = Uri.parse('http://localhost:8000/api/v1/predict');
        var request = http.MultipartRequest('POST', uri);
        
        final language = Provider.of<LanguageProvider>(context, listen: false).languageName;
        request.fields['language'] = language;

        if (imageFile != null) {
          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: imageFile.name.isEmpty ? 'scan.jpg' : imageFile.name,
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
          }
        }

        if (_text.isNotEmpty) {
          request.fields['query'] = _text;
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          data = json.decode(response.body);
        } else {
          throw "Backend error ${response.statusCode}: ${response.body}";
        }
      }

      // 4. Common post-processing
      // Save result to local history
      await databaseService.addToHistory(data);
      
      if (!isOnline) {
        // Queue for sync when back online
        await databaseService.addToSyncQueue(data);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationScreen(data: data),
          ),
        );
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E24),
      body: Stack(
        children: [
          // 1. Camera Viewfinder (Only for Vision/Fusion)
          if (_currentMode != ScanMode.voice)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.mic, color: Colors.blueAccent, size: 100),
              ),
            ),

          // 2. Overlay & Guidelines
          _buildOverlay(),

          // 3. UI Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Mode Selector
                _buildModeSelector(),
                const SizedBox(height: 20),
                
                // Voice Input Display
                if (_text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: Text(_text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                const SizedBox(height: 16),

                // Primary Action Button
                _buildActionButtons(),
              ],
            ),
          ),

          // Processing State
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 20),
                    Text("AI Processing Symptoms...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54, width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(width: 40, height: 2, color: Colors.blueAccent.withOpacity(0.5)),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(width: 2, height: 40, color: Colors.blueAccent.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(AppLocalizations.of(context)!.scanner, ScanMode.vision),
          _modeButton("Fusion", ScanMode.fusion),
          _modeButton("Voice", ScanMode.voice),
        ],
      ),
    );
  }

  Widget _modeButton(String label, ScanMode mode) {
    bool active = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mic Button (for Voice context)
        if (_currentMode != ScanMode.vision)
          FloatingActionButton(
            heroTag: "mic",
            onPressed: _listen,
            backgroundColor: _isListening ? Colors.red : Colors.white10,
            child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
          ),

        // Main Capture/Send Button
        GestureDetector(
          onTap: _handleScan,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                child: const Icon(Icons.bolt, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),

        // Gallery/History Button (Placeholder)
        FloatingActionButton(
          heroTag: "gallery",
          onPressed: () {},
          backgroundColor: Colors.white10,
          child: const Icon(Icons.photo_library, color: Colors.white),
        ),
      ],
    );
  }
}
