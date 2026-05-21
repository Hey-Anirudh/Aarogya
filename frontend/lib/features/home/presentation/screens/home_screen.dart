import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/user_manager.dart';
import 'package:aarogya/core/data_manager.dart';
import 'package:aarogya/core/services/firestore_service.dart';
import 'package:aarogya/core/models/clinic.dart';
import 'package:aarogya/core/models/appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dataManager = DataManager();
  bool _isEmergencyActive = false;
  bool _isCallingTeam = false;

  @override
  void initState() {
    super.initState();
    _dataManager.startSync();
    _dataManager.addListener(_onSyncUpdate);
  }

  @override
  void dispose() {
    _dataManager.removeListener(_onSyncUpdate);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserManager();
    final data = DataManager();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user, data),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmergencyCard(context),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Quick Actions"),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Nearby Clinics"),
                  const SizedBox(height: 16),
                  _buildNearbyClinics(data),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Upcoming Appointments"),
                  const SizedBox(height: 16),
                  _buildUpcomingAppointments(data),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserManager user, DataManager data) {
    const Color hospitalNavy = Color(0xFF0F2D26);

    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: const Color(0xFFFCFDFD),
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${user.displayName}!",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hospitalNavy,
                  ),
                ),
                Text(
                  "How are you feeling today?",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: hospitalNavy.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().getNotificationsStream(),
              builder: (context, snapshot) {
                final int unreadCount = snapshot.hasData
                    ? snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['isRead'] == false).length
                    : 0;

                return IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text("$unreadCount", style: const TextStyle(fontSize: 8)),
                    child: const Icon(Icons.notifications_none, color: hospitalNavy),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text("🏥", style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    if (_isEmergencyActive) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
          border: Border.all(color: const Color(0xFFEF4444), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32)
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeOut(duration: 800.ms)
                    .fadeIn(duration: 800.ms),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "EMERGENCY DISPATCHED",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text("🚑", style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mobile Clinic ETA", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const Text("4 Minutes", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("Unit 4 is on the way to your location", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isCallingTeam)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk, color: Colors.white)
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 1.seconds),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Call ongoing with Medical Team...",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isCallingTeam = !_isCallingTeam;
                      });
                    },
                    icon: Icon(_isCallingTeam ? Icons.call_end : Icons.call, size: 18),
                    label: Text(_isCallingTeam ? "End Call" : "Call Team"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCallingTeam ? Colors.white24 : Colors.white,
                      foregroundColor: _isCallingTeam ? Colors.white : const Color(0xFF7F1D1D),
                      elevation: _isCallingTeam ? 0 : 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEmergencyActive = false;
                        _isCallingTeam = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cancel SOS"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().shimmer(duration: 2.seconds, color: Colors.redAccent.withOpacity(0.3));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFF7F1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "EMERGENCY REQUEST",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  "Need immediate help? Request the nearest mobile clinic now.",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Confirm SOS"),
                          ],
                        ),
                        content: const Text("Are you sure you want to dispatch emergency services to your current location?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _isEmergencyActive = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("DISPATCH NOW"),
                          ),
                        ],
                      ),
                    );
                  },
                  onLongPress: () {
                     setState(() {
                       _isEmergencyActive = true;
                     });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7F1D1D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("SOS REQUEST (Tap)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
          const Text("🆘", style: TextStyle(fontSize: 80)),
        ],
      ),
    ).animate().fadeIn().scale(duration: 400.ms);
  }

  Widget _buildSectionHeader(String title) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: hospitalNavy,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            "See All",
            style: GoogleFonts.outfit(color: hospitalGreen, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    const Color hospitalGreen = Color(0xFF439A86);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.push('/booking'),
          child: _buildActionItem("📅", "Book Consultation", hospitalGreen),
        ),
        GestureDetector(
          onTap: () => context.push('/order-medicine'),
          child: _buildActionItem("💊", "Order Medicine", const Color(0xFFD9A000)),
        ),
        GestureDetector(
          onTap: () => context.push('/lab-tests'),
          child: _buildActionItem("🧪", "Lab Tests", const Color(0xFF8B5CF6)),
        ),
      ],
    );
  }

  Widget _buildActionItem(String emoji, String title, Color color) {
    const Color hospitalNavy = Color(0xFF0F2D26);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 80,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: hospitalNavy,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  // ── DYNAMIC NEARBY CLINICS ──
  Widget _buildNearbyClinics(DataManager data) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);

    if (data.clinics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          children: [
            const Text("🚛", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              "No Active Clinics Nearby",
              style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Mobile clinics will appear here once they are dispatched to your area. Check back soon!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms);
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.clinics.length,
        itemBuilder: (context, index) {
          final clinic = data.clinics[index];

          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("🚛", style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic.name,
                            style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${clinic.distanceKm.toStringAsFixed(1)} km away",
                            style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: clinic.status == "ACTIVE" ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        clinic.status,
                        style: TextStyle(
                          color: clinic.status == "ACTIVE" ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  "Next Stop: ${clinic.nextStop}",
                  style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: clinic.distanceKm < 5 ? 0.8 : 0.4,
                  backgroundColor: Colors.black.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation(hospitalGreen),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── DYNAMIC UPCOMING APPOINTMENTS ──
  Widget _buildUpcomingAppointments(DataManager data) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);

    final upcoming = data.appointments
        .where((a) => a.status == "CONFIRMED" || a.status == "IN_TRANSIT" || a.status == "CALLING" || a.status == "IN_CALL")
        .toList();

    if (upcoming.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: hospitalGreen.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: hospitalGreen.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            const Text("📅", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              "No Upcoming Appointments",
              style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Book your first consultation to get started with Aarogyam's mobile healthcare.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/booking'),
              icon: const Icon(Icons.add, size: 18),
              label: Text("Book Now", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: hospitalGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 600.ms);
    }

    return Column(
      children: upcoming.map((appt) {

            final timeStr = "${appt.scheduledAt.day}/${appt.scheduledAt.month}/${appt.scheduledAt.year} at ${appt.scheduledAt.hour.toString().padLeft(2, '0')}:${appt.scheduledAt.minute.toString().padLeft(2, '0')}";
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: hospitalGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: hospitalGreen.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: hospitalGreen, shape: BoxShape.circle),
                    child: const Text("👨‍⚕️", style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appt.doctorName,
                          style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${appt.doctorSpecialization} • $timeStr",
                          style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/tracking'),
                    child: const Icon(Icons.arrow_forward_ios, color: hospitalGreen, size: 16),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms);
          }).toList(),
        );
  }
}
