import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aarogya/core/models/clinic.dart';
import 'package:aarogya/core/models/doctor.dart';
import 'package:aarogya/core/models/appointment.dart';
import 'package:aarogya/core/models/notification_item.dart';
import 'package:aarogya/core/models/report.dart';
import 'package:aarogya/core/services/auth_service.dart';
import 'package:aarogya/core/services/local_storage_service.dart';
import 'package:aarogya/routes/app_router.dart';
import 'package:aarogya/features/doctor/presentation/screens/incoming_call_overlay.dart';

/// Central production data manager — single source of truth.
/// Synced automatically with Cloud Firestore.
class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  String? activeRingingCallId;
  BuildContext? _ringingDialogContext;

  final List<VoidCallback> _listeners = [];
  
  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
  
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in List<VoidCallback>.from(_listeners)) {
      try {
        listener();
      } catch (_) {}
    }
  }

  // ──────────────────────────────────────────────
  // LIVE DATA STORES (automatically synced)
  // ──────────────────────────────────────────────
  final List<Clinic> clinics = [];
  final List<Doctor> doctors = [];
  final List<Appointment> appointments = [];
  final List<NotificationItem> notifications = [];
  final List<MedicalReport> reports = [];
  final List<Map<String, dynamic>> activityLogs = [];

  bool _isListening = false;
  bool _isSyncing = false;
  Timer? _syncTimer;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.48:5000/api/',
    connectTimeout: const Duration(seconds: 2),
    receiveTimeout: const Duration(seconds: 2),
  ));

  /// Start listening to Firestore real-time streams and syncing state.
  /// Call this upon successful login/initialization.
  void startSync() {
    if (_isListening) return;
    _isListening = true;

    _loadMockClinics();
    _loadMockDoctors();
    _loadLocalAppointments();
    _loadMockPastAppointments();
    _loadMockReports();

    print("🚀 Starting real-time sync with Node.js Backend API...");

    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isSyncing) return;
      _isSyncing = true;
      try {
        final res = await _dio.get('sync');
        final data = res.data;

        clinics.clear();
        for (var c in data['clinics'] ?? []) {
          clinics.add(Clinic(
            id: c['id'],
            name: c['name'],
            vehicleNumber: c['vehicleNumber'],
            latitude: (c['latitude'] as num?)?.toDouble() ?? 28.6139,
            longitude: (c['longitude'] as num?)?.toDouble() ?? 77.2090,
            currentLocation: c['currentLocation'] ?? c['address'],
            services: (c['services'] as String).split(', '),
            status: c['status'],
            distanceKm: 2.5,
            nextStop: c['nextStop'] ?? 'Main Crossing',
          ));
        }

        doctors.clear();
        for (var d in data['doctors'] ?? []) {
          doctors.add(Doctor(
            id: d['id'],
            name: d['name'] ?? '',
            specialization: d['specialization'] ?? '',
            clinicId: d['clinicId'] ?? '',
            isAvailable: d['isAvailable'] ?? true,
            rating: 4.8,
            experienceYears: 10,
            phone: '+919999999991',
          ));
        }

        // Sync appointments from backend
        final List<Appointment> newAppointments = [];
        for (var a in data['appointments'] ?? []) {
          newAppointments.add(Appointment(
            id: a['id'],
            doctorId: a['doctorId'] ?? '',
            doctorName: a['doctorName'] ?? '',
            doctorSpecialization: a['doctorSpecialization'] ?? '',
            clinicId: a['clinicId'] ?? '',
            clinicName: a['clinicName'] ?? '',
            patientName: a['patientName'] ?? '',
            patientPhone: a['patientPhone'] ?? '',
            symptoms: a['symptoms'] ?? '',
            consultationType: a['consultationType'] ?? 'Physical',
            scheduledAt: DateTime.tryParse(a['scheduledAt'] ?? '') ?? DateTime.now(),
            status: a['status'] ?? 'CONFIRMED',
            address: a['address'] ?? '',
            estimatedArrivalMinutes: a['estimatedArrivalMinutes'] ?? 15,
          ));
        }

        appointments.clear();
        appointments.addAll(newAppointments);

        // Check if any appointment is currently in CALLING status
        bool foundActiveCall = false;
        Appointment? callingAppt;
        for (var appt in newAppointments) {
          if (appt.status == 'CALLING') {
            foundActiveCall = true;
            callingAppt = appt;
            break;
          }
        }

        if (foundActiveCall && callingAppt != null) {
          if (activeRingingCallId != callingAppt.id) {
            _triggerIncomingCallOverlay(callingAppt);
          }
        } else {
          // If no active calls are present but we are still ringing, dismiss the overlay
          _dismissIncomingCallOverlay();
        }

        // Notify listeners so UI updates instantly when data syncs
        _notifyListeners();

      } catch (e) {
        // print("⚠️ API Sync Error: $e");
      } finally {
        _isSyncing = false;
      }
    });
  }

  void _triggerIncomingCallOverlay(Appointment appt) {
    activeRingingCallId = appt.id;
    
    Future.microtask(() {
      final context = rootNavigatorKey.currentContext;
      if (context == null) return;

      // Close previous ringing dialog if any is open
      _dismissIncomingCallOverlay();

      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Incoming Call',
        barrierColor: Colors.black.withOpacity(0.6),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (dialogContext, animation1, animation2) {
          _ringingDialogContext = dialogContext;
          return IncomingCallOverlay(appointment: appt);
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          );
        },
      ).then((_) {
        // Reset local status once overlay is closed
        if (_ringingDialogContext == null) {
          activeRingingCallId = null;
        }
      });
    });
  }

  void _dismissIncomingCallOverlay() {
    if (_ringingDialogContext != null) {
      try {
        Navigator.of(_ringingDialogContext!).pop();
      } catch (_) {}
      _ringingDialogContext = null;
    }
    activeRingingCallId = null;
  }

  void _saveLocalAppointments() {
    final list = appointments.map((a) => a.toJson()).toList();
    LocalStorageService().cacheData('local_appointments', list);
  }

  void _loadLocalAppointments() {
    final list = LocalStorageService().getCachedData('local_appointments', maxAgeMinutes: 999999);
    if (list != null && list is List) {
      appointments.clear();
      for (var json in list) {
        try {
          appointments.add(Appointment.fromJson(Map<String, dynamic>.from(json)));
        } catch (_) {}
      }
    }
  }

  void _syncAppointments(List<DocumentSnapshot> docs, {required bool isUpcomingBatch}) {
    // Remove old ones of this type and replace with updated ones
    appointments.removeWhere((a) => isUpcomingBatch ? (a.status == "CONFIRMED" || a.status == "IN_TRANSIT") : (a.status == "COMPLETED" || a.status == "CANCELLED"));

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      appointments.add(Appointment(
        id: doc.id,
        doctorId: data['doctorId'] ?? '',
        doctorName: data['doctorName'] ?? '',
        doctorSpecialization: data['doctorSpecialization'] ?? '',
        clinicId: data['clinicId'] ?? '',
        clinicName: data['clinicName'] ?? '',
        patientName: data['patientName'] ?? '',
        patientPhone: data['patientPhone'] ?? '',
        symptoms: data['symptoms'] ?? '',
        consultationType: data['consultationType'] ?? 'Physical',
        scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] ?? 'CONFIRMED',
        address: data['address'] ?? '',
        estimatedArrivalMinutes: data['estimatedArrivalMinutes'] ?? 15,
      ));
    }
    print("📡 Synced ${appointments.length} total appointments.");
  }

  // Seed methods removed as they are handled by the backend API.

  // ──────────────────────────────────────────────
  // CLINIC OPERATIONS
  // ──────────────────────────────────────────────
  Clinic? getClinic(String id) {
    try { return clinics.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }
  List<Clinic> get activeClinics => clinics;

  // ──────────────────────────────────────────────
  // DOCTOR OPERATIONS
  // ──────────────────────────────────────────────
  Doctor? getDoctor(String id) {
    try { return doctors.firstWhere((d) => d.id == id); }
    catch (_) { return null; }
  }
  List<Doctor> get availableDoctors => doctors;
  List<Doctor> doctorsForClinic(String clinicId) => doctors.where((d) => d.clinicId == clinicId).toList();

  // ──────────────────────────────────────────────
  // APPOINTMENT OPERATIONS
  // ──────────────────────────────────────────────
  Future<String> createAppointment(Appointment appt) async {
    if (!appointments.any((a) => a.id == appt.id)) appointments.add(appt);
    _saveLocalAppointments();

    // Save to Firestore for live cross-role sync
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appt.id).set({
        'id': appt.id,
        'doctorId': appt.doctorId,
        'doctorName': appt.doctorName,
        'doctorSpecialization': appt.doctorSpecialization,
        'clinicId': appt.clinicId,
        'clinicName': appt.clinicName,
        'patientId': 'uuid-patient-demo',
        'patientName': appt.patientName,
        'patientPhone': appt.patientPhone,
        'symptoms': appt.symptoms,
        'consultationType': appt.consultationType,
        'scheduledAt': appt.scheduledAt.toIso8601String(),
        'status': appt.status,
        'address': appt.address,
        'estimatedArrivalMinutes': appt.estimatedArrivalMinutes,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("✅ Appointment saved to Firestore for live Admin/Doctor sync!");
    } catch (e) {
      print("⚠️ Firestore save error: $e");
    }

    // Also try Node.js backend
    try {
      await _dio.post('appointments', data: {
        'id': appt.id,
        'doctorId': appt.doctorId,
        'doctorName': appt.doctorName,
        'doctorSpecialization': appt.doctorSpecialization,
        'clinicId': appt.clinicId,
        'clinicName': appt.clinicName,
        'patientId': 'uuid-patient-demo',
        'patientName': appt.patientName,
        'patientPhone': appt.patientPhone,
        'symptoms': appt.symptoms,
        'consultationType': appt.consultationType,
        'scheduledAt': appt.scheduledAt.toIso8601String(),
        'status': appt.status,
        'address': appt.address,
      });
    } catch (e) {
      print("⚠️ API POST Error: $e");
    }
    return appt.id;
  }

  Future<void> cancelAppointment(String id) async {
    final idx = appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      appointments[idx].status = "CANCELLED";
      _saveLocalAppointments();
    }
    try {
      await _dio.put('appointments/$id', data: {'status': 'CANCELLED'});
    } catch (e) {
      print("⚠️ API PUT Error: $e");
    }
  }

  Future<void> completeAppointment(String id) async {
    final idx = appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      appointments[idx].status = "COMPLETED";
      _saveLocalAppointments();
    }
    try {
      await _dio.put('appointments/$id', data: {'status': 'COMPLETED'});
    } catch (e) {
      print("⚠️ API PUT Error: $e");
    }
  }

  Future<void> startCallingAppointment(String id) async {
    final idx = appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      appointments[idx].status = "CALLING";
      _saveLocalAppointments();
    }
    try {
      await _dio.put('appointments/$id', data: {'status': 'CALLING'});
    } catch (e) {
      print("⚠️ API PUT Error starting call: $e");
    }
  }

  Future<void> resetCallingAppointment(String id) async {
    final idx = appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      appointments[idx].status = "CONFIRMED";
      _saveLocalAppointments();
    }
    try {
      await _dio.put('appointments/$id', data: {'status': 'CONFIRMED'});
    } catch (e) {
      print("⚠️ API PUT Error resetting call: $e");
    }
  }

  Future<void> acceptCallingAppointment(String id) async {
    final idx = appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      appointments[idx].status = "IN_CALL";
      _saveLocalAppointments();
    }
    try {
      await _dio.put('appointments/$id', data: {'status': 'IN_CALL'});
    } catch (e) {
      print("⚠️ API PUT Error accepting call: $e");
    }
  }

  Appointment? getAppointment(String id) {
    try { return appointments.firstWhere((a) => a.id == id); }
    catch (_) { return null; }
  }

  List<Appointment> get upcomingAppointments => appointments.where((a) => a.isUpcoming).toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<Appointment> get pastAppointments => appointments.where((a) => a.isPast).toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  // ──────────────────────────────────────────────
  // NOTIFICATION OPERATIONS
  // ──────────────────────────────────────────────
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> markAllRead() async {
    for (var n in notifications) {
      n.isRead = true;
    }
  }

  Future<void> markRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) notifications[idx].isRead = true;
  }

  // ──────────────────────────────────────────────
  // REPORT OPERATIONS
  // ──────────────────────────────────────────────
  Future<void> addReport(MedicalReport report) async {
    if (!reports.any((r) => r.id == report.id)) {
      reports.add(report);
    }
    try {
      await _dio.post('reports', data: {
        'title': report.title,
        'category': report.category,
        'date': report.date,
        'fileSize': report.fileSize,
        'fileUrl': report.fileUrl,
        'fileType': report.fileType,
      });
    } catch (e) {
      print("⚠️ API POST Error: $e");
    }
  }

  List<MedicalReport> searchReports(String query) {
    if (query.isEmpty) return reports;
    final q = query.toLowerCase();
    return reports.where((r) => r.title.toLowerCase().contains(q) || r.category.toLowerCase().contains(q)).toList();
  }

  // ──────────────────────────────────────────────
  // STATS
  // ──────────────────────────────────────────────
  int get totalConsultations => appointments.where((a) => a.status == "COMPLETED").length;
  int get totalReports => reports.length;

  Future<void> fetchActivityLogs() async {
    try {
      final response = await _dio.get('activity');
      activityLogs.clear();
      if (response.data is List) {
        for (var item in response.data) {
          activityLogs.add(item as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print("⚠️ API GET Error fetching activity logs: $e");
    }
  }

  void _loadMockClinics() {
    if (clinics.isNotEmpty) return;
    clinics.addAll([
      Clinic(
        id: 'clinic_1',
        name: 'Primary Care Unit A',
        vehicleNumber: 'DL-01-A-1234',
        latitude: 28.6139,
        longitude: 77.2090,
        currentLocation: 'Noida Sector 62 Main Crossing, UP',
        services: ['General Checkup', 'Pediatrics', 'Vaccinations'],
        status: 'ACTIVE',
        distanceKm: 2.4,
        nextStop: 'Main Crossing',
      ),
      Clinic(
        id: 'clinic_2',
        name: 'Maternal & Child Health Express',
        vehicleNumber: 'DL-02-B-5678',
        latitude: 28.5800,
        longitude: 77.3100,
        currentLocation: 'Sector 15 Community Center, Noida',
        services: ['Gynaecology', 'Pediatrics', 'Ultrasound'],
        status: 'IN_TRANSIT',
        distanceKm: 4.8,
        nextStop: 'Community Center',
      ),
    ]);
  }

  void _loadMockDoctors() {
    if (doctors.isNotEmpty) return;
    doctors.addAll([
      Doctor(
        id: 'doc_1',
        name: 'Dr. Aarav Sharma',
        specialization: 'General Physician',
        clinicId: 'clinic_1',
        isAvailable: true,
        rating: 4.9,
        experienceYears: 12,
        phone: '+919999999991',
      ),
      Doctor(
        id: 'doc_2',
        name: 'Dr. Priya Patel',
        specialization: 'Paediatrician',
        clinicId: 'clinic_1',
        isAvailable: true,
        rating: 4.8,
        experienceYears: 8,
        phone: '+919999999992',
      ),
      Doctor(
        id: 'doc_3',
        name: 'Dr. Ananya Rao',
        specialization: 'Gynaecologist',
        clinicId: 'clinic_2',
        isAvailable: true,
        rating: 4.9,
        experienceYears: 14,
        phone: '+919999999993',
      ),
    ]);
  }

  void _loadMockPastAppointments() {
    if (appointments.any((a) => a.isPast)) return;
    appointments.addAll([
      Appointment(
        id: 'mock_past_1',
        doctorId: 'doc_1',
        doctorName: 'Dr. Aarav Sharma',
        doctorSpecialization: 'General Physician',
        clinicId: 'clinic_1',
        clinicName: 'Primary Care Unit A',
        patientName: 'Demo Patient',
        patientPhone: '+911111111111',
        symptoms: 'Mild Fever, Cough',
        consultationType: 'Physical',
        scheduledAt: DateTime.now().subtract(const Duration(days: 5)),
        status: 'COMPLETED',
        address: 'Noida',
        estimatedArrivalMinutes: 0,
      ),
      Appointment(
        id: 'mock_past_2',
        doctorId: 'doc_2',
        doctorName: 'Dr. Priya Patel',
        doctorSpecialization: 'Paediatrician',
        clinicId: 'clinic_1',
        clinicName: 'Primary Care Unit A',
        patientName: 'Demo Patient',
        patientPhone: '+911111111111',
        symptoms: 'Routine Checkup',
        consultationType: 'Telemedicine',
        scheduledAt: DateTime.now().subtract(const Duration(days: 12)),
        status: 'COMPLETED',
        address: 'Noida',
        estimatedArrivalMinutes: 0,
      )
    ]);
  }

  void _loadMockReports() {
    if (reports.isNotEmpty) return;
    reports.addAll([
      MedicalReport(
        id: 'rep_1',
        title: 'Complete Blood Count (CBC)',
        category: 'Lab Test',
        date: '10 Oct 2026',
        fileSize: '1.2 MB',
        fileUrl: '',
        fileType: 'PDF',
      ),
      MedicalReport(
        id: 'rep_2',
        title: 'Chest X-Ray',
        category: 'Imaging',
        date: '05 Sep 2026',
        fileSize: '4.5 MB',
        fileUrl: '',
        fileType: 'JPG',
      ),
    ]);
  }

  Future<void> seedDatabase() async {
    try {
      await _dio.post('seed');
    } catch (e) {
      print("⚠️ API POST Error: $e");
    }
  }
}
