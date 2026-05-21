class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialization;
  final String clinicId;
  final String clinicName;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String symptoms;
  final String consultationType; // "Physical" or "Telemedicine"
  final DateTime scheduledAt;
  String status; // "CONFIRMED", "IN_TRANSIT", "COMPLETED", "CANCELLED"
  final String address; // patient's address for mobile clinic dispatch
  final int estimatedArrivalMinutes;
  String doctorNotes;
  String dispatchTier;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.clinicId,
    required this.clinicName,
    this.patientId = '',
    required this.patientName,
    required this.patientPhone,
    required this.symptoms,
    required this.consultationType,
    required this.scheduledAt,
    required this.status,
    required this.address,
    required this.estimatedArrivalMinutes,
    this.doctorNotes = '',
    this.dispatchTier = '',
  });

  bool get isUpcoming => scheduledAt.isAfter(DateTime.now()) && status != "CANCELLED" && status != "COMPLETED";
  bool get isPast => status == "COMPLETED" || scheduledAt.isBefore(DateTime.now());
  String get timeSlot => "${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}";

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'clinicId': clinicId,
      'clinicName': clinicName,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'symptoms': symptoms,
      'consultationType': consultationType,
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status,
      'address': address,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'doctorNotes': doctorNotes,
      'dispatchTier': dispatchTier,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      doctorSpecialization: json['doctorSpecialization'] ?? '',
      clinicId: json['clinicId'] ?? '',
      clinicName: json['clinicName'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      patientPhone: json['patientPhone'] ?? '',
      symptoms: json['symptoms'] ?? '',
      consultationType: json['consultationType'] ?? 'Physical',
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'CONFIRMED',
      address: json['address'] ?? '',
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'] ?? 15,
      doctorNotes: json['doctorNotes'] ?? '',
      dispatchTier: json['dispatchTier'] ?? '',
    );
  }
}
