import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Error: $e");
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
              // Icon fixed from wallet_pass to creditcard
              child: const Icon(CupertinoIcons.creditcard, color: CupertinoColors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const CupertinoSearchTextField(
              backgroundColor: Color(0xFF2A2A2A),
              placeholder: 'Search for BGMI UC, Valorant & more',
              style: TextStyle(color: CupertinoColors.white),
            ),
            const SizedBox(height: 20),
            const Text('For You', style: TextStyle(color: CupertinoColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ProductCard(
                    title: 'BGMI UC', 
                    subtitle: '10% Savings', 
                    imageIcon: CupertinoIcons.game_controller_solid, 
                    onTap: () {
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => const DetailsScreen()));
                    }
                  )
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: ProductCard(
                    title: 'Valorant Points', 
                    subtitle: '17.8% Savings', 
                    imageIcon: CupertinoIcons.desktopcomputer
                  )
                ),
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
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
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

  void _proceedToPay() {
    if (_gameIdController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a valid BGMI Game ID.'),
          actions: [
            CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))
          ],
        ),
      );
      return;
    }
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => PaymentScreen(gameId: _gameIdController.text.trim())
    ));
  }

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
                  Container(
                    height: 150,
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text("10% Cashback on BGMI UC", style: TextStyle(color: CupertinoColors.white))),
                  ),
                  const SizedBox(height: 20),
                  const Text('Delivery Details', style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _gameIdController,
                    placeholder: 'Enter BGMI gaming id',
                    placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
                    style: const TextStyle(color: CupertinoColors.white),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
                  ),
                  const SizedBox(height: 16),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(top: BorderSide(color: Color(0xFF333333))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _proceedToPay,
                  child: const Text('Pay ₹75'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ================= PAYMENT SCREEN (WITH FIREBASE) =================
class PaymentScreen extends StatefulWidget {
  final String gameId;
  const PaymentScreen({super.key, required this.gameId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  Future<void> _processPayment(String method) async {
    setState(() => _isProcessing = true);

    try {
      // 1. Database reference
      final databaseRef = FirebaseDatabase.instance.ref("orders");
      
      // 2. Data save karna Firebase me
      await databaseRef.push().set({
        "game_id": widget.gameId,
        "amount": "₹75",
        "payment_method": method,
        "status": "pending", // Ise 'success' kar sakte hain real payment ke baad
        "timestamp": DateTime.now().toIso8601String(),
      });

      // 3. Success Message
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Order Placed!'),
            content: Text('Your order for Game ID: ${widget.gameId} has been saved to Firebase.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to Details
                  Navigator.pop(context); // Go back to Home
                },
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save order: $e'),
            actions: [
              CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF1A1A1A),
        middle: Text('Payment Methods', style: TextStyle(color: CupertinoColors.white)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('UPI', style: TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPaymentOption('Google Pay'),
                _buildPaymentOption('Paytm'),
                _buildPaymentOption('PhonePe'),
              ],
            ),
            if (_isProcessing)
              Container(
                color: CupertinoColors.black.withOpacity(0.5),
                child: const Center(
                  child: CupertinoActivityIndicator(radius: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
      child: CupertinoListTile(
        title: Text(title, style: const TextStyle(color: CupertinoColors.white)),
        leading: const Icon(CupertinoIcons.money_dollar_circle, color: CupertinoColors.systemGrey),
        trailing: const Icon(CupertinoIcons.circle, color: CupertinoColors.systemGrey),
        onTap: () => _processPayment(title),
      ),
    );
  }
}
