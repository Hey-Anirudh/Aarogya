import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class MedicineOrderScreen extends StatefulWidget {
  const MedicineOrderScreen({super.key});

  @override
  State<MedicineOrderScreen> createState() => _MedicineOrderScreenState();
}

class _MedicineOrderScreenState extends State<MedicineOrderScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _medicines = [
    {'name': 'Paracetamol 500mg', 'type': 'Tablet', 'price': 25, 'icon': '💊', 'inStock': true},
    {'name': 'Azithromycin 250mg', 'type': 'Tablet', 'price': 120, 'icon': '💊', 'inStock': true},
    {'name': 'Cough Syrup (Adulsa)', 'type': 'Syrup', 'price': 85, 'icon': '🧪', 'inStock': true},
    {'name': 'Vitamin C Zinc', 'type': 'Tablet', 'price': 45, 'icon': '💊', 'inStock': true},
    {'name': 'Ibuprofen 400mg', 'type': 'Tablet', 'price': 35, 'icon': '💊', 'inStock': false},
    {'name': 'Amoxicillin 500mg', 'type': 'Capsule', 'price': 110, 'icon': '💊', 'inStock': true},
    {'name': 'ORS Powder Apple', 'type': 'Powder', 'price': 20, 'icon': '🧂', 'inStock': true},
    {'name': 'Antacid Liquid', 'type': 'Syrup', 'price': 95, 'icon': '🧪', 'inStock': true},
  ];

  final Set<String> _cart = {};
  double _total = 0;

  void _toggleCart(Map<String, dynamic> med) {
    if (!med['inStock']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This medicine is currently out of stock')),
      );
      return;
    }
    setState(() {
      if (_cart.contains(med['name'])) {
        _cart.remove(med['name']);
        _total -= med['price'];
      } else {
        _cart.add(med['name']);
        _total += med['price'];
      }
    });
  }

  void _placeOrder() {
    if (_cart.isEmpty) return;
    
    // Simulate order placement
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
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                "Order Placed!",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F2D26),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your medicines will be delivered from the nearest mobile clinic within 30 minutes.",
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
    const Color accentOrange = Color(0xFFD9A000);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Order Medicine", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: hospitalNavy),
      ),
      body: Column(
        children: [
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
                  hintText: "Search medicines...",
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ),

          // Upload Prescription Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [hospitalGreen, const Color(0xFF2D7A68)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: hospitalGreen.withOpacity(0.3),
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
                    child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Have a Prescription?", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text("Upload & we'll arrange it from the nearest mobile clinic.", style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Camera opened for prescription upload")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: hospitalGreen,
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
                Text("Available Medicines", style: GoogleFonts.outfit(color: hospitalNavy, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("Delivery in ~30m", style: GoogleFonts.outfit(color: accentOrange, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Medicine List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                final med = _medicines[index];
                if (_searchController.text.isNotEmpty &&
                    !med['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase())) {
                  return const SizedBox.shrink();
                }

                final isSelected = _cart.contains(med['name']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? hospitalGreen : Colors.black.withOpacity(0.05),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentOrange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(med['icon'], style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med['name'], style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("${med['type']} • ${med['inStock'] ? 'In Stock' : 'Out of Stock'}",
                                style: GoogleFonts.outfit(
                                  color: med['inStock'] ? hospitalNavy.withOpacity(0.5) : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("₹${med['price']}", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _toggleCart(med),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? hospitalGreen : (med['inStock'] ? hospitalNavy : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isSelected ? "Added" : "Add",
                                style: GoogleFonts.outfit(color: med['inStock'] ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12),
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
                        Text("${_cart.length} items added", style: GoogleFonts.outfit(color: hospitalNavy.withOpacity(0.6), fontWeight: FontWeight.w500, fontSize: 12)),
                        Text("₹$_total", style: GoogleFonts.outfit(color: hospitalNavy, fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: hospitalGreen.withOpacity(0.3),
                        ),
                        child: Text("PLACE ORDER", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
