class Clinic {
  final String id;
  final String name;
  final String vehicleNumber;
  final double latitude;
  final double longitude;
  final String currentLocation; // readable address
  final List<String> services;
  final String status; // "ACTIVE", "IN_TRANSIT", "OFFLINE"
  final double distanceKm;
  final String nextStop;

  Clinic({
    required this.id,
    required this.name,
    required this.vehicleNumber,
    required this.latitude,
    required this.longitude,
    required this.currentLocation,
    required this.services,
    required this.status,
    required this.distanceKm,
    required this.nextStop,
  });
}
