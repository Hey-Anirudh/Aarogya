import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'package:aarogya/features/appointments/presentation/screens/history_screen.dart';
import 'package:aarogya/features/reports/presentation/screens/reports_screen.dart';
import 'package:aarogya/features/profile/presentation/screens/profile_screen.dart';
import 'package:aarogya/core/user_manager.dart';
import 'package:aarogya/features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import 'package:aarogya/features/admin/presentation/screens/admin_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Widget> _getPages() {
    final role = UserManager().role;
    final pages = [
      const HomeScreen(),
      const AppointmentHistoryScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];
    if (role == 'doctor') {
      pages.add(const DoctorDashboardScreen());
    } else if (role == 'admin') {
      pages.add(const AdminDashboardScreen());
    }
    return pages;
  }

  List<BottomNavigationBarItem> _getNavBarItems() {
    final role = UserManager().role;
    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
      const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: "Bookings"),
      const BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: "Reports"),
      const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
    ];
    if (role == 'doctor') {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.medical_services_rounded), label: "Doc Console"));
    } else if (role == 'admin') {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_rounded), label: "Admin Ops"));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    final navItems = _getNavBarItems();

    // Guard selectedIndex boundary in case role changes dynamically
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0A84FF), // primary Blue accent
          unselectedItemColor: Colors.black.withOpacity(0.35),
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          items: navItems,
        ),
      ),
    );
  }
}
