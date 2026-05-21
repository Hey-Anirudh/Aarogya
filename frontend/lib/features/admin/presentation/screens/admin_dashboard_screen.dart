import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/models/clinic.dart';
import 'package:aarogya/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _dataManager = DataManager();

  @override
  void initState() {
    super.initState();
    _dataManager.startSync();
  }

  void _updateClinicStatus(Clinic clinic, String status) {
    setState(() {
      // Modify clinic status instantly in local memory lists
      final index = _dataManager.clinics.indexWhere((c) => c.id == clinic.id);
      if (index != -1) {
        final current = _dataManager.clinics[index];
        _dataManager.clinics[index] = Clinic(
          id: current.id,
          name: current.name,
          vehicleNumber: current.vehicleNumber,
          latitude: current.latitude,
          longitude: current.longitude,
          currentLocation: current.currentLocation,
          services: current.services,
          status: status, // Update to new status
          distanceKm: current.distanceKm,
          nextStop: current.nextStop,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F2D26),
        content: Text("${clinic.name} status updated to $status!"),
      ),
    );
  }

  void _showChangeRouteDialog(Clinic clinic) {
    final routeController = TextEditingController(text: clinic.currentLocation);
    final stopController = TextEditingController(text: clinic.nextStop);
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Modify Van Route: ${clinic.vehicleNumber}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: hospitalNavy)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Update the current GPS waypoint and destination stop for this clinical van. Changes will update the patient live maps instantly.",
                style: TextStyle(color: hospitalNavy.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: routeController,
                decoration: InputDecoration(
                  labelText: "Current GPS Location",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stopController,
                decoration: InputDecoration(
                  labelText: "Next Scheduled Stop",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newLoc = routeController.text.trim();
                final newStop = stopController.text.trim();

                if (newLoc.isNotEmpty && newStop.isNotEmpty) {
                  setState(() {
                    final idx = _dataManager.clinics.indexWhere((c) => c.id == clinic.id);
                    if (idx != -1) {
                      final current = _dataManager.clinics[idx];
                      _dataManager.clinics[idx] = Clinic(
                        id: current.id,
                        name: current.name,
                        vehicleNumber: current.vehicleNumber,
                        latitude: current.latitude + 0.002, // Simulate small GPS shift
                        longitude: current.longitude - 0.001,
                        currentLocation: newLoc,
                        services: current.services,
                        status: current.status,
                        distanceKm: current.distanceKm,
                        nextStop: newStop,
                      );
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: hospitalGreen,
                      content: Text("GPS tracking route coordinates updated! Patients notified."),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: hospitalGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Deploy Route Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);
    const Color lightMint = Color(0xFFEDF7F5);
    const Color accentOrange = Color(0xFFD9A000);

    final totalVans = _dataManager.clinics.length;
    final inTransitVans = _dataManager.clinics.where((c) => c.status == "IN_TRANSIT").length;
    final activeConsultations = _dataManager.appointments.length;
    final completedConsultations = _dataManager.totalConsultations;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: hospitalNavy),
          onPressed: () => context.go('/login'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("⚙️ ADMIN", style: TextStyle(color: accentOrange, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
            const SizedBox(width: 8),
            Text(
              "Control Center Dashboard",
              style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: hospitalGreen),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Row 1: Fleet & Checkup Summary Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard("Total Fleet Vans", "$totalVans Units", "🚚 Active on Roads", hospitalNavy, Colors.white, width: 150),
              _buildStatCard("Clinical Operations", "$inTransitVans Vans", "⚠️ In Transit", hospitalGreen, Colors.white, width: 150),
              _buildStatCard("Consultations Handled", "$activeConsultations Total", "⏱️ Real-time Booked", accentOrange, Colors.white, width: 150),
              _buildStatCard("Checkups Completed", "$completedConsultations Cases", "✅ Rx Sent", const Color(0xFF8B5CF6), Colors.white, width: 150),
            ],
          ),

          const SizedBox(height: 40),

          // Seeding Banner
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2D26), Color(0xFF1B4D41)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("⚡", style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Empty Firestore Database Detected?",
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Instantly seed your connected Firebase Cloud Firestore with premium live health vans and specialist doctors in one tap.",
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _dataManager.seedDatabase();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF439A86),
                              content: Text("✅ Cloud Firestore database seeded with real clinics and doctors!"),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text("Error seeding database: $e"),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF0F2D26), size: 18),
                    label: const Text("Seed Firestore", style: TextStyle(color: Color(0xFF0F2D26), fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Row 2: Pending Patient Dispatches (LIVE from Firestore)
          Text(
            "Emergency & Scheduled Dispatches",
            style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Live patient requests from Firestore. Assign a resource tier to each.",
            style: TextStyle(color: hospitalNavy.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 16),
          
          Builder(
            builder: (context) {
              final docs = _dataManager.appointments.where((a) => a.status == 'CONFIRMED').toList();
              // Sort locally by creation time
              docs.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Column(
                      children: [
                        const Text("✅", style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text("No pending dispatches.", style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("New patient requests will appear here in real-time.", style: TextStyle(color: hospitalNavy.withOpacity(0.3), fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final appt = docs[index];
                  final patientName = appt.patientName;
                  final symptoms = appt.symptoms;
                  final type = appt.consultationType;
                  final doctorNotes = appt.doctorNotes;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: type == 'Physical' ? accentOrange.withOpacity(0.5) : hospitalGreen.withOpacity(0.5), width: 1.5),
                      boxShadow: [BoxShadow(color: accentOrange.withOpacity(0.08), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: (type == 'Physical' ? accentOrange : hospitalGreen).withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(type == 'Physical' ? Icons.local_hospital : Icons.videocam, color: type == 'Physical' ? accentOrange : hospitalGreen),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Patient: $patientName", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("Symptoms: $symptoms", style: TextStyle(color: hospitalNavy.withOpacity(0.6), fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (type == 'Physical' ? accentOrange : hospitalGreen).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(type.toUpperCase(), style: TextStyle(color: type == 'Physical' ? accentOrange : hospitalGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                setState(() {
                                  final idx = _dataManager.appointments.indexWhere((a) => a.id == appt.id);
                                  if (idx != -1) {
                                    if (value == "Video Call Only") {
                                      _dataManager.appointments[idx].status = 'COMPLETED';
                                    } else {
                                      _dataManager.appointments[idx].status = 'IN_TRANSIT';
                                    }
                                    _dataManager.appointments[idx].dispatchTier = value;
                                  }
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("$value assigned to $patientName!")),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: "Video Call Only", child: Text("Tier 0: Video Call Only (₹0)")),
                                const PopupMenuItem(value: "Bike Delivery", child: Text("Tier 1: Bike Delivery (Meds)")),
                                const PopupMenuItem(value: "Bike Worker", child: Text("Tier 2: Health Worker (Labs)")),
                                const PopupMenuItem(value: "Full Medivan", child: Text("Tier 3: Full Medivan")),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: hospitalNavy,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text("ASSIGN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (doctorNotes.isNotEmpty) ...[
                          const Divider(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A84FF).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.medical_information, color: Color(0xFF0A84FF), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Doctor's Suggestion", style: GoogleFonts.outfit(color: const Color(0xFF0A84FF), fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text(doctorNotes, style: TextStyle(color: hospitalNavy.withOpacity(0.7), fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
                },
              );
            },
          ),

          const SizedBox(height: 32),

          // Row 3: Van Fleet & Waypoint Administration Section
          Text(
            "Mobile Fleet GPS Tracker & Route Manager",
            style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Monitor live health vans, deploy instant route modifications, and toggle status. Changes propagate to patient search live map instantly.",
            style: TextStyle(color: hospitalNavy.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Fleet Cards Grid
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dataManager.clinics.length,
            itemBuilder: (context, index) {
              final clinic = _dataManager.clinics[index];
              Color statusColor = hospitalGreen;
              if (clinic.status == "IN_TRANSIT") {
                statusColor = accentOrange;
              } else if (clinic.status == "OFFLINE") {
                statusColor = Colors.grey;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon/Logo
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: lightMint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: Text("🚐", style: TextStyle(fontSize: 28))),
                        ),
                        const SizedBox(width: 16),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      clinic.name,
                                      style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      clinic.status,
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(color: hospitalNavy.withOpacity(0.6), fontSize: 12),
                                  children: [
                                    const TextSpan(text: "Current: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: clinic.currentLocation),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(color: hospitalNavy.withOpacity(0.6), fontSize: 12),
                                  children: [
                                    const TextSpan(text: "Next Stop: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: clinic.nextStop, style: const TextStyle(color: hospitalGreen, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Actions (now on a separate line to prevent horizontal overflow)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        // Update route
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_road_rounded, size: 16, color: Colors.white),
                          label: const Text("Alter Route", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _showChangeRouteDialog(clinic),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hospitalNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          ),
                        ),

                        // Toggle Status Menu
                        PopupMenuButton<String>(
                          onSelected: (val) => _updateClinicStatus(clinic, val),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: "ACTIVE", child: Text("Set ACTIVE")),
                            const PopupMenuItem(value: "IN_TRANSIT", child: Text("Set IN_TRANSIT")),
                            const PopupMenuItem(value: "OFFLINE", child: Text("Set OFFLINE")),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  clinic.status == "ACTIVE" ? "Active" : "Moving",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hospitalNavy),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: hospitalNavy),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
            },
          ),

          const SizedBox(height: 40),

          // Row 3: Activity Log Database Monitor
          Text(
            "Global Database Activity Log",
            style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Live tracking of every single action performed by Doctors and Patients in the SQLite Database.",
            style: TextStyle(color: hospitalNavy.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          if (_dataManager.activityLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.04))),
              child: const Center(child: Text("No database activity found.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dataManager.activityLogs.length,
              itemBuilder: (context, index) {
                final log = _dataManager.activityLogs[index];
                final date = DateTime.tryParse(log['createdAt'] ?? '')?.toLocal();
                final timeStr = date != null ? "${date.hour}:${date.minute.toString().padLeft(2, '0')}" : "--:--";

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: log['role'] == 'DOCTOR' ? hospitalNavy.withOpacity(0.1) : hospitalGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log['role'] ?? 'SYSTEM',
                          style: TextStyle(
                            color: log['role'] == 'DOCTOR' ? hospitalNavy : hospitalGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['action'] ?? 'UNKNOWN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(log['details'] ?? '', style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(timeStr, style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, String subtitle, Color bgColor, Color textColor, {double width = 150}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: bgColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(color: textColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
