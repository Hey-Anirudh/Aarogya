import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aarogya/core/services/auth_service.dart';

/// Cloud Firestore Service — all database CRUD operations
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // USER PROFILE
  // ──────────────────────────────────────────────

  /// Save or update user profile
  Future<void> saveUserProfile({
    required String name,
    required String age,
    required String gender,
    required String address,
    required String healthHistory,
    required String phoneNumber,
  }) async {
    try {
      final uid = AuthService().uid;
      if (uid == null) return;

      await _db.collection('users').doc(uid).set({
        'name': name,
        'age': age,
        'gender': gender,
        'address': address,
        'healthHistory': healthHistory,
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("⚠️ Firestore saveUserProfile caught: $e. Falling back to local storage only.");
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final uid = AuthService().uid;
      if (uid == null) return null;

      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("⚠️ Firestore getUserProfile caught: $e. Falling back to local/cached data.");
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // CLINICS
  // ──────────────────────────────────────────────

  /// Get all active clinics (real-time stream)
  Stream<QuerySnapshot> getClinicsStream() {
    return _db.collection('clinics')
        .where('status', whereIn: ['ACTIVE', 'IN_TRANSIT'])
        .snapshots();
  }

  /// Get all clinics (one-time fetch)
  Future<List<Map<String, dynamic>>> getAllClinics() async {
    final snapshot = await _db.collection('clinics').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Add a clinic (admin operation)
  Future<String> addClinic(Map<String, dynamic> clinicData) async {
    final docRef = await _db.collection('clinics').add({
      ...clinicData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ──────────────────────────────────────────────
  // DOCTORS
  // ──────────────────────────────────────────────

  /// Get all available doctors
  Stream<QuerySnapshot> getDoctorsStream() {
    return _db.collection('doctors')
        .where('isAvailable', isEqualTo: true)
        .snapshots();
  }

  /// Get all doctors (one-time)
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final snapshot = await _db.collection('doctors').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Add a doctor (admin operation)
  Future<String> addDoctor(Map<String, dynamic> doctorData) async {
    final docRef = await _db.collection('doctors').add({
      ...doctorData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ──────────────────────────────────────────────
  // APPOINTMENTS
  // ──────────────────────────────────────────────

  /// Create a new appointment
  Future<String> createAppointment(Map<String, dynamic> apptData) async {
    final uid = AuthService().uid;
    if (uid == null) throw Exception('Not authenticated');

    final docRef = await _db.collection('appointments').add({
      ...apptData,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Auto-generate notification
    await addNotification(
      title: 'Appointment Confirmed',
      description: 'Your ${apptData['consultationType']} consultation with ${apptData['doctorName']} has been booked.',
      emoji: '📅',
    );

    return docRef.id;
  }

  /// Get ALL appointments across all users (for Admin & Doctor dashboards)
  Stream<QuerySnapshot> getAllAppointmentsStream() {
    return _db.collection('appointments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get only CONFIRMED appointments (pending dispatch) for Admin
  Stream<QuerySnapshot> getPendingDispatchStream() {
    return _db.collection('appointments')
        .where('status', isEqualTo: 'CONFIRMED')
        .snapshots();
  }

  /// Get Physical appointments for Doctor review
  Stream<QuerySnapshot> getPhysicalAppointmentsStream() {
    return _db.collection('appointments')
        .where('consultationType', isEqualTo: 'Physical')
        .where('status', whereIn: ['CONFIRMED', 'IN_TRANSIT'])
        .snapshots();
  }

  /// Update appointment status (dispatch, complete, cancel)
  Future<void> updateAppointmentStatus(String docId, String newStatus) async {
    await _db.collection('appointments').doc(docId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Save doctor notes/suggestions on a physical appointment
  Future<void> saveDoctorNotes(String docId, String notes) async {
    await _db.collection('appointments').doc(docId).update({
      'doctorNotes': notes,
      'notesUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update dispatch tier chosen by admin
  Future<void> updateDispatchTier(String docId, String tier) async {
    await _db.collection('appointments').doc(docId).update({
      'dispatchTier': tier,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get upcoming appointments for current user
  Stream<QuerySnapshot> getUpcomingAppointments() {
    final uid = AuthService().uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('appointments')
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: ['CONFIRMED', 'IN_TRANSIT'])
        .orderBy('scheduledAt')
        .snapshots();
  }

  /// Get past appointments for current user
  Stream<QuerySnapshot> getPastAppointments() {
    final uid = AuthService().uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('appointments')
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: ['COMPLETED', 'CANCELLED'])
        .orderBy('scheduledAt', descending: true)
        .snapshots();
  }

  /// Cancel an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'status': 'CANCELLED',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Complete an appointment
  Future<void> completeAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'status': 'COMPLETED',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get appointment count for stats
  Future<int> getCompletedAppointmentCount() async {
    final uid = AuthService().uid;
    if (uid == null) return 0;

    final snapshot = await _db.collection('appointments')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'COMPLETED')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ──────────────────────────────────────────────
  // NOTIFICATIONS
  // ──────────────────────────────────────────────

  /// Add a notification for the current user
  Future<void> addNotification({
    required String title,
    required String description,
    required String emoji,
  }) async {
    final uid = AuthService().uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).collection('notifications').add({
      'title': title,
      'description': description,
      'emoji': emoji,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get notifications stream
  Stream<QuerySnapshot> getNotificationsStream() {
    final uid = AuthService().uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('users').doc(uid).collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    final uid = AuthService().uid;
    if (uid == null) return;

    final batch = _db.batch();
    final snapshot = await _db.collection('users').doc(uid).collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final uid = AuthService().uid;
    if (uid == null) return 0;

    final snapshot = await _db.collection('users').doc(uid).collection('notifications')
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ──────────────────────────────────────────────
  // MEDICAL REPORTS
  // ──────────────────────────────────────────────

  /// Add a report record
  Future<String> addReport(Map<String, dynamic> reportData) async {
    final uid = AuthService().uid;
    if (uid == null) throw Exception('Not authenticated');

    final docRef = await _db.collection('users').doc(uid).collection('reports').add({
      ...reportData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get all reports for current user
  Stream<QuerySnapshot> getReportsStream() {
    final uid = AuthService().uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('users').doc(uid).collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
