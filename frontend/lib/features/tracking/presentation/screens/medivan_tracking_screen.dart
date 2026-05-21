import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/models/appointment.dart';

class MedivanTrackingScreen extends StatefulWidget {
  final String appointmentId;
  const MedivanTrackingScreen({super.key, required this.appointmentId});

  @override
  State<MedivanTrackingScreen> createState() => _MedivanTrackingScreenState();
}

class _MedivanTrackingScreenState extends State<MedivanTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;

  // Patient destination (Noida sector 62 area)
  final LatLng _patientLocation = const LatLng(28.6271, 77.3760);

  // Medivan starting point (3km away)
  final LatLng _medivanStart = const LatLng(28.6120, 77.3580);

  late LatLng _currentMedivanPos;
  late List<LatLng> _routePoints;

  int _currentStep = 0;
  Timer? _moveTimer;
  bool _arrived = false;
  int _etaSeconds = 10;
  Timer? _etaTimer;
  double _progressValue = 0.0;

  late AnimationController _pulseController;

  // Map markers
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _currentMedivanPos = _medivanStart;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Generate a realistic curved route with many interpolated points
    _routePoints = _generateRoute(_medivanStart, _patientLocation, 100);

    // Start the animation after a brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      _startMedivanAnimation();
      _startEtaCountdown();
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _etaTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Generate a smooth curved route between two points with intermediate waypoints
  List<LatLng> _generateRoute(LatLng start, LatLng end, int steps) {
    final List<LatLng> route = [];

    // Create a slight curve via midpoint offset
    final midLat = (start.latitude + end.latitude) / 2 + 0.004;
    final midLng = (start.longitude + end.longitude) / 2 - 0.003;
    final mid = LatLng(midLat, midLng);

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;

      // Quadratic Bezier curve interpolation
      final lat = pow(1 - t, 2) * start.latitude +
          2 * (1 - t) * t * mid.latitude +
          pow(t, 2) * end.latitude;
      final lng = pow(1 - t, 2) * start.longitude +
          2 * (1 - t) * t * mid.longitude +
          pow(t, 2) * end.longitude;

      route.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
    return route;
  }

  void _startMedivanAnimation() {
    _moveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentStep >= _routePoints.length - 1) {
        timer.cancel();
        setState(() {
          _arrived = true;
          _etaSeconds = 0;
          _progressValue = 1.0;
        });
        return;
      }

      _currentStep++;
      setState(() {
        _currentMedivanPos = _routePoints[_currentStep];
        _progressValue = _currentStep / (_routePoints.length - 1);
        _updateMapElements();
      });

      // Smoothly move camera to follow the medivan
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentMedivanPos,
            zoom: 15.5,
            bearing: _calculateBearing(
              _routePoints[max(0, _currentStep - 1)],
              _currentMedivanPos,
            ),
            tilt: 45,
          ),
        ),
      );
    });
  }

  void _startEtaCountdown() {
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_etaSeconds <= 0 || _arrived) {
        timer.cancel();
        return;
      }
      setState(() => _etaSeconds--);
    });
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return atan2(y, x) * 180 / pi;
  }

  void _updateMapElements() {
    // Medivan marker
    _markers = {
      Marker(
        markerId: const MarkerId('medivan'),
        position: _currentMedivanPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '🚛 Medivan', snippet: 'On the way!'),
        anchor: const Offset(0.5, 0.5),
      ),
      Marker(
        markerId: const MarkerId('patient'),
        position: _patientLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: '📍 Your Location'),
      ),
    };

    // Draw route polyline (remaining path)
    final remaining = _routePoints.sublist(_currentStep);
    final traveled = _routePoints.sublist(0, _currentStep + 1);

    _polylines = {
      Polyline(
        polylineId: const PolylineId('traveled'),
        points: traveled,
        color: const Color(0xFF439A86),
        width: 5,
      ),
      Polyline(
        polylineId: const PolylineId('remaining'),
        points: remaining,
        color: const Color(0xFF439A86).withOpacity(0.3),
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);

    // Get appointment details
    final appt = DataManager().getAppointment(widget.appointmentId);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ── REAL GOOGLE MAPS ──
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _medivanStart,
                zoom: 14.0,
                tilt: 30,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMapElements();
                // Initial camera pan to show full route
                final bounds = LatLngBounds(
                  southwest: LatLng(
                    min(_medivanStart.latitude, _patientLocation.latitude) - 0.005,
                    min(_medivanStart.longitude, _patientLocation.longitude) - 0.005,
                  ),
                  northeast: LatLng(
                    max(_medivanStart.latitude, _patientLocation.latitude) + 0.005,
                    max(_medivanStart.longitude, _patientLocation.longitude) + 0.005,
                  ),
                );
                controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
              },
            ),
          ),

          // ── TOP HEADER BAR ──
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: hospitalNavy, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _arrived
                                ? Colors.green.withOpacity(0.1)
                                : hospitalGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _arrived ? "✅" : "🚛",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _arrived
                                    ? "Medivan Has Arrived!"
                                    : "Medivan En Route",
                                style: GoogleFonts.outfit(
                                  color: hospitalNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _arrived
                                    ? "Your doctor is ready"
                                    : "ETA: $_etaSeconds seconds",
                                style: GoogleFonts.outfit(
                                  color: _arrived ? Colors.green : hospitalGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Live pulse indicator
                        if (!_arrived)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(
                                    0.4 + _pulseController.value * 0.6,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 6 + _pulseController.value * 4,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM DETAILS DRAWER ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _arrived ? "ARRIVED" : "EN ROUTE",
                            style: GoogleFonts.outfit(
                              color: _arrived ? Colors.green : hospitalGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            "${(_progressValue * 100).toInt()}%",
                            style: GoogleFonts.outfit(
                              color: hospitalNavy.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          minHeight: 6,
                          backgroundColor: Colors.black.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation(
                            _arrived ? Colors.green : hospitalGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Doctor info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hospitalGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: hospitalGreen.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: hospitalGreen.withOpacity(0.3), width: 2),
                          ),
                          child: const Center(
                            child: Text("👨‍⚕️", style: TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appt?.doctorName ?? "Dr. Assigned",
                                style: GoogleFonts.outfit(
                                  color: hospitalNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appt?.doctorSpecialization ?? "General Physician",
                                style: GoogleFonts.outfit(
                                  color: hospitalNavy.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hospitalGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call, color: Color(0xFF439A86), size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _buildStatChip("🚛", "Medivan", appt?.clinicName ?? "Aarogyam Mobile", hospitalNavy),
                      const SizedBox(width: 12),
                      _buildStatChip("⏱️", "ETA", _arrived ? "Arrived" : "$_etaSeconds sec", hospitalNavy),
                      const SizedBox(width: 12),
                      _buildStatChip("📍", "Type", appt?.consultationType ?? "Physical", hospitalNavy),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Arrived CTA
                  if (_arrived)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: Text(
                          "MEDIVAN IS HERE",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: Colors.green.withOpacity(0.3),
                        ),
                      ),
                    ).animate().fadeIn().scale(
                          begin: const Offset(0.95, 0.95),
                          curve: Curves.easeOutBack,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String emoji, String label, String value, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: textColor.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
