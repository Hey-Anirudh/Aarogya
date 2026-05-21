import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aarogya/routes/app_router.dart';
import 'package:aarogya/core/services/local_storage_service.dart';
import 'package:aarogya/core/services/notification_service.dart';

import 'package:aarogya/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive local storage
  await LocalStorageService().initialize();

  // Initialize push notifications
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: AarogyamApp(),
    ),
  );
}

class AarogyamApp extends StatelessWidget {
  const AarogyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aarogyam - Future of Healthcare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF0A84FF),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      ),
      routerConfig: goRouter,
    );
  }
}
