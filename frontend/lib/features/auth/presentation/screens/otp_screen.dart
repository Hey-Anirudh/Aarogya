import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aarogya/core/services/auth_service.dart';
import 'package:aarogya/core/services/firestore_service.dart';
import 'package:aarogya/core/user_manager.dart';
import 'package:dio/dio.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  // Generate 6 text controllers and focus nodes for a secure 6-digit OTP
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _authKeyController = TextEditingController();
  
  bool _showNotification = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _countdownSeconds = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Simulate SMS delivery by sliding down notification banner after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showNotification = true;
        });
        // Auto-dismiss the SMS banner after 6 seconds
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted) {
            setState(() {
              _showNotification = false;
            });
          }
        });
      }
    });
  }

  void _startTimer() {
    _countdownSeconds = 59;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) {
          setState(() {
            _countdownSeconds--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Securely mask phone number to hide middle digits
  String _getMaskedPhoneNumber() {
    final String phone = UserManager().phoneNumber;
    if (phone.length < 6) return "XXXXXX-XXXX";
    return "${phone.substring(0, 7)}****${phone.substring(phone.length - 3)}";
  }

  // Validate the entered 6-digit secure code via Firebase
  void _verifyOtp() async {
    final String enteredOtp = _controllers.map((c) => c.text.trim()).join("");
    
    if (enteredOtp.length < 6) {
      setState(() {
        _errorMessage = "Please enter the complete 6-digit code.";
      });
      return;
    }

    final role = UserManager().role;
    if ((role == 'doctor' || role == 'admin') && _authKeyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Staff authorization key is required.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // 1. Verify OTP with Firebase (if not mocked)
      await AuthService().verifyOtp(otp: enteredOtp);
      
      // 2. Auth Key & DB User verification via Node backend
      final dio = Dio(BaseOptions(
        baseUrl: 'http://192.168.1.48:5000/api/',
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ));
      final response = await dio.post('auth/verify', data: {
        'phone': UserManager().phoneNumber,
        'role': role,
        'authKey': _authKeyController.text.trim(),
      });
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        final data = response.data;
        if (data['isNew'] == true) {
            context.go('/profile-setup');
        } else {
            // Restore user data!
            final user = data['user'];
            UserManager().name = user['name'] ?? '';
            if (role == 'patient' && user['patient'] != null) {
              UserManager().age = user['patient']['age']?.toString() ?? '';
              UserManager().gender = user['patient']['gender'] ?? '';
              UserManager().address = user['patient']['address'] ?? '';
              UserManager().healthHistory = user['patient']['medicalHistory'] ?? '';
            } else if (role == 'doctor' || role == 'admin') {
               UserManager().address = 'Aarogyam HQ Command, Noida'; 
            }
            context.go('/home');
        }
      }
    } catch (e) {
      if (e is DioException && (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout)) {
        print("⚠️ Backend offline or timed out. Bypassing verification for prototyping...");
        if (mounted) {
          setState(() => _isLoading = false);
          final profile = await FirestoreService().getUserProfile();
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
        return;
      }

      setState(() {
        _isLoading = false;
        if (e is DioException && e.response?.statusCode == 401) {
          _errorMessage = "Invalid Authorization Key. Access Denied.";
        } else {
          _errorMessage = "Invalid verification code. Please try again.";
          for (var c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        }
      });
    }
  }

  // Trigger OTP resend via Firebase
  void _handleResendCode() {
    if (_countdownSeconds > 0) return;
    
    // Resend OTP via Firebase Auth
    final phone = UserManager().phoneNumber.replaceAll(RegExp(r'[^0-9]'), '').substring(2);
    AuthService().sendOtp(phoneNumber: phone, onCodeSent: (_) {}, onError: (_) {}, onAutoVerified: () {});
    
    setState(() {
      _errorMessage = null;
      _showNotification = true;
    });
    
    _startTimer();

    // Dismiss banner
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalGreen = Color(0xFF439A86);
    const Color lightMint = Color(0xFFEDF7F5); // Soothing medical soft mint green
    const Color clinicalWhite = Color(0xFFFCFDFD); // Clean clinical white
    const Color hospitalNavy = Color(0xFF0F2D26); // High-contrast clinical navy

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching login
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [clinicalWhite, lightMint],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 55,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: hospitalNavy, size: 22),
              onPressed: () => context.go('/login'),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),

                  // Header Texts
                  Text(
                    "Verification 🔑",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: hospitalNavy,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.05, end: 0),
                  
                  const SizedBox(height: 12),
                  
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: hospitalNavy.withOpacity(0.65),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: "We've sent a 6-digit verification code to "),
                        TextSpan(
                          text: "+91 ${_getMaskedPhoneNumber()}",
                          style: const TextStyle(color: hospitalNavy, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 50),

                  // 6-Digit Secure Input Boxes (Dot Security!)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (index) => SizedBox(
                        width: 46, // Ultra-responsive width for 6 boxes
                        height: 54,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          obscureText: true, // DOT SECURITY activated
                          obscuringCharacter: '•', // Elegant custom secure dot
                          style: GoogleFonts.outfit(
                            color: hospitalNavy, 
                            fontSize: 22, 
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.12), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: hospitalGreen, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white, // Pure white slots
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                _focusNodes[index].unfocus(); // unfocus last field
                              }
                            } else {
                              if (index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            }
                          },
                        ),
                      ).animate().fadeIn(delay: (300 + (index * 70)).ms).scale(begin: const Offset(0.9, 0.9)),
                    ),
                  ),

                  // Verification Error text
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    ).animate().shake(duration: 300.ms),
                  ],

                  if (UserManager().role == 'doctor' || UserManager().role == 'admin') ...[
                    const SizedBox(height: 30),
                    Text(
                      "Staff Authorization Key",
                      style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _authKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Enter the secure staff auth key",
                        hintStyle: TextStyle(color: hospitalNavy.withOpacity(0.3), fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.security, color: hospitalGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.12))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.12))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: hospitalGreen, width: 1.5)),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                  ],

                  const SizedBox(height: 45),

                  // VERIFY & CONTINUE Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hospitalGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: hospitalGreen.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        shadowColor: hospitalGreen.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              "VERIFY & CONTINUE",
                              style: GoogleFonts.outfit(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  letterSpacing: 1,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 35),

                  // Resend Code timer / link
                  Center(
                    child: TextButton(
                      onPressed: _countdownSeconds == 0 ? _handleResendCode : null,
                      style: TextButton.styleFrom(
                        foregroundColor: hospitalGreen,
                      ),
                      child: Text(
                        _countdownSeconds > 0
                            ? "Resend Code in 00:${_countdownSeconds.toString().padLeft(2, '0')}"
                            : "Resend OTP Verification",
                        style: GoogleFonts.outfit(
                          color: _countdownSeconds > 0 
                              ? Colors.black26 
                              : hospitalGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Android/iOS style SMS Notification Slide Down Overlay Simulation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            top: _showNotification ? 55 : -120, // Slides down beautifully
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Sleek Android notification black
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  // App Icon Container inside SMS
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hospitalGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_circle, color: hospitalGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "MESSAGES • now",
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Aarogyam: Your verification OTP is 123456. Valid for 10 mins.",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
