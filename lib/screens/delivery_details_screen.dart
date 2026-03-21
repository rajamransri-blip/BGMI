import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'payment_methods_screen.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final int selectedUC;
  final int price;
  const DeliveryDetailsScreen({super.key, required this.selectedUC, required this.price});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final _gameIdController = TextEditingController();
  bool _isVerified = false;
  bool _isLoading = false;
  bool _saveDetails = true;

  void _verifyId() async {
    if (_gameIdController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    // Simulate verification
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _isVerified = true;
    });
  }

  void _proceedToPay() {
    if (!_isVerified) {
      showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(title: const Text("Error"), content: const Text("Please verify your BGMI Game Id first."), actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(ctx))]));
      return;
    }
    // Navigate to payment screen
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PaymentMethodsScreen(price: widget.price, ucPack: "${widget.selectedUC} UC", gameId: _gameIdController.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Delivery Details")),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Replication of image_2.png UI
                  const Text("Delivery Details", style: TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("BGMI Game Id", style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12)),
                  const SizedBox(height: 8),
                  
                  CupertinoTextField(
                    controller: _gameIdController,
                    placeholder: "Enter BGMI gaming id",
                    placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
                    style: const TextStyle(color: CupertinoColors.white),
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8), border: Border.all(color: _isVerified ? CupertinoColors.activeGreen : const Color(0xFF333333))),
                    suffix: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _isLoading ? const CupertinoActivityIndicator() : Text(_isVerified ? "Verified ✅" : "Verify", style: TextStyle(color: _isVerified ? CupertinoColors.activeGreen : CupertinoColors.activeBlue)),
                      onPressed: _verifyId,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CupertinoCheckbox(value: _saveDetails, onChanged: (v) => setState(() => _saveDetails = v!)),
                      const SizedBox(width: 8),
                      const Text("Save Details for future deliveries", style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12))
                    ],
                  ),
                ],
              ),
            ),
            // Bottom fixed pay button from image_2.png
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total: ₹${widget.price}", style: const TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${widget.selectedUC} UC", style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: CupertinoButton.filled(onPressed: _proceedToPay, child: Text("Pay ₹${widget.price}"))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
