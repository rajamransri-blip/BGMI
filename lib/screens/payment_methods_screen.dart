import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:upi_india/upi_india.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final int price;
  final String ucPack;
  final String gameId;
  const PaymentMethodsScreen({super.key, required this.price, required this.ucPack, required this.gameId});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final UpiIndia _upiIndia = UpiIndia();
  List<UpiApp>? _upiApps;
  bool _isLoadingWallet = true;
  bool _insufficientWallet = false;
  int _walletBalance = 0;
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _checkWalletAndUPI();
  }

  void _checkWalletAndUPI() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseDatabase.instance.ref("users/$uid/balance").get();
    if (snapshot.exists) {
      _walletBalance = (snapshot.value as num).toInt();
      if (_walletBalance < widget.price) {
        _insufficientWallet = true;
      }
    } else {
      _insufficientWallet = true;
    }

    try {
      final apps = await _upiIndia.getAllUpiApps(mandatoryTransactionId: false);
      setState(() {
        _upiApps = apps;
        _isLoadingWallet = false;
      });
    } catch (e) {
      setState(() => _isLoadingWallet = false);
    }
  }

  void _processWalletPayment() async {
    setState(() => _isLoadingWallet = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final databaseRef = FirebaseDatabase.instance.ref();
    
    final transactionResult = await databaseRef.child("users/$uid/balance").runTransaction((Object? currentBalance) {
      if (currentBalance == null) return Transaction.abort();
      int current = (currentBalance as num).toInt();
      if (current < widget.price) return Transaction.abort();
      return Transaction.success(current - widget.price);
    });

    if (transactionResult.committed) {
      await databaseRef.child("orders").push().set({
        'uid': uid,
        'gameId': widget.gameId,
        'pack': widget.ucPack,
        'price': widget.price,
        'method': 'Wallet',
        'status': 'Processing',
        'timestamp': ServerValue.timestamp
      });
      _showSuccess();
    } else {
      _showError("Wallet transaction failed. Maybe insufficient funds.");
    }
    setState(() => _isLoadingWallet = false);
  }

  void _processUPIPayment(UpiApp app) async {
    setState(() => _isLoadingWallet = true);
    final txnId = DateTime.now().millisecondsSinceEpoch.toString();
    UpiResponse? response;
    try {
      response = await _upiIndia.startTransaction(
        app: app,
        receiverUpiId: "8406962570@ybl",
        receiverName: "Rooter Shop BGMI UC",
        transactionRefId: txnId,
        transactionNote: "BGMI UC Pack: ${widget.ucPack} for Game ID: ${widget.gameId}",
        amount: widget.price.toDouble(),
      );
    } catch (e) {
      response = null;
      _showError("UPI Transaction init failed: $e");
    }
    
    setState(() => _isLoadingWallet = false);

    if (response == null) return;

    // FIX 1: USER_CANCELLED hata kar default laga diya
    switch (response.status) {
      case UpiPaymentStatus.SUCCESS:
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseDatabase.instance.ref("orders").push().set({
          'uid': uid,
          'gameId': widget.gameId,
          'pack': widget.ucPack,
          'price': widget.price,
          'method': "UPI - ${app.name}",
          'status': 'Processing (UPI Txn: ${response.transactionId})',
          'timestamp': ServerValue.timestamp
        });
        _showSuccess();
        break;
      case UpiPaymentStatus.SUBMITTED:
        _showInfo("Payment Submitted. Awaiting bank confirmation.");
        break;
      case UpiPaymentStatus.FAILURE:
        _showError("Payment Failed: ${response.approvalRefNo}");
        break;
      default:
        _showInfo("Payment Cancelled or Unknown Status.");
        break;
    }
  }

  void _showSuccess() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Success ✅"),
        content: const Text("Order placed successfully! UC will be delivered soon."),
        actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        })],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(title: const Text("Error"), content: Text(message), actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(ctx))]));
  }

  void _showInfo(String message) {
    showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(title: const Text("Info"), content: Text(message), actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(ctx))]));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Payment Methods")),
      child: SafeArea(
        child: _isLoadingWallet 
          ? const Center(child: CupertinoActivityIndicator())
          : Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Shopping Card", style: TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Material(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: _insufficientWallet ? CupertinoColors.destructiveRed : const Color(0xFF333333))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.creditcard_fill, color: CupertinoColors.activeBlue, size: 30),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Rooter Shopping Card", style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                                    Text("Available Balance: ₹$_walletBalance", style: TextStyle(color: _insufficientWallet ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (!_insufficientWallet) CupertinoButton(padding: EdgeInsets.zero, child: Text(_selectedMethod == 'Wallet' ? 'Selected ✅' : 'Pay Using Wallet'), onPressed: () => setState(() => _selectedMethod = 'Wallet')),
                            ],
                          ),
                          // FIX 2: EdgeInsets.only(top: 12) kar diya gaya hai
                          if (_insufficientWallet) const Padding(padding: EdgeInsets.only(top: 12), child: Text("Not enough balance to purchase this product.", style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("UPI", style: TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_upiApps == null || _upiApps!.isEmpty) const Center(child: Text("No UPI Apps Installed", style: TextStyle(color: CupertinoColors.systemGrey)))
                  else Column(
                    children: _upiApps!.map((app) => Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: _selectedMethod == "upi_${app.name}" ? CupertinoColors.activeBlue : const Color(0xFF333333))),
                        child: ListTile(
                          leading: Image.memory(app.icon, width: 30, height: 30),
                          title: Text(app.name, style: const TextStyle(color: CupertinoColors.white)),
                          trailing: const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey),
                          onTap: () => setState(() => _selectedMethod = "upi_${app.name}"),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1A1A1A),
                  child: Row(
                    children: [
                      // FIX 3: shippingbox ko cube_box kar diya gaya hai
                      const Icon(CupertinoIcons.cube_box, color: CupertinoColors.activeBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.gameId, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text("Pay ₹${widget.price}"),
                        onPressed: () {
                          if (_selectedMethod == 'Wallet') {
                            _processWalletPayment();
                          } else if (_selectedMethod != null && _selectedMethod!.startsWith("upi_")) {
                            final appName = _selectedMethod!.substring(4);
                            final app = _upiApps!.firstWhere((a) => a.name == appName);
                            _processUPIPayment(app);
                          } else {
                            _showError("Please select a payment method.");
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
}
