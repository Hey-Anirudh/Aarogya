import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aarogya/core/data_manager.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);
    final data = DataManager();
    final filteredReports = data.searchReports(_searchQuery);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Medical Reports",
          style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "Search reports...",
                  hintStyle: TextStyle(color: hospitalNavy.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.search, color: hospitalNavy.withOpacity(0.4)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Reports list
          Expanded(
            child: filteredReports.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("📋", style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isEmpty ? "No Medical Reports" : "No Results Found",
                            style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? "Reports from your consultations, lab tests, and prescriptions will appear here."
                                : "Try searching with different keywords.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: hospitalGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(report.fileType == "PDF" ? "📄" : "🖼️", style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(report.title, style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${report.date} • ${report.fileSize}",
                                    style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.download_rounded, color: hospitalGreen),
                              style: IconButton.styleFrom(backgroundColor: hospitalGreen.withOpacity(0.12)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: -0.05, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
