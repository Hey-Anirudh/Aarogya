import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/services/auth_service.dart';
import 'package:aarogya/core/services/firestore_service.dart';
import 'package:aarogya/core/user_manager.dart';

enum AuthViewMode {
  gateway,
  loginForm,
  signUpForm,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  AuthViewMode _currentMode = AuthViewMode.gateway;
  String _selectedRole = 'patient'; // 'patient', 'doctor', 'admin'
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleGetOtp() async {
    final String phone = _phoneController.text.trim();

    if (phone.length != 10 || double.tryParse(phone) == null) {
      setState(() => _errorMessage = "Please enter a valid 10-digit mobile number.");
      return;
    }

    // Testing Phase Lockdown
    if (_selectedRole == 'patient' && phone != '1111111111') {
      setState(() => _errorMessage = "Testing Phase: Please use 1111111111 for Patient login.");
      return;
    } else if (_selectedRole == 'doctor' && phone != '2222222222') {
      setState(() => _errorMessage = "Testing Phase: Please use 2222222222 for Doctor login.");
      return;
    } else if (_selectedRole == 'admin' && phone != '3333333333') {
      setState(() => _errorMessage = "Testing Phase: Please use 3333333333 for Admin login.");
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Save phone to UserManager
    UserManager().phoneNumber = "+91 ${phone.substring(0, 5)} ${phone.substring(5)}";

    // Use Firebase Auth to send real OTP
    await AuthService().sendOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        setState(() => _isLoading = false);
        if (mounted) context.go('/otp');
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
      onAutoVerified: () async {
        setState(() => _isLoading = false);
        final profile = await FirestoreService().getUserProfile();
        if (mounted) {
            if (profile != null && profile['name'] != null && profile['name'].toString().isNotEmpty) {
                UserManager().name = profile['name'] ?? '';
                UserManager().age = profile['age']?.toString() ?? '';
                UserManager().gender = profile['gender'] ?? '';
                UserManager().address = profile['address'] ?? '';
                UserManager().healthHistory = profile['healthHistory'] ?? '';
                context.go('/home');
            } else {
                context.go('/profile-setup');
            }
        }
      },
    );
  }

  void _handleLoginSubmit() async {
    UserManager().role = _selectedRole;
    _handleGetOtp();
  }

  @override
  void initState() {
    super.initState();
    UserManager().role = 'patient';
    UserManager().name = '';
  }

