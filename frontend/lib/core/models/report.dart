class MedicalReport {
  final String id;
  final String title;
  final String date;
  final String fileType; // "PDF", "JPG", "PNG"
  final String fileSize;
  final String? appointmentId; // linked to which appointment
  final String category; // "Prescription", "Lab Test", "X-Ray", "Vaccination", "Other"
  final String? fileUrl;

  MedicalReport({
    required this.id,
    required this.title,
    required this.date,
    required this.fileType,
    required this.fileSize,
    this.appointmentId,
    required this.category,
    this.fileUrl,
  });
}
