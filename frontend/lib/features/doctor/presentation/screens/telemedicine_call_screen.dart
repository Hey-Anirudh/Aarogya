import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class TelemedicineCallScreen extends StatefulWidget {
  final String appointmentId;
  const TelemedicineCallScreen({super.key, required this.appointmentId});

  @override
  State<TelemedicineCallScreen> createState() => _TelemedicineCallScreenState();
}

class _TelemedicineCallScreenState extends State<TelemedicineCallScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;
  bool _isMuted = false;
  bool _isVideoOff = false;
  String? _errorMessage;

  // Call timer
  Timer? _callTimer;
  int _callSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startCallTimer();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callSeconds++);
      }
    });
  }

  String get _formattedTime {
    final minutes = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _initializeCamera() async {
    // Request camera and microphone permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted) {
      setState(() => _errorMessage = "Camera permission is required for video calls.");
      return;
    }
    if (!micStatus.isGranted) {
      // Mic denied is non-fatal, just warn
      debugPrint("⚠️ Microphone permission denied");
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMessage = "No cameras found on this device.");
        return;
      }

      // Start with front camera
      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      await _setupCamera(frontCamera);
    } catch (e) {
      setState(() => _errorMessage = "Failed to initialize camera: $e");
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    // Dispose old controller if switching cameras
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      setState(() => _errorMessage = "Camera error: $e");
    }
  }

  void _toggleCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isCameraInitialized = false;
    });

    final newCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _cameras.first,
    );

    await _setupCamera(newCamera);
  }

  void _toggleVideo() {
    setState(() => _isVideoOff = !_isVideoOff);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
  }

  void _endCall() {
    _cameraController?.dispose();
    _cameraController = null;
    _callTimer?.cancel();
    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── MAIN CAMERA FEED (full screen) ──
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 80),
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF439A86),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Retry", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          else if (!_isCameraInitialized)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF439A86)),
                  SizedBox(height: 24),
                  Text("Initializing camera...", style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          else if (_isVideoOff)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text("Camera Off", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            // Real camera preview — fills the entire screen
            Positioned.fill(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 1,
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),

          // ── PIP (Picture-in-Picture) — simulated remote participant ──
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              width: 110,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2D26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_rounded, color: Colors.white24, size: 40),
                      const SizedBox(height: 6),
                      Text(
                        "Waiting...",
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── TOP BAR OVERLAY — timer + flip camera ──
          Positioned(
            top: 50,
            left: 20,
            right: 140,
            child: Row(
              children: [
                // Timer chip
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.black.withOpacity(0.4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(_formattedTime, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Flip camera button
                if (_cameras.length > 1)
                  GestureDetector(
                    onTap: _toggleCamera,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.black.withOpacity(0.4),
                          child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── BOTTOM CONTROL BAR ──
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: _isMuted ? Colors.redAccent : Colors.white24,
                  onTap: _toggleMute,
                ),
                const SizedBox(width: 24),
                _buildControlButton(
                  icon: Icons.call_end_rounded,
                  color: Colors.redAccent,
                  iconColor: Colors.white,
                  size: 64,
                  onTap: _endCall,
                ),
                const SizedBox(width: 24),
                _buildControlButton(
                  icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                  color: _isVideoOff ? Colors.redAccent : Colors.white24,
                  onTap: _toggleVideo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color iconColor = Colors.white,
    double size = 56,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}