  void _backToGateway() {
    setState(() {
      _errorMessage = null;
      _phoneController.clear();
      _pinController.clear();
      _selectedRole = 'patient';
      _currentMode = AuthViewMode.gateway;
    });
    UserManager().role = 'patient';
    UserManager().name = '';
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalGreen = Color(0xFF439A86);
    const Color lightMint = Color(0xFFEDF7F5);
    const Color clinicalWhite = Color(0xFFFCFDFD);
    const Color hospitalNavy = Color(0xFF0F2D26);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [clinicalWhite, lightMint],
              ),
            ),
          ),
          if (_currentMode != AuthViewMode.gateway)
            Positioned(
              top: 55,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: hospitalNavy, size: 22),
                onPressed: _backToGateway,
              ).animate().fadeIn(duration: 300.ms),
            ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: _currentMode == AuthViewMode.gateway
                  ? _buildGatewayView(hospitalGreen, hospitalNavy)
                  : _buildFormView(hospitalGreen, hospitalNavy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayView(Color primaryColor, Color textColor) {
    return Column(
      key: const ValueKey("gateway_view"),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        _buildClinicalLogo(primaryColor, textColor, largeSize: true)
            .animate()
            .scale(begin: const Offset(0.85, 0.85), curve: Curves.elasticOut, duration: 1.seconds),
        const SizedBox(height: 35),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            "Access specialized doctors, active mobile clinics, and receive clinical care directly in your rural community.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: textColor.withOpacity(0.65), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 40.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentMode = AuthViewMode.loginForm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  child: Text("Log In", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentMode = AuthViewMode.signUpForm),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("Sign Up", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormView(Color primaryColor, Color textColor) {
    final bool isLogin = _currentMode == AuthViewMode.loginForm;

    String desc = "";
    if (_selectedRole == 'patient') {
      desc = isLogin
          ? "Enter your registered number to receive a secure OTP via SMS."
          : "Register your mobile number to create your new healthcare profile.";
    } else if (_selectedRole == 'doctor') {
      desc = "Enter your clinical mobile number to verify your physician credentials via SMS OTP.";
    } else {
      desc = "Enter your registered system administrator mobile number to authenticate via SMS OTP.";
    }

    String btnText = "GET SECURE OTP";

    return SingleChildScrollView(
      key: const ValueKey("form_view"),
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          _buildClinicalLogo(primaryColor, textColor, largeSize: false),
          const SizedBox(height: 35),
          
          // Role indicator (shown when doctor/admin is selected)
          if (_selectedRole != 'patient')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedRole == 'doctor' ? Icons.medical_services_rounded : Icons.admin_panel_settings_rounded,
                    color: primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Signing in as ${_selectedRole == 'doctor' ? 'Doctor' : 'Administrator'}",
                    style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedRole = 'patient';
                      _errorMessage = null;
                    }),
                    child: Icon(Icons.close_rounded, color: primaryColor.withOpacity(0.6), size: 18),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          if (_selectedRole != 'patient') const SizedBox(height: 20),


          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? "Welcome Back 👋" : "Create Account 🏥",
                  style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: GoogleFonts.outfit(fontSize: 14, color: textColor.withOpacity(0.65), height: 1.4),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),
          const SizedBox(height: 40),

          // Single unified phone number input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _errorMessage != null ? Colors.redAccent.withOpacity(0.4) : primaryColor.withOpacity(0.24),
                width: 1.5,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    const Text("🇮🇳", style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text("+91", style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(height: 24, width: 1, color: Colors.black12),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: GoogleFonts.outfit(color: textColor, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Enter Mobile Number",
                      hintStyle: TextStyle(color: textColor.withOpacity(0.25)),
                      counterText: "",
                      border: InputBorder.none,
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) setState(() => _errorMessage = null);
                    },
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.98, 0.98)),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_errorMessage!, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ).animate().shake(duration: 300.ms),
          ],
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Testing Phase: Use ${_selectedRole == 'patient' ? '1111111111' : _selectedRole == 'doctor' ? '2222222222' : '3333333333'} to login.",
                    style: GoogleFonts.outfit(color: Colors.orange.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 35),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLoginSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                shadowColor: primaryColor.withOpacity(0.3),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(btnText, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 30),
          if (_selectedRole == 'patient')
            TextButton(
              onPressed: _backToGateway,
              child: Text(
                isLogin ? "Need a new account? Sign Up" : "Already registered? Log In",
                style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          const SizedBox(height: 16),
          if (_selectedRole == 'patient') ...[
            Divider(color: textColor.withOpacity(0.08), thickness: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedRole = 'doctor';
                    _errorMessage = null;
                  }),
                  icon: Icon(Icons.medical_services_outlined, color: textColor.withOpacity(0.5), size: 16),
                  label: Text(
                    "Sign in as Doctor",
                    style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                Container(height: 16, width: 1, color: textColor.withOpacity(0.15)),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedRole = 'admin';
                    _errorMessage = null;
                  }),
                  icon: Icon(Icons.admin_panel_settings_outlined, color: textColor.withOpacity(0.5), size: 16),
                  label: Text(
                    "Sign in as Admin",
                    style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicalLogo(Color primaryColor, Color textColor, {required bool largeSize}) {
    final double iconSize = largeSize ? 85 : 55;
    final double crossSize = largeSize ? 46 : 32;
    final double ringSize = largeSize ? 60 : 38;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.18), blurRadius: largeSize ? 25 : 12, spreadRadius: 2)],
            border: Border.all(color: primaryColor.withOpacity(0.08)),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5)),
                ).animate(onPlay: (c) => c.repeat())
                 .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 1.5.seconds, curve: Curves.easeOut)
                 .fadeOut(),
                Icon(Icons.add_circle, color: primaryColor, size: crossSize),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "AAROGYAM",
          style: GoogleFonts.outfit(
            fontSize: largeSize ? 26 : 16,
            fontWeight: FontWeight.w900,
            letterSpacing: largeSize ? 8 : 4,
            color: textColor,
            shadows: [Shadow(color: primaryColor.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
          ),
        ),
      ],
    );
  }
}
