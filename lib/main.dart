import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For some specific UI elements like BottomSheet
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const UCSellerApp());
}

class UCSellerApp extends StatelessWidget {
  const UCSellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'UC Shop',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: Color(0xFF0F0F0F),
      ),
      home: HomeScreen(),
    );
  }
}

// ================= HOME SCREEN =================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: const Icon(CupertinoIcons.bag_fill, color: CupertinoColors.activeBlue),
        middle: const Text('SHOP', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.sparkles, color: CupertinoColors.white),
              onPressed: () {},
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.wallet_pass, color: CupertinoColors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Search Bar
            CupertinoSearchTextField(
              backgroundColor: const Color(0xFF2A2A2A),
              placeholder: 'Search for BGMI UC, Valorant & more',
              style: const TextStyle(color: CupertinoColors.white),
            ),
            const SizedBox(height: 20),
            const Text('For You', style: TextStyle(color: CupertinoColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Products Grid
            Row(
              children: [
                Expanded(child: ProductCard(title: 'BGMI UC', subtitle: '10% Savings', imageIcon: CupertinoIcons.game_controller_solid, onTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => const DetailsScreen()));
                })),
                const SizedBox(width: 16),
                Expanded(child: ProductCard(title: 'Valorant Points', subtitle: '17.8% Savings', imageIcon: CupertinoIcons.desktopcomputer)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData imageIcon;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.title, required this.subtitle, required this.imageIcon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF333333),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Icon(imageIcon, size: 50, color: CupertinoColors.systemGrey),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: CupertinoColors.activeBlue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= DETAILS SCREEN =================
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TextEditingController _gameIdController = TextEditingController();
  bool _saveDetails = true;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF1A1A1A),
        middle: Text('BGMI UC', style: TextStyle(color: CupertinoColors.white)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Banner Area
                  Container(
                    height: 150,
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text("10% Cashback on BGMI UC", style: TextStyle(color: CupertinoColors.white))),
                  ),
                  const SizedBox(height: 20),
                  const Text('Delivery Details', style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Game ID Input (iOS Style)
                  CupertinoTextField(
                    controller: _gameIdController,
                    placeholder: 'Enter BGMI gaming id',
                    placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
                    style: const TextStyle(color: CupertinoColors.white),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
                    suffix: CupertinoButton(
                      padding: const EdgeInsets.only(right: 16),
                      child: const Text('Verify', style: TextStyle(color: CupertinoColors.systemGrey)),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Save Details Checkbox Row
                  Row(
                    children: [
                      CupertinoSwitch(
                        value: _saveDetails,
                        onChanged: (val) => setState(() => _saveDetails = val),
                        activeColor: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 8),
                      const Text('Save Details for future deliveries', style: TextStyle(color: CupertinoColors.white)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bottom Pay Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(top: BorderSide(color: Color(0xFF333333))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  child: const Text('Pay ₹75'),
                  onPressed: () {
                    if (_gameIdController.text.isEmpty) {
                      // Basic Validation
                      return;
                    }
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => const PaymentScreen()));
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ================= PAYMENT SCREEN =================
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF1A1A1A),
        middle: Text('Payment Methods', style: TextStyle(color: CupertinoColors.white)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('UPI', style: TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentOption(context, 'Google Pay', 'gpay_icon'),
            _buildPaymentOption(context, 'Paytm', 'paytm_icon'),
            _buildPaymentOption(context, 'PhonePe', 'phonepe_icon'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, String title, String iconPlaceholder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoListTile(
        title: Text(title, style: const TextStyle(color: CupertinoColors.white)),
        leading: const Icon(CupertinoIcons.money_dollar_circle, color: CupertinoColors.systemGrey),
        trailing: const Icon(CupertinoIcons.circle, color: CupertinoColors.systemGrey),
        onTap: () {
          // Yaha aap real UPI Deep Linking ya Payment Gateway ka code lagayenge
          _showSuccessDialog(context);
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Payment Processing'),
        content: const Text('Integrate Razorpay / UPI intent here.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to details
            },
          )
        ],
      ),
    );
  }
}
