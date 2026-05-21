import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/services/auth_service.dart';
import 'package:aarogya/core/services/local_storage_service.dart';
import 'package:aarogya/core/user_manager.dart';
import 'package:aarogya/core/data_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  _navigateToNext() async {
    // Exact delay to sync with the van's smooth entrance and exit animations
    await Future.delayed(const Duration(milliseconds: 4000));
    if (mounted) {
      final auth = AuthService();
      if (auth.isLoggedIn) {
        // Load cached user profile into UserManager singleton
        final cache = LocalStorageService().cachedUserProfile;
        if (cache != null) {
          final user = UserManager();
          user.name = cache['name'] ?? '';
          user.age = cache['age'] ?? '';
          user.gender = cache['gender'] ?? '';
          user.address = cache['address'] ?? '';
          user.healthHistory = cache['healthHistory'] ?? '';
          user.phoneNumber = cache['phoneNumber'] ?? '';
          user.role = cache['role'] ?? 'patient';
        }

        // Start Firebase live data synchronization!
        DataManager().startSync();

        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Exact soothing clinical hospital green/teal from your photo
    const Color hospitalGreen = Color(0xFF439A86);

    return Scaffold(
      backgroundColor: hospitalGreen,
      body: Stack(
        children: [
          // Subtle clinical background design patterns (decorative grid lines)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: MedicalGridPainter(),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Medical Driving Van
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dotted/dashed road line under the van
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 160,
                        height: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(10, (index) => Container(
                            width: 10,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          )),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .scaleX(begin: 0.0, end: 1.0, duration: 600.ms),
                    ),

                    // The driving van itself (placed slightly above the road line)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: const MedicalVanWidget(
                        size: 80,
                        primaryColor: hospitalGreen,
                      ),
                    )
                    // Slide in from left
                    .animate()
                    .slideX(
                      begin: -2.5,
                      end: 0.0,
                      duration: 1400.ms,
                      curve: Curves.decelerate,
                    )
                    // Drive off-screen to the right at the end of the splash (No vibration!)
                    .then(delay: 1500.ms)
                    .slideX(
                      begin: 0.0,
                      end: 2.5,
                      duration: 900.ms,
                      curve: Curves.easeInCubic,
                    ),
                  ],
                ),

                const SizedBox(height: 55),

                // App Title (Crisp white with medical clean shadow)
                Text(
                  "AAROGYAM",
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 14,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF1E5246).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 1000.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0.0, duration: 800.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 14),

                // Slogan (High-opacity white for readability)
                Text(
                  "HEALTHCARE AT YOUR DOORSTEP",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    letterSpacing: 4,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                )
                .animate()
                .fadeIn(delay: 1500.ms, duration: 800.ms),

                const SizedBox(height: 70),

                // Premium Minimalist Loading Bar (Pure white progress track)
                Container(
                  width: 150,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 1200.ms)
                .scaleX(begin: 0.0, end: 1.0, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Premium Medical Van / Ambulance Widget
class MedicalVanWidget extends StatelessWidget {
  final double size;
  final Color primaryColor;

  const MedicalVanWidget({
    super.key,
    required this.size,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final double width = size * 1.6;
    final double height = size;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Van Body Shadow for premium depth
          Positioned(
            bottom: size * 0.1,
            left: size * 0.1,
            right: size * 0.1,
            child: Container(
              height: size * 0.15,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
          ),

          // Main Chassis
          Positioned(
            left: size * 0.05,
            bottom: size * 0.18,
            child: Container(
              width: size * 1.45,
              height: size * 0.58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.08),
                  topRight: Radius.circular(size * 0.28), // Slanted front
                  bottomLeft: Radius.circular(size * 0.05),
                  bottomRight: Radius.circular(size * 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Stack(
                children: [
                  // Decorative clinical stripes matching background color
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: size * 0.12,
                    child: Container(
                      height: size * 0.08,
                      color: primaryColor.withOpacity(0.15),
                    ),
                  ),

                  // Hospital Cross symbol matching background color
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(size * 0.04),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_circle,
                        color: primaryColor,
                        size: size * 0.32,
                      ),
                    ),
                  ),

                  // Cabin Window
                  Positioned(
                    top: size * 0.06,
                    right: size * 0.12,
                    child: Container(
                      width: size * 0.32,
                      height: size * 0.22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B), // Sleek glass border
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(size * 0.18),
                          topLeft: const Radius.circular(3),
                          bottomRight: const Radius.circular(3),
                          bottomLeft: const Radius.circular(3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(size * 0.16),
                              topLeft: const Radius.circular(2),
                              bottomRight: const Radius.circular(2),
                              bottomLeft: const Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Emergency Flashing Siren on Top
          Positioned(
            left: size * 0.5,
            top: size * 0.14,
            child: Container(
              width: size * 0.14,
              height: size * 0.09,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(size * 0.02),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .custom(
              duration: 250.ms,
              builder: (context, val, child) {
                final Color sirenColor = val < 0.5 ? Colors.redAccent : Colors.amberAccent;
                return Container(
                  width: size * 0.14,
                  height: size * 0.09,
                  decoration: BoxDecoration(
                    color: sirenColor,
                    borderRadius: BorderRadius.circular(size * 0.02),
                    boxShadow: [
                      BoxShadow(
                        color: sirenColor.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          // Left Wheel (Back)
          Positioned(
            left: size * 0.26,
            bottom: size * 0.04,
            child: const WheelWidget(size: 18),
          ),

          // Right Wheel (Front)
          Positioned(
            right: size * 0.26,
            bottom: size * 0.04,
            child: const WheelWidget(size: 18),
          ),
        ],
      ),
    );
  }
}

// Spinning Wheel Widget
class WheelWidget extends StatelessWidget {
  final double size;

  const WheelWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          children: [
            // Center Cap
            Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
            ),
            // Spokes to visualize rotation
            ...List.generate(4, (index) {
              final double angle = (index * 45) * 3.14159 / 180;
              return Transform.rotate(
                angle: angle,
                child: Container(
                  width: size,
                  height: 1.5,
                  color: Colors.white30,
                ),
              );
            }),
          ],
        ),
      ),
    )
    .animate(onPlay: (c) => c.repeat())
    .rotate(duration: 800.ms, curve: Curves.linear);
  }
}

// Custom Painter for medical-themed background grid patterns
class MedicalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    const double step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
