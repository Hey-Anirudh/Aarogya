import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_setup_screen.dart';
import '../features/home/presentation/screens/main_screen.dart';
import '../features/appointments/presentation/screens/booking_screen.dart';
import '../features/appointments/presentation/screens/confirmation_screen.dart';
import '../features/tracking/presentation/screens/tracking_screen.dart';
import '../features/notifications/presentation/screens/notification_screen.dart';
import '../features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/doctor/presentation/screens/telemedicine_call_screen.dart';
import '../features/appointments/presentation/screens/medicine_order_screen.dart';
import '../features/appointments/presentation/screens/lab_tests_screen.dart';
import '../features/profile/presentation/screens/medical_history_screen.dart';
import '../features/profile/presentation/screens/manage_addresses_screen.dart';
import '../features/profile/presentation/screens/help_support_screen.dart';
import '../features/profile/presentation/screens/terms_policies_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OTPScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/booking',
      builder: (context, state) => const BookingScreen(),
    ),
    GoRoute(
      path: '/appointment-confirmation',
      builder: (context, state) => const AppointmentConfirmationScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/doctor-dashboard',
      builder: (context, state) => const DoctorDashboardScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/telemedicine/:id',
      builder: (context, state) {
        final appointmentId = state.pathParameters['id'] ?? '';
        return TelemedicineCallScreen(appointmentId: appointmentId);
      },
    ),
    GoRoute(
      path: '/order-medicine',
      builder: (context, state) => const MedicineOrderScreen(),
    ),
    GoRoute(
      path: '/lab-tests',
      builder: (context, state) => const LabTestsScreen(),
    ),
    GoRoute(
      path: '/medical-history',
      builder: (context, state) => const MedicalHistoryScreen(),
    ),
    GoRoute(
      path: '/manage-addresses',
      builder: (context, state) => const ManageAddressesScreen(),
    ),
    GoRoute(
      path: '/help-support',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/terms-policies',
      builder: (context, state) => const TermsPoliciesScreen(),
    ),
  ],
);
