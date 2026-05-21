import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/user_manager.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/models/appointment.dart';
import 'package:aarogya/core/models/doctor.dart';
import 'package:aarogya/core/models/clinic.dart';
import 'package:aarogya/core/models/report.dart';
import 'package:aarogya/core/services/firestore_service.dart';
import 'package:aarogya/core/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  String _consultationType = 'Physical';
  Doctor? _selectedDoctor;
  Clinic? _selectedClinic;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isBooking = false;
  bool _isUploading = false;
  String? _uploadedFileName;
  String? _uploadedFileUrl;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _confirmBooking() async {
    final user = UserManager();
    final data = DataManager();

    if (_symptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please describe your symptoms", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    final scheduledDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final apptId = 'appt_${DateTime.now().millisecondsSinceEpoch}';
    final appt = Appointment(
      id: apptId,
      doctorId: _selectedDoctor?.id ?? "unassigned",
      doctorName: _selectedDoctor?.name ?? "To Be Assigned",
      doctorSpecialization: _selectedDoctor?.specialization ?? "General",
      clinicId: _selectedClinic?.id ?? _selectedDoctor?.clinicId ?? "unassigned",
      clinicName: _selectedClinic?.name ?? "Nearest Available Clinic",
      patientName: user.name.isNotEmpty ? user.name : "Patient",
      patientPhone: user.phoneNumber.isNotEmpty ? user.phoneNumber : "Unspecified",
      symptoms: _symptomsController.text.trim(),
      consultationType: _consultationType,
      scheduledAt: scheduledDateTime,
      status: "CONFIRMED",
      address: user.address.isNotEmpty ? user.address : "Rural Crossing",
      estimatedArrivalMinutes: 15 + Random().nextInt(15),
    );

    try {
      await data.createAppointment(appt);
      
      setState(() {
        _isBooking = false;
      });

      if (mounted) {
        context.push('/appointment-confirmation');
      }
    } catch (e) {
      setState(() {
        _isBooking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to book appointment: $e", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
        iconTheme: const IconThemeData(color: hospitalNavy),
        title: Text(
          "Book Appointment",
          style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SYMPTOMS ──
            _buildSectionHeader("Describe Symptoms", hospitalNavy),
            const SizedBox(height: 12),
            _buildTextField("Tell us how you are feeling...", hospitalNavy, maxLines: 5, controller: _symptomsController),

            const SizedBox(height: 30),

            // ── SELECT DOCTOR ──
            _buildSectionHeader("Select Doctor", hospitalNavy),
            const SizedBox(height: 12),
            _buildDoctorSelector(data, hospitalNavy, hospitalGreen),

            const SizedBox(height: 30),

            // ── SELECT DATE & TIME ──
            _buildSectionHeader("Schedule", hospitalNavy),
            const SizedBox(height: 12),
            _buildDateTimeSelector(hospitalNavy, hospitalGreen),

            const SizedBox(height: 30),

            // ── UPLOAD REPORTS ──
            _buildSectionHeader("Upload Previous Reports", hospitalNavy),
            const SizedBox(height: 12),
            _buildUploadSection(hospitalNavy, hospitalGreen),

            const SizedBox(height: 30),

            // ── CONSULTATION TYPE ──
            _buildSectionHeader("Consultation Type", hospitalNavy),
            const SizedBox(height: 12),
            _buildConsultationTypeSelector(hospitalNavy, hospitalGreen),

            const SizedBox(height: 60),

            // ── CONFIRM ──
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hospitalGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: hospitalGreen.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: hospitalGreen.withOpacity(0.3),
                ),
                child: _isBooking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        "CONFIRM BOOKING",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor));
  }

  Widget _buildTextField(String hint, Color textColor, {int maxLines = 1, TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.outfit(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ── DYNAMIC DOCTOR SELECTOR ──
  Widget _buildDoctorSelector(DataManager data, Color textColor, Color focusColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getDoctorsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: focusColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: focusColor.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                const Text("👨‍⚕️", style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                Text(
                  "No Doctors Registered Yet",
                  style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "A doctor will be automatically assigned from the nearest available mobile clinic.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docSnapshot = docs[index];
              final mapData = docSnapshot.data() as Map<String, dynamic>;
              final doc = Doctor(
                id: docSnapshot.id,
                name: mapData['name'] ?? '',
                specialization: mapData['specialization'] ?? '',
                clinicId: mapData['clinicId'] ?? '',
                isAvailable: mapData['isAvailable'] ?? true,
                rating: (mapData['rating'] as num?)?.toDouble() ?? 4.5,
                experienceYears: mapData['experienceYears'] ?? 5,
                phone: mapData['phone'] ?? '+919999999999',
              );

              final isSelected = _selectedDoctor?.id == doc.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDoctor = doc;
                  _selectedClinic = data.getClinic(doc.clinicId);
                }),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? focusColor.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? focusColor : Colors.black.withOpacity(0.06), width: isSelected ? 2 : 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Text("👨‍⚕️", style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(doc.name, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(doc.specialization, style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
                      Text("⭐ ${doc.rating} • ${doc.experienceYears}yr exp", style: GoogleFonts.outfit(color: focusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── DATE & TIME PICKER ──
  Widget _buildDateTimeSelector(Color textColor, Color focusColor) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: focusColor, size: 18),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date", style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: focusColor, size: 18),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Time", style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        _selectedTime.format(context),
                        style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection(Color textColor, Color focusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: focusColor.withOpacity(0.24), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          const Text("📄", style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text("Tap to upload PDF or Images", style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text("CHOOSE FILES", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: focusColor.withOpacity(0.12), foregroundColor: focusColor, elevation: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTypeSelector(Color textColor, Color focusColor) {
    return Row(
      children: [
        _buildTypeCard("Physical", "🏠", "Doctor visits you", textColor, focusColor),
        const SizedBox(width: 16),
        _buildTypeCard("Telemedicine", "💻", "Video Consultation", textColor, focusColor),
      ],
    );
  }

  Widget _buildTypeCard(String type, String emoji, String subtitle, Color textColor, Color focusColor) {
    bool isSelected = _consultationType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _consultationType = type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? focusColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? focusColor : Colors.black.withOpacity(0.08), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              Text(type, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
