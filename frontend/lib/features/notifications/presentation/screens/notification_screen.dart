import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aarogya/core/data_manager.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);
    final data = DataManager();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: hospitalNavy),
        title: Text(
          "Notifications",
          style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (data.unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() => data.markAllRead());
              },
              child: Text(
                "Mark all as read",
                style: GoogleFonts.outfit(color: hospitalGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: data.notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🔔", style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 24),
                    Text(
                      "No Notifications Yet",
                      style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Appointment confirmations, clinic alerts, and medicine reminders will appear here.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: data.notifications.length,
              itemBuilder: (context, index) {
                final notif = data.notifications[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => data.markRead(notif.id));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notif.isRead ? Colors.white : hospitalGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notif.isRead ? Colors.black.withOpacity(0.05) : hospitalGreen.withOpacity(0.24),
                        width: 1.5,
                      ),
                      boxShadow: notif.isRead
                          ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), shape: BoxShape.circle),
                          child: Text(notif.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(notif.title, style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  Text(notif.timeAgo, style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.description,
                                style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.65), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: hospitalGreen, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
              },
            ),
    );
  }
}
