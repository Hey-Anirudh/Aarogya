import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/user_manager.dart';
import 'package:aarogya/core/data_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Profile",
          style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileHeader(hospitalNavy, context),
            const SizedBox(height: 30),
            _buildStats(hospitalNavy),
            const SizedBox(height: 40),
            _buildMenuSection("ACCOUNT", hospitalNavy, [
              _buildMenuItem(Icons.person_outline, "Edit Profile", "Change your name, age, and details", hospitalNavy, onTap: () {
                context.push('/profile-setup');
              }),
              _buildMenuItem(Icons.history, "Medical History", "Manage chronic illnesses & allergies", hospitalNavy, onTap: () {
                context.push('/medical-history');
              }),
              _buildMenuItem(Icons.location_on_outlined, "Manage Addresses", "Edit high-precision home address", hospitalNavy, onTap: () {
                context.push('/manage-addresses');
              }),
            ]),
            const SizedBox(height: 30),
            _buildMenuSection("SUPPORT", hospitalNavy, [
              _buildMenuItem(Icons.help_outline, "Help & Support", "Get in touch with us", hospitalNavy, onTap: () {
                context.push('/help-support');
              }),
              _buildMenuItem(Icons.description_outlined, "Terms & Policies", "Legal information", hospitalNavy, onTap: () {
                context.push('/terms-policies');
              }),
            ]),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Color textColor, BuildContext context) {
    const Color hospitalGreen = Color(0xFF439A86);
    final user = UserManager();

    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile-setup'),
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: hospitalGreen, width: 2),
                  color: Colors.black.withOpacity(0.04),
                ),
                child: const Center(child: Text("👤", style: TextStyle(fontSize: 40))),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: hospitalGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName,
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          user.displayPhone,
          style: GoogleFonts.outfit(color: textColor.withOpacity(0.55), fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildStats(Color textColor) {
    final user = UserManager();
    final data = DataManager();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem("${data.totalConsultations}", "Consultations", textColor),
        Container(width: 1, height: 40, color: Colors.black.withOpacity(0.08)),
        _buildStatItem(user.displayGender, "Gender", textColor),
        Container(width: 1, height: 40, color: Colors.black.withOpacity(0.08)),
        _buildStatItem(user.displayAge, "Years Old", textColor),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color textColor) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF439A86))),
        Text(label, style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMenuSection(String title, Color textColor, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color textColor, {VoidCallback? onTap}) {
    const Color hospitalGreen = Color(0xFF439A86);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Icon(icon, color: hospitalGreen, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 14),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: Text("LOGOUT", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.24)),
          ),
        ),
      ),
    );
  }
}
