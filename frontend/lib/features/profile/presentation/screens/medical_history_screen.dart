import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aarogya/core/user_manager.dart';

class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);
    final user = UserManager();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Medical History", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: hospitalNavy),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Health Profile", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: hospitalNavy)),
            const SizedBox(height: 8),
            Text("Keep this updated for doctors to make accurate diagnoses.", style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hospitalGreen.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_edu, color: hospitalGreen),
                      const SizedBox(width: 12),
                      Text("Chronic Illnesses & Allergies", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: hospitalNavy)),
                    ],
                  ),
                  const Divider(height: 30),
                  Text(
                    user.healthHistory.isEmpty ? "No medical history recorded." : user.healthHistory,
                    style: GoogleFonts.outfit(fontSize: 14, color: hospitalNavy.withOpacity(0.8), height: 1.5),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirecting to profile editor to update history")));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hospitalGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("UPDATE HISTORY", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
