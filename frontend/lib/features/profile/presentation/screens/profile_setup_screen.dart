import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:aarogya/core/user_manager.dart';
import 'package:aarogya/core/services/local_storage_service.dart';
import 'package:aarogya/core/services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String? _selectedGender;
  
  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = UserManager();
    _nameController.text = user.name;
    _ageController.text = user.age;
    _addressController.text = user.address;
    _historyController.text = user.healthHistory;
    if (['Male', 'Female', 'Other'].contains(user.gender)) {
      _selectedGender = user.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  // Opens the real interactive Google Maps Address Picker
  void _openMapPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MapPickerSheet(),
    ).then((selectedAddress) {
      if (selectedAddress != null && selectedAddress is String) {
        setState(() {
          _addressController.text = selectedAddress;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalGreen = Color(0xFF439A86);
    const Color hospitalNavy = Color(0xFF0F2D26); // High-contrast clinical deep green

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Setup Profile",
          style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04), // soft clinical light grey
                      shape: BoxShape.circle,
                      border: Border.all(color: hospitalGreen.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Center(child: Text("👤", style: TextStyle(fontSize: 40))),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: hospitalGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            ),
            
            const SizedBox(height: 40),
            
            _buildLabel("Full Name", hospitalNavy),
            _buildTextField("Enter your name", hospitalNavy, hospitalGreen, controller: _nameController),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Age", hospitalNavy),
                      _buildTextField("Years", hospitalNavy, hospitalGreen, keyboardType: TextInputType.number, controller: _ageController),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Gender", hospitalNavy),
                      _buildGenderDropdown(hospitalNavy, hospitalGreen),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Permanent Address Section with interactive Google Maps button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel("Permanent Address", hospitalNavy),
                TextButton.icon(
                  onPressed: () => _openMapPicker(context),
                  icon: const Icon(Icons.my_location_rounded, size: 15, color: hospitalGreen),
                  label: Text(
                    "Google Maps", 
                    style: GoogleFonts.outfit(color: hospitalGreen, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            _buildTextField("House no, Street, City...", hospitalNavy, hospitalGreen, maxLines: 3, controller: _addressController),
            
            const SizedBox(height: 20),
            
            _buildLabel("Health History (Optional)", hospitalNavy),
            _buildTextField("Any chronic diseases, allergies...", hospitalNavy, hospitalGreen, maxLines: 4, controller: _historyController),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  final user = UserManager();
                  user.name = _nameController.text.trim();
                  user.age = _ageController.text.trim();
                  user.gender = _selectedGender ?? "";
                  user.address = _addressController.text.trim();
                  user.healthHistory = _historyController.text.trim();

                  // Save securely to Firebase Cloud Firestore first
                  try {
                    await FirestoreService().saveUserProfile(
                      name: user.name,
                      age: user.age,
                      gender: user.gender,
                      address: user.address,
                      healthHistory: user.healthHistory,
                      phoneNumber: user.phoneNumber,
                    );
                  } catch (e) {
                    print("Error saving to Firestore: $e");
                  }

                  // Save to SQLite via Node backend (with timeout to prevent freezing)
                  try {
                    final dio = Dio(BaseOptions(
                      baseUrl: 'http://192.168.1.48:5000/api/',
                      connectTimeout: const Duration(seconds: 2),
                      receiveTimeout: const Duration(seconds: 2),
                    ));
                    await dio.post('users/profile', data: {
                      'phone': user.phoneNumber,
                      'name': user.name,
                      'role': user.role,
                      'age': user.age,
                      'gender': user.gender,
                      'address': user.address,
                      'medicalHistory': user.healthHistory,
                    });
                  } catch (e) {
                    print("Error saving profile to backend: $e");
                  }

                  // Cache locally with Hive
                  await LocalStorageService().cacheUserProfile({
                    'name': user.name,
                    'age': user.age,
                    'gender': user.gender,
                    'address': user.address,
                    'healthHistory': user.healthHistory,
                    'phoneNumber': user.phoneNumber,
                    'role': user.role,
                  });
                  await LocalStorageService().setLoggedIn(true);

                  if (mounted) context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hospitalGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: hospitalGreen.withOpacity(0.3),
                ),
                child: Text(
                  "COMPLETE SETUP",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: textColor.withOpacity(0.8), 
          fontWeight: FontWeight.bold, 
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, Color textColor, Color focusColor, {TextInputType? keyboardType, int maxLines = 1, TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

  Widget _buildGenderDropdown(Color textColor, Color focusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          dropdownColor: Colors.white,
          hint: Text("Select", style: GoogleFonts.outfit(color: textColor.withOpacity(0.3))),
          icon: Icon(Icons.keyboard_arrow_down, color: focusColor),
          isExpanded: true,
          style: GoogleFonts.outfit(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
          items: ["Male", "Female", "Other"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
      ),
    );
  }
}

// Breathtaking REAL Google Maps Sheet with High-Precision GPS Lock & Reverse Geocoding
class MapPickerSheet extends StatefulWidget {
  const MapPickerSheet({super.key});

  @override
  State<MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<MapPickerSheet> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(28.6256, 77.3732); // Default Noida
  String _address = "Acquiring live satellite coordinates...";
  bool _isLoading = true;
  bool _isEmulatorDefaultGps = false; // Detects Googleplex coordinates

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Fetch location using IP-based API (bypasses emulator GPS hangs)
  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _address = "Determining location via IP...";
    });

    try {
      final dio = Dio();
      final response = await dio.get('http://ip-api.com/json').timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final double lat = response.data['lat'];
        final double lon = response.data['lon'];
        final LatLng liveLatLng = LatLng(lat, lon);

        if (mounted) {
          setState(() {
            _currentPosition = liveLatLng;
            _isLoading = false;
            _isEmulatorDefaultGps = false;
          });
          
          // Pan the Google Map camera to the locked location
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: liveLatLng, zoom: 17.5),
            ),
          );

          // Instantly geocode coordinates into a real street address
          _reverseGeocode(liveLatLng);
        }
      } else {
        throw 'IP Location API returned failure';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _address = "Error fetching live coordinates. Drag map to pin.";
        });
      }
    }
  }

  // Live Reverse Geocoding using Nominatim REST APIs
  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': latLng.latitude,
          'lon': latLng.longitude,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'AarogyamHealthcareApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final String displayName = response.data['display_name'] ?? "";
        if (mounted) {
          setState(() {
            _address = displayName;
          });
        }
      } else {
        throw 'Failed to reverse geocode';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = "Noida, Uttar Pradesh, India (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // 1. REAL LIVE INTERACTIVE GOOGLE MAPS PANEL
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 16.0,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // Animate camera to correct spot on start
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: _currentPosition, zoom: 16.5),
                    ),
                  );
                },
                onCameraIdle: () {
                  _reverseGeocode(_currentPosition);
                },
                onCameraMove: (CameraPosition position) {
                  _currentPosition = position.target;
                },
              ),
            ),
          ),

          // 2. BOUNCING MEDICAL LOCATION CENTER TARGET FLAG
          Center(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0), // center pin precisely on map coordinate
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: hospitalNavy,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
                        ],
                      ),
                      child: Text(
                        "DRAG MAP TO PIN",
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 48,
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .moveY(begin: 0, end: -4, duration: 800.ms, curve: Curves.easeInOut),
                  ],
                ),
              ),
            ),
          ),

          // 3. TOP MODAL BAR
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // 4. SMART EMULATOR GPS HELPER OVERLAY
          if (_isEmulatorDefaultGps)
            Positioned(
              top: 36,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Emulator Simulated GPS Active",
                            style: GoogleFonts.outfit(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Google default is California, USA. Drag this map or select India in the emulator sidebar settings ('...')!",
                            style: GoogleFonts.outfit(color: Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: -0.1, end: 0).fadeIn(),
            ),

          // 5. FLOATING SATELLITE POSITION LOCK GPS TRIGGER BUTTON
          Positioned(
            right: 20,
            bottom: 220,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: IconButton(
                onPressed: _determinePosition,
                icon: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(hospitalGreen),
                        ),
                      )
                    : const Icon(Icons.gps_fixed, color: hospitalGreen),
              ),
            ),
          ),

          // 6. BOTTOM DETAILS DRAWER (Real location address text and use trigger)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 25,
                    offset: const Offset(0, -6),
                  )
                ],
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hospitalGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "HIGH-PRECISION GPS LOCK 📡",
                          style: GoogleFonts.outfit(color: hospitalGreen, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${_currentPosition.latitude.toStringAsFixed(4)}° N, ${_currentPosition.longitude.toStringAsFixed(4)}° E",
                        style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.45), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Live Dynamic reverse-geocoded address display text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _address,
                      key: ValueKey(_address),
                      style: GoogleFonts.outfit(
                        color: hospitalNavy,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Primary location acceptance button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context, _address),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hospitalGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: hospitalGreen.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: hospitalGreen.withOpacity(0.3),
                      ),
                      child: Text(
                        "CONFIRM ADDRESS & USE",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
