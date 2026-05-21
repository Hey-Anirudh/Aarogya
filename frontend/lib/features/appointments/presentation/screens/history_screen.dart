import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/models/appointment.dart';
import 'package:aarogya/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);
    final data = DataManager();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "My Appointments",
          style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: hospitalGreen,
          labelColor: hospitalGreen,
          unselectedLabelColor: hospitalNavy.withOpacity(0.4),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "UPCOMING"),
            Tab(text: "PAST"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getUpcomingAppointments(),
            builder: (context, snapshot) {
              final List<Appointment> upcoming = snapshot.hasData
                  ? snapshot.data!.docs.map((doc) {
                      final mapData = doc.data() as Map<String, dynamic>;
                      return Appointment(
                        id: doc.id,
                        doctorId: mapData['doctorId'] ?? '',
                        doctorName: mapData['doctorName'] ?? '',
                        doctorSpecialization: mapData['doctorSpecialization'] ?? '',
                        clinicId: mapData['clinicId'] ?? '',
                        clinicName: mapData['clinicName'] ?? '',
                        patientName: mapData['patientName'] ?? '',
                        patientPhone: mapData['patientPhone'] ?? '',
                        symptoms: mapData['symptoms'] ?? '',
                        consultationType: mapData['consultationType'] ?? 'Physical',
                        scheduledAt: (mapData['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                        status: mapData['status'] ?? 'CONFIRMED',
                        address: mapData['address'] ?? '',
                        estimatedArrivalMinutes: mapData['estimatedArrivalMinutes'] ?? 15,
                      );
                    }).toList()
                  : [];
              return _buildAppointmentList(upcoming, isUpcoming: true, textColor: hospitalNavy, accentColor: hospitalGreen);
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getPastAppointments(),
            builder: (context, snapshot) {
              final List<Appointment> past = snapshot.hasData
                  ? snapshot.data!.docs.map((doc) {
                      final mapData = doc.data() as Map<String, dynamic>;
                      return Appointment(
                        id: doc.id,
                        doctorId: mapData['doctorId'] ?? '',
                        doctorName: mapData['doctorName'] ?? '',
                        doctorSpecialization: mapData['doctorSpecialization'] ?? '',
                        clinicId: mapData['clinicId'] ?? '',
                        clinicName: mapData['clinicName'] ?? '',
                        patientName: mapData['patientName'] ?? '',
                        patientPhone: mapData['patientPhone'] ?? '',
                        symptoms: mapData['symptoms'] ?? '',
                        consultationType: mapData['consultationType'] ?? 'Physical',
                        scheduledAt: (mapData['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                        status: mapData['status'] ?? 'COMPLETED',
                        address: mapData['address'] ?? '',
                        estimatedArrivalMinutes: mapData['estimatedArrivalMinutes'] ?? 15,
                      );
                    }).toList()
                  : [];
              return _buildAppointmentList(past, isUpcoming: false, textColor: hospitalNavy, accentColor: hospitalGreen);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(List<Appointment> appointments, {required bool isUpcoming, required Color textColor, required Color accentColor}) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isUpcoming ? "📅" : "📋", style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                isUpcoming ? "No Upcoming Appointments" : "No Past Appointments",
                style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                isUpcoming
                    ? "Your scheduled consultations will appear here once you book one."
                    : "Your completed consultations will be recorded here.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 14, height: 1.5),
              ),
              if (isUpcoming) ...[
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => context.push('/booking'),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text("Book Consultation", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final timeStr = "${appt.scheduledAt.day}/${appt.scheduledAt.month}/${appt.scheduledAt.year}, ${appt.scheduledAt.hour.toString().padLeft(2, '0')}:${appt.scheduledAt.minute.toString().padLeft(2, '0')}";

        return _buildAppointmentCard(
          appt: appt,
          isUpcoming: isUpcoming,
          date: timeStr,
          textColor: textColor,
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildAppointmentCard({
    required Appointment appt,
    required bool isUpcoming,
    required String date,
    required Color textColor,
  }) {
    const Color hospitalGreen = Color(0xFF439A86);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: hospitalGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: const Text("👨‍⚕️", style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.doctorName, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      "${appt.consultationType} • ${appt.doctorSpecialization}",
                      style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(appt.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appt.status,
                  style: GoogleFonts.outfit(color: _statusColor(appt.status), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 40, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: hospitalGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(date, style: GoogleFonts.outfit(color: textColor.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              if (isUpcoming)
                GestureDetector(
                  onTap: () => context.push('/tracking'),
                  child: Text("Track 🚛", style: GoogleFonts.outfit(color: hospitalGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                )
              else
                Text("View Report 📄", style: GoogleFonts.outfit(color: hospitalGreen, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          if (isUpcoming && appt.consultationType == "Telemedicine") ...[
            const Divider(height: 32, color: Colors.black12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_call_rounded, color: Colors.white),
                label: const Text("Join Telemedicine Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => context.push('/telemedicine/${appt.id}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "CONFIRMED": return Colors.green;
      case "IN_TRANSIT": return Colors.orange;
      case "COMPLETED": return Colors.blue;
      case "CANCELLED": return Colors.red;
      default: return Colors.grey;
    }
  }
}
