import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/models/appointment.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  final DataManager data = DataManager();
  Appointment? activeAppt;
  
  late AnimationController _animController;
  late Animation<double> _driveAnimation;

  String _etaMessage = "ETA: 15 mins";
  String _statusMessage = "Assigned & En Route";
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    try {
      activeAppt = data.appointments.lastWhere(
        (a) => a.status == "CONFIRMED" || a.status == "IN_TRANSIT",
      );
    } catch (_) {
      activeAppt = data.appointments.isNotEmpty ? data.appointments.last : null;
    }

    // 20-second Real-time Simulation
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _driveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    
    _animController.addListener(() {
      final prog = _driveAnimation.value;
      if (prog > 0.95) {
        if (_etaMessage != "Arrived!") {
          setState(() {
            _etaMessage = "Arrived!";
            _statusMessage = "Medivan has reached your location.";
            _arrived = true;
          });
        }
      } else if (prog > 0.75) {
        if (_etaMessage != "ETA: 2 mins") {
          setState(() {
            _etaMessage = "ETA: 2 mins";
            _statusMessage = "Approaching your street...";
          });
        }
      } else if (prog > 0.4) {
        if (_etaMessage != "ETA: 5 mins") {
          setState(() {
            _etaMessage = "ETA: 5 mins";
            _statusMessage = "Halfway there. Please keep phone handy.";
          });
        }
      }
    });

    _animController.forward().whenComplete(() {
      _showArrivalDialog();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showArrivalDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF439A86),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 50),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                "Medivan Arrived!",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F2D26),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "The health worker is at your door. They will collect samples or connect you to the doctor now.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.black54, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    context.go('/home'); // go home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF439A86),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Okay, Understood", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Map background
          _buildSimulatedMap(),

          // Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: hospitalNavy),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      children: [
                        const Text("🚛", style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeAppt?.clinicName ?? "Aarogyam Medivan Unit",
                              style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              activeAppt != null ? _etaMessage : "No active dispatch",
                              style: GoogleFonts.outfit(color: hospitalGreen, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User marker
          Positioned(
            bottom: 300,
            right: 100,
            child: Column(
              children: [
                const Text("📍", style: TextStyle(fontSize: 40)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: Text("You", style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Animated Clinic marker
          if (activeAppt != null)
            AnimatedBuilder(
              animation: _driveAnimation,
              builder: (context, child) {
                // Interpolate X and Y visually
                final double startX = 50.0;
                final double startY = 150.0;
                final double endX = MediaQuery.of(context).size.width - 130;
                final double endY = MediaQuery.of(context).size.height - 350;
                
                final double currentX = startX + (endX - startX) * _driveAnimation.value;
                final double currentY = startY + (endY - startY) * _driveAnimation.value;

                return Positioned(
                  top: currentY,
                  left: currentX,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hospitalGreen,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: hospitalGreen.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Text(
                          activeAppt!.clinicName,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text("🚛", style: TextStyle(fontSize: 40)),
                    ],
                  ),
                );
              },
            ),

          // No active appointment overlay
          if (activeAppt == null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🚛", style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 20),
                    Text("No Active Tracking", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      "Book a consultation first, then track your assigned mobile clinic in real-time.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hospitalGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Go Home", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom info card
          if (activeAppt != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: hospitalGreen.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Text("👨‍⚕️", style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeAppt!.doctorName,
                                style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                "$_statusMessage • ${activeAppt!.consultationType}",
                                style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.call, color: hospitalGreen),
                          style: IconButton.styleFrom(backgroundColor: hospitalGreen.withOpacity(0.12)),
                        ),
                      ],
                    ),
                    const Divider(height: 30, color: Colors.black12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat("ETA", _arrived ? "0 min" : _etaMessage.replaceAll("ETA: ", ""), hospitalNavy),
                        _buildStat("Type", activeAppt!.consultationType, hospitalNavy),
                        _buildStat("Status", _arrived ? "ARRIVED" : "IN_TRANSIT", hospitalNavy),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimulatedMap() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Stack(
        children: [
          // Render a simple grid of roads
          for (int i = 0; i < 15; i++)
            Positioned(left: (i * 60).toDouble(), top: 0, bottom: 0, child: Container(width: 12, color: Colors.white, child: Row(children:[Expanded(child:Container(color:Colors.white)),Container(width:2, color:Colors.yellow.withOpacity(0.3)),Expanded(child:Container(color:Colors.white))]))),
          for (int i = 0; i < 25; i++)
            Positioned(top: (i * 60).toDouble(), left: 0, right: 0, child: Container(height: 12, color: Colors.white, child: Column(children:[Expanded(child:Container(color:Colors.white)),Container(height:2, color:Colors.yellow.withOpacity(0.3)),Expanded(child:Container(color:Colors.white))]))),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
