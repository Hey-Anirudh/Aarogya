import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aarogya/core/user_manager.dart';

class ManageAddressesScreen extends StatelessWidget {
  const ManageAddressesScreen({super.key});

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
        title: Text("Manage Addresses", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: hospitalNavy),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hospitalGreen.withOpacity(0.5), width: 1.5),
                boxShadow: [BoxShadow(color: hospitalGreen.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hospitalGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_rounded, color: hospitalGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Primary Home Address", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: hospitalNavy)),
                            const Spacer(),
                            const Icon(Icons.check_circle, color: hospitalGreen, size: 18),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.address.isEmpty ? "No address recorded." : user.address,
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add new address feature coming soon!")));
              },
              icon: const Icon(Icons.add, color: hospitalNavy),
              label: Text("Add New Address", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: Colors.black.withOpacity(0.1)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
