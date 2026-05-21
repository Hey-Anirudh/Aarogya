import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/models/appointment.dart';

class IncomingCallOverlay extends StatefulWidget {
  final Appointment appointment;
  const IncomingCallOverlay({super.key, required this.appointment});

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay> {
  @override
  Widget build(BuildContext context) {
    const Color hospitalGreen = Color(0xFF439A86);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glassmorphic backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),
          
          // Floating Call Card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF143029).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Incoming Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                           .fadeOut(duration: 800.ms, curve: Curves.easeInOut)
                           .then()
                           .fadeIn(duration: 800.ms),
                          const SizedBox(width: 8),
                          Text(
                            "INCOMING VIDEO CALL",
                            style: GoogleFonts.outfit(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Doctor Avatar with Pulsing Halo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Halo
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hospitalGreen.withOpacity(0.08),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                         .scaleXY(begin: 0.9, end: 1.25, duration: 1500.ms, curve: Curves.easeOut)
                         .fadeOut(duration: 1500.ms),

                        // Inner Halo
                        Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hospitalGreen.withOpacity(0.15),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                         .scaleXY(begin: 0.95, end: 1.15, duration: 1200.ms, curve: Curves.easeOut)
                         .fadeOut(duration: 1200.ms),

                        // Avatar Circle
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: hospitalGreen, width: 2),
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Text(
                              "👨‍⚕️",
                              style: TextStyle(fontSize: 44),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Doctor Name
                    Text(
                      widget.appointment.doctorName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Doctor Specialization
                    Text(
                      widget.appointment.doctorSpecialization,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Decline Button
                        _buildCallButton(
                          icon: Icons.call_end_rounded,
                          color: Colors.redAccent,
                          onPressed: () async {
                            // Cancel/reset the calling status on the backend
                            await DataManager().resetCallingAppointment(widget.appointment.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        const SizedBox(width: 48),
                        // Accept Button
                        _buildCallButton(
                          icon: Icons.videocam_rounded,
                          color: hospitalGreen,
                          onPressed: () async {
                            // Update call state to indicate it's accepted or active
                            await DataManager().acceptCallingAppointment(widget.appointment.id);
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              // Push to telemedicine screen
                              context.push('/telemedicine/${widget.appointment.id}');
                            }
                          },
                        ).animate(onPlay: (controller) => controller.repeat())
                         .shimmer(delay: 1500.ms, duration: 1500.ms),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
