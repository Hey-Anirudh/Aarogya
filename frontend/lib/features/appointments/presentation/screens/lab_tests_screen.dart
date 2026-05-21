import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class LabTestsScreen extends StatefulWidget {
  const LabTestsScreen({super.key});

  @override
  State<LabTestsScreen> createState() => _LabTestsScreenState();
}

class _LabTestsScreenState extends State<LabTestsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _tests = [
    {'name': 'Complete Blood Count (CBC)', 'desc': 'Checks for anemia, infection, and many other diseases.', 'price': 399, 'icon': '🩸', 'popular': true},
    {'name': 'Lipid Profile', 'desc': 'Measures cholesterol levels to assess heart risk.', 'price': 599, 'icon': '❤️', 'popular': true},
    {'name': 'Thyroid Profile (T3, T4, TSH)', 'desc': 'Checks thyroid gland function.', 'price': 499, 'icon': '🦋', 'popular': false},
    {'name': 'Diabetes Screening (HbA1c)', 'desc': 'Average blood sugar level over the past 2-3 months.', 'price': 450, 'icon': '🍬', 'popular': true},
    {'name': 'Liver Function Test (LFT)', 'desc': 'Measures enzymes and proteins to assess liver health.', 'price': 699, 'icon': '🧬', 'popular': false},
    {'name': 'Vitamin D & B12 Test', 'desc': 'Measures essential vitamins for bone and nerve health.', 'price': 1299, 'icon': '☀️', 'popular': true},
    {'name': 'Kidney Function Test (KFT)', 'desc': 'Measures how well your kidneys are working.', 'price': 799, 'icon': '⚕️', 'popular': false},
  ];

  final Set<String> _cart = {};
  double _total = 0;

  void _toggleCart(Map<String, dynamic> test) {
    setState(() {
      if (_cart.contains(test['name'])) {
        _cart.remove(test['name']);
        _total -= test['price'];
      } else {
        _cart.add(test['name']);
        _total += test['price'];
      }
    });
  }

  void _bookTests() {
    if (_cart.isEmpty) return;
    
    // Simulate booking
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.science, color: Colors.white, size: 40),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                "Tests Booked!",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F2D26),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "A technician from the Aarogyam Mobile Clinic will visit you shortly to collect your samples.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    context.go('/home'); // go home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF439A86),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Back to Home", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color hospitalNavy = Color(0xFF0F2D26);
    const Color hospitalGreen = Color(0xFF439A86);
    const Color accentPurple = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Book Lab Tests", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: hospitalNavy),
      ),
      body: Column(
        children: [
          // Header Illustration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.08),
              border: Border(bottom: BorderSide(color: accentPurple.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                const Text("🔬", style: TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("At-Home Sample Collection", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text("Safe, hygienic, and convenient testing at your doorstep.", style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: hospitalNavy),
                  hintText: "Search lab tests...",
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ),

          // Upload Prescription for Labs Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentPurple, const Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentPurple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Doctor's Advice?", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text("Upload it to auto-add required tests.", style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Camera opened for advice upload")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: accentPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text("Upload", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ).animate().slideX(begin: -0.1, end: 0).fadeIn(),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
            child: Row(
              children: [
                Text("Popular Tests & Packages", style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("Safe & Hygienic", style: GoogleFonts.outfit(color: hospitalGreen, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Test List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _tests.length,
              itemBuilder: (context, index) {
                final test = _tests[index];
                if (_searchController.text.isNotEmpty &&
                    !test['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase())) {
                  return const SizedBox.shrink();
                }

                final isSelected = _cart.contains(test['name']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? accentPurple : Colors.black.withOpacity(0.05),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentPurple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(test['icon'], style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(test['name'], style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                if (test['popular'])
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accentPurple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text("Popular", style: GoogleFonts.outfit(color: accentPurple, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(test['desc'],
                                style: GoogleFonts.outfit(
                                  color: hospitalNavy.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("₹${test['price']}", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _toggleCart(test),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? accentPurple : hospitalNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isSelected ? "Added" : "Add",
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 50).ms);
              },
            ),
          ),

          // Bottom Cart Bar
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${_cart.length} tests selected", style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.6), fontWeight: FontWeight.w500, fontSize: 12)),
                        Text("₹$_total", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _bookTests,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: accentPurple.withOpacity(0.3),
                        ),
                        child: Text("SCHEDULE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}
