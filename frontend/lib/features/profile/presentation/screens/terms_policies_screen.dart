import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPoliciesScreen extends StatelessWidget {
  const TermsPoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Terms & Policies", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: hospitalNavy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Legal Information", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: hospitalNavy)),
            const SizedBox(height: 16),
            Text(
              "By using the Aarogyam Mobile Clinic application, you agree to our Terms of Service and Privacy Policy. All medical data is stored securely in compliance with the latest health data regulations.",
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection("1. Data Privacy", "We collect health history and location data strictly to provide mobile clinical services and SOS emergency response. Your data is encrypted and never sold to third parties.", hospitalNavy),
            _buildSection("2. Emergency Services (SOS)", "The SOS feature is for critical medical emergencies. False alarms may result in account suspension.", hospitalNavy),
            _buildSection("3. Consultations", "Telemedicine consultations are supplementary and do not replace physical diagnosis in critical conditions. Our mobile clinics provide physical care when requested.", hospitalNavy),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text(content, style: GoogleFonts.outfit(fontSize: 14, color: textColor.withOpacity(0.7), height: 1.5)),
        ],
      ),
    );
  }
}
