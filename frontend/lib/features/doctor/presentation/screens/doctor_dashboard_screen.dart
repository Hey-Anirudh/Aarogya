import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/models/appointment.dart';
import 'package:aarogya/core/models/report.dart';
import 'package:dio/dio.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _dataManager = DataManager();
  Appointment? _activeAppointment;
  bool _isConsultationActive = false;
  
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start listening to data updates so it refreshes live when appointments are booked!
    _dataManager.startSync();
    _dataManager.addListener(_onSyncUpdate);
  }

  @override
  void dispose() {
    _dataManager.removeListener(_onSyncUpdate);
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _completeConsultation() async {
    if (_activeAppointment == null) return;

    final appt = _activeAppointment!;
    final diag = _diagnosisController.text.trim();
    final medicines = _prescriptionController.text.trim();

    if (diag.isEmpty || medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out both diagnosis and prescribed medicines.")),
      );
      return;
    }

    // 1. Submit prescription and log activity to Node backend
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://192.168.1.48:5000/api/',
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ));
      await dio.post('prescriptions', data: {
        'appointmentId': appt.id,
        'patientId': appt.patientId,
        'doctorName': appt.doctorName,
        'diagnosis': diag,
        'medicines': medicines,
        'notes': _notesController.text.trim(),
      });
    } catch (e) {
      print("⚠️ Error saving prescription to DB: $e");
    }

    // 2. Update UI locally
    setState(() {
      appt.status = "COMPLETED";
      _activeAppointment = null;
      _isConsultationActive = false;
    });

    // 3. Clear inputs
    _diagnosisController.clear();
    _prescriptionController.clear();
    _notesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF439A86),
        content: Text("Prescription successfully issued to ${appt.patientName}!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);
    const Color lightMint = Color(0xFFEDF7F5);
    const Color accentOrange = Color(0xFFD9A000);

    // Filter down to pending appointments for this doctor (or all in demo mode)
    final pendingQueue = _dataManager.appointments
        .where((a) => a.status == "CONFIRMED" || a.status == "IN_TRANSIT")
        .toList();

    final completedList = _dataManager.appointments
        .where((a) => a.status == "COMPLETED")
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hospitalNavy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("🏥 DOCTOR", style: TextStyle(color: hospitalNavy, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Consultation Terminal",
                style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
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
      body: _activeAppointment == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Waiting Queue (${pendingQueue.length})",
                    style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                // Physical Visit Requests from local DataManager (Doctor can add notes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Builder(
                    builder: (context) {
                      final docs = _dataManager.appointments
                          .where((a) => a.consultationType == 'Physical' && (a.status == 'CONFIRMED' || a.status == 'IN_TRANSIT'))
                          .toList();
                          
                      if (docs.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "🏥 ${docs.length} PHYSICAL VISIT REQUEST${docs.length > 1 ? 'S' : ''} — Add your notes for the Admin",
                              style: TextStyle(color: accentOrange, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...docs.map((appt) {
                            final pName = appt.patientName;
                            final symptoms = appt.symptoms;
                            final existingNotes = appt.doctorNotes;
                            final notesCtrl = TextEditingController(text: existingNotes);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: accentOrange.withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: accentOrange.withOpacity(0.1),
                                        child: Text(pName.isNotEmpty ? pName[0] : 'P', style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(pName, style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold)),
                                            Text("Symptoms: $symptoms", style: TextStyle(color: hospitalNavy.withOpacity(0.5), fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                        child: const Text("PHYSICAL", style: TextStyle(color: accentOrange, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Text("Your Suggestion / Notes for Admin:", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: notesCtrl,
                                    maxLines: 2,
                                    style: GoogleFonts.outfit(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: "e.g. Send Medivan with ECG equipment...",
                                      hintStyle: TextStyle(color: hospitalNavy.withOpacity(0.25), fontSize: 12),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FA),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        final notes = notesCtrl.text.trim();
                                        if (notes.isEmpty) return;
                                        
                                        setState(() {
                                          final idx = _dataManager.appointments.indexWhere((a) => a.id == appt.id);
                                          if (idx != -1) {
                                            _dataManager.appointments[idx].doctorNotes = notes;
                                          }
                                        });
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Notes saved locally! Admin can now see your suggestion."), backgroundColor: Color(0xFF439A86)),
                                        );
                                      },
                                      icon: const Icon(Icons.send, size: 16, color: Colors.white),
                                      label: const Text("Save Notes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hospitalGreen,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: pendingQueue.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("☕", style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                Text(
                                  "No Pending Consultations",
                                  style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "New bookings from patients will appear here instantly.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.3), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: pendingQueue.length,
                          itemBuilder: (context, index) {
                            final appt = pendingQueue[index];
                            final isActive = _activeAppointment?.id == appt.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isActive ? hospitalGreen.withOpacity(0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive ? hospitalGreen : Colors.black.withOpacity(0.04),
                                  width: isActive ? 1.5 : 1,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: CircleAvatar(
                                  backgroundColor: hospitalNavy.withOpacity(0.08),
                                  child: Text(appt.patientName.isNotEmpty ? appt.patientName[0].toUpperCase() : "P", style: const TextStyle(color: hospitalNavy, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(
                                  appt.patientName,
                                  style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      "Reason: ${appt.consultationType}",
                                      style: TextStyle(color: hospitalNavy.withOpacity(0.6), fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Time: ${appt.timeSlot}",
                                      style: const TextStyle(color: hospitalGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: hospitalNavy),
                                onTap: () {
                                  setState(() {
                                    _activeAppointment = appt;
                                    _diagnosisController.text = "";
                                    _prescriptionController.text = "";
                                    _notesController.text = "";
                                  });
                                },
                              ),
                            ).animate().fadeIn(delay: (index * 50).ms);
                          },
                        ),
                ),
              ],
            )
          : Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Back to queue button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _activeAppointment = null),
                      icon: const Icon(Icons.arrow_back_rounded, color: hospitalNavy, size: 18),
                      label: const Text("Back to Queue", style: TextStyle(color: hospitalNavy, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Patient Summary Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: hospitalNavy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("LIVE CONSULTATION", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                            const Spacer(),
                            Text(
                              _activeAppointment!.timeSlot,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _activeAppointment!.patientName,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Mobile: ${_activeAppointment!.doctorId.isNotEmpty ? '+91 99999 12345' : 'Patient'}",
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                        const Divider(height: 24, color: Colors.white12),
                        Text(
                          "Presented Symptoms / Reason:",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activeAppointment!.consultationType,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  if (!_isConsultationActive) ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Text(
                        "Action Required",
                        style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "You must complete the consultation before writing the prescription.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_activeAppointment!.consultationType == "Telemedicine")
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 28),
                          label: Text(
                            "Start Video Consultation",
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            // Set backend status to CALLING so patient gets incoming call dialog
                            await _dataManager.startCallingAppointment(_activeAppointment!.id);
                            
                            if (context.mounted) {
                              final result = await context.push<bool>('/telemedicine/${_activeAppointment!.id}');
                              if (result == true) {
                                setState(() => _isConsultationActive = true);
                              } else {
                                // If doctor cancels or exits the call, reset status to CONFIRMED
                                await _dataManager.resetCallingAppointment(_activeAppointment!.id);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A84FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms)
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.person_search_rounded, color: Colors.white, size: 28),
                          label: Text(
                            "Start Physical Checkup",
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() => _isConsultationActive = true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hospitalNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                  ] else ...[
                    const SizedBox(height: 32),

                    // Form Label: Diagnosis
                    Text(
                      "Clinical Diagnosis",
                      style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _diagnosisController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter primary symptoms detected...",
                        hintStyle: TextStyle(color: hospitalNavy.withOpacity(0.3), fontSize: 14),
                        filled: true,
                        fillColor: lightMint.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: hospitalGreen, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Form Label: Prescribed Medicines
                    Text(
                      "Prescribed Medicines & Dosage",
                      style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _prescriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "List medicines, dosage, and duration...",
                        hintStyle: TextStyle(color: hospitalNavy.withOpacity(0.3), fontSize: 14),
                        filled: true,
                        fillColor: lightMint.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: hospitalGreen, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Form Label: General Advice
                    Text(
                      "General Clinical Notes / Advice",
                      style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "General advice...",
                        hintStyle: TextStyle(color: hospitalNavy.withOpacity(0.3), fontSize: 14),
                        filled: true,
                        fillColor: lightMint.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: hospitalGreen, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Action Button: Issue Digital Rx
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.verified_user_rounded, color: Colors.white),
                        label: Text(
                          "Complete & Send Digital Prescription",
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _completeConsultation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
