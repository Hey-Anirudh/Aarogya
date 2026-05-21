class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  // All fields start empty — populated ONLY by user input
  String name = "";
  String age = "";
  String gender = "";
  String address = "";
  String healthHistory = "";
  String phoneNumber = "";
  String role = "patient"; // "patient", "doctor", "admin"

  // Computed display helpers
  String get displayName => name.isNotEmpty ? name : "Guest";
  String get displayPhone => phoneNumber.isNotEmpty ? phoneNumber : "Not set";
  String get displayAge => age.isNotEmpty ? age : "--";
  String get displayGender => gender.isNotEmpty ? gender : "--";
  String get displayAddress => address.isNotEmpty ? address : "No address set";
  bool get isProfileComplete => name.isNotEmpty && phoneNumber.isNotEmpty;
}
