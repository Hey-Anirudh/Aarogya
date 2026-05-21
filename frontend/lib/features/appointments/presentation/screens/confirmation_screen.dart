import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/models/appointment.dart';

class AppointmentConfirmationScreen extends StatelessWidget {
  const AppointmentConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);
    final data = DataManager();

    // Get the most recently created appointment
    final Appointment? latestAppt = data.appointments.isNotEmpty ? data.appointments.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: ListView(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.check, color: Colors.white, size: 60)),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 30),

              Text(
                "Booking Confirmed!",
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: hospitalNavy),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 12),

              Text(
                latestAppt != null
                    ? "Your ${latestAppt.consultationType} consultation has been scheduled."
                    : "A mobile clinic has been assigned to you.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.65), fontSize: 16, fontWeight: FontWeight.w500),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 60),

              _buildDetailCard(
                "👨‍⚕️ Assigned Doctor",
                latestAppt?.doctorName ?? "To Be Assigned",
                latestAppt?.doctorSpecialization ?? "General Physician",
                hospitalNavy, hospitalGreen,
              ),
              const SizedBox(height: 20),
              _buildDetailCard(
                "🚛 Assigned Clinic",
                latestAppt?.clinicName ?? "Nearest Available",
                latestAppt?.status ?? "CONFIRMED",
                hospitalNavy, hospitalGreen,
              ),
              const SizedBox(height: 20),
              _buildDetailCard(
                "⏳ Estimated Arrival",
                latestAppt != null ? "${latestAppt.estimatedArrivalMinutes} Minutes" : "15 - 20 Minutes",
                latestAppt != null ? "Arriving at: ${latestAppt.address}" : "Arriving at your location",
                hospitalNavy, hospitalGreen,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => context.push('/tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hospitalGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: hospitalGreen.withOpacity(0.3),
                  ),
                  child: Text(
                    "LIVE TRACKING",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ).animate().fadeIn(delay: 1.seconds),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  "Back to Home",
                  style: GoogleFonts.outfit(color: hospitalGreen, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ).animate().fadeIn(delay: 1.2.seconds),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String mainText, String subText, Color textColor, Color focusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: focusColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(mainText, style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subText, style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
