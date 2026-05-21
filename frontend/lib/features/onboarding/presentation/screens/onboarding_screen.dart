import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPageValue = 0.0;
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      emoji: "🏥",
      title: "Mobile Clinics",
      description: "Aarogyam brings fully equipped medical clinics directly to your neighborhood.",
    ),
    OnboardingData(
      emoji: "👨‍⚕️",
      title: "Expert Doctors",
      description: "Connect with specialized doctors via telemedicine or physical consultations.",
    ),
    OnboardingData(
      emoji: "🛰️",
      title: "Real-time Tracking",
      description: "Track the medical clinic's location in real-time as it travels to you.",
    ),
    OnboardingData(
      emoji: "🔐",
      title: "Data Privacy",
      description: "Your health records are secure, encrypted, and accessible only by you.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPageValue = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalGreen = Color(0xFF439A86);
    const Color lightMint = Color(0xFFEDF7F5); // Soothing medical soft mint green
    const Color clinicalWhite = Color(0xFFFCFDFD); // Clean clinical white

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Sleek Light Clinical)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [clinicalWhite, lightMint],
              ),
            ),
          ),

          // Ambient Medical Circle Glow in background
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hospitalGreen.withOpacity(0.08),
              ),
            ),
          ),

          // Main Header Text
          Positioned(
            top: 65,
            left: 30,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AAROGYAM",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: hospitalGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Future of Healthcare",
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F2D26), // Deep contrast clinical navy
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0.0),
          ),

          // 3D Card Stack PageView
          Center(
            child: SizedBox(
              height: 460,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  // Premium 3D deck-of-cards transition calculations
                  double difference = index - _currentPageValue;
                  double scale = (1 - (difference.abs() * 0.15)).clamp(0.8, 1.0);
                  double rotation = (difference * 0.08).clamp(-0.15, 0.15);
                  double translation = difference * 320.0; // Dynamic card slide spacing

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective depth
                      ..translate(translation, 0.0, 0.0)
                      ..scale(scale)
                      ..rotateZ(rotation),
                    child: Opacity(
                      opacity: (1 - difference.abs().clamp(0.0, 1.0)),
                      child: _buildOnboardingCard(_pages[index], hospitalGreen),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Controls (Indicators & Navigation Button)
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Clean Indicator Dots
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? hospitalGreen 
                            : Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).animate().scale(duration: 250.ms),
                  ),
                ),
                
                // Next / Get Started Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      _showPermissionsDialog(hospitalGreen);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hospitalGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 5,
                    shadowColor: hospitalGreen.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentPage == _pages.length - 1 
                            ? Icons.check_circle_outline 
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Beautiful Floating Card Widget
  Widget _buildOnboardingCard(OnboardingData data, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white, // Elevated clean white solid card
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Badge for Emoji Icon
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.06),
              border: Border.all(color: primaryColor.withOpacity(0.12), width: 2),
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 64),
              ).animate()
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 1.seconds),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Feature Title (Deep contrasting navy/teal clinical color)
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F2D26), // Contrasting medical color
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Feature Description (Readability clinical grey)
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF475569), // Slate 600
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(Color primaryColor) {
    const Color hospitalNavy = Color(0xFF0F2D26);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Elevated clean white permission dialog
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            const Text("🏥", style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              "App Permissions",
              style: GoogleFonts.outfit(
                color: hospitalNavy, 
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "To provide instant medical support at your door, Aarogyam requires the following access:",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.7), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildPermissionItem("📍", "Live Location", "Required to track and route clinical vans to you."),
            _buildPermissionItem("🔔", "Smart Alerts", "Get instant updates on clinic arrival and appointments."),
            _buildPermissionItem("📸", "HD Camera", "For remote telemedicine/consultation with specialists."),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "GRANT PERMISSIONS",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Asynchronous function to request real native system permissions
  Future<void> _requestPermissions() async {
    // Request Location, Camera, and Notifications
    await [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.notification,
    ].request();

    if (mounted) {
      context.go('/login');
    }
  }

  Widget _buildPermissionItem(String emoji, String title, String desc) {
    const Color hospitalNavy = Color(0xFF0F2D26);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: GoogleFonts.outfit(
                    color: hospitalNavy, 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  desc, 
                  style: GoogleFonts.outfit(
                    color: hospitalNavy.withOpacity(0.55), 
                    fontSize: 11,
                    height: 1.3,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String emoji;
  final String title;
  final String description;

  OnboardingData({required this.emoji, required this.title, required this.description});
}
