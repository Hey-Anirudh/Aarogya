class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String clinicId; // which clinic they belong to
  final double rating;
  final int experienceYears;
  final bool isAvailable;
  final String phone;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.clinicId,
    required this.rating,
    required this.experienceYears,
    required this.isAvailable,
    required this.phone,
  });
}
