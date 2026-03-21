import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:upi_india/upi_india.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isFirebaseInit = false;
  String errorMsg = "";
  
  try {
    // Direct Firebase Setup (No gray screen error)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDN_q_BcUTvSXkILqKIvO_FhYJ4jHSC-HY",
        appId: "1:225862888805:android:bbf4d06df8a0b57e6f058c",
        messagingSenderId: "225862888805",
        projectId: "bgmiuc-74295",
        databaseURL: "https://bgmiuc-74295-default-rtdb.firebaseio.com",
        storageBucket: "bgmiuc-74295.firebasestorage.app",
      ),
    );
    isFirebaseInit = true;
  } catch (e) {
    errorMsg = e.toString();
  }

  runApp(RooterShopApp(isInit: isFirebaseInit, error: errorMsg));
}

class RooterShopApp extends StatelessWidget {
  final bool isInit;
  final String error;
  const RooterShopApp({super.key, required this.isInit, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rooter SHOP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A), elevation: 0),
        cardColor: const Color(0xFF1A1A1A),
      ),
      home: isInit ? const AuthStateWrapper() : Scaffold(body: Center(child: Text("Error: $error"))),
    );
  }
}

// ================= AUTH WRAPPER =================
class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const AuthScreen();
      },
    );
  }
}

// ================= LOGIN / REGISTER =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      } else {
        UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        await FirebaseDatabase.instance.ref("users/${user.user!.uid}").set({'balance': 0, 'email': _email.text.trim()});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 10),
              const Text("Rooter SHOP", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(controller: _email, decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1A1A1A), hintText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _pass, obscureText: true, decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1A1A1A), hintText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 30),
              _isLoading 
                ? const CircularProgressIndicator() 
                : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _submit, child: Text(_isLogin ? "Login" : "Register", style: const TextStyle(fontSize: 18, color: Colors.white)))),
              TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "Create an account" : "I already have an account", style: const TextStyle(color: Colors.grey)))
            ],
          ),
        ),
      ),
    );
  }
}

// ================= HOME SCREEN (WITH DRAWER & BETTER UI) =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _balance = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      // LEFT SIDE DRAWER MENU (Logout here)
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_circle, size: 60, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(FirebaseAuth.instance.currentUser?.email ?? "User", style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.history), title: const Text('My Orders'), onTap: () {}),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('SHOP', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // WALLET BUTTON (Clickable for Top-up)
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref("users/$uid/balance").onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                _balance = (snapshot.data!.snapshot.value as num).toInt();
              }
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletTopupScreen())),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueAccent.withOpacity(0.5))),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text("₹$_balance", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.add_circle, size: 16, color: Colors.greenAccent), // Add money icon
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1A1A1A), hintText: 'Search for BGMI UC...', prefixIcon: const Icon(Icons.search, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none))),
          const SizedBox(height: 24),
          
          // FREE GOOGLE REDEEM CODES (Giveaway Section)
          const Text('🎁 Free Giveaways', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref("giveaways").limitToLast(1).onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                Map data = snapshot.data!.snapshot.value as Map;
                var key = data.keys.first;
                var codeData = data[key];
                return Card(
                  color: Colors.green.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.green)),
                  child: ListTile(
                    leading: const Icon(Icons.card_giftcard, color: Colors.greenAccent, size: 30),
                    title: const Text("Google Play Redeem Code", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(codeData['code'] ?? "XXXX-XXXX-XXXX", style: const TextStyle(color: Colors.greenAccent, letterSpacing: 2)),
                    trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code Copied!")));
                    }, child: const Text("COPY", style: TextStyle(color: Colors.white))),
                  ),
                );
              }
              // If admin hasn't posted a giveaway yet
              return Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.card_giftcard, color: Colors.grey),
                  title: Text("No active giveaways right now"),
                  subtitle: Text("Check back later for free redeem codes!"),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text('🔥 For You', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BgmiPacksScreen())),
                  child: _buildProductCard('BGMI UC', '10% Savings', Icons.gamepad),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildProductCard('Valorant Points', '17.8% Savings', Icons.computer)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String title, String subtitle, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 120, decoration: const BoxDecoration(color: Color(0xFF2A2A2A), borderRadius: BorderRadius.vertical(top: Radius.circular(16))), child: Center(child: Icon(icon, size: 50, color: Colors.blueAccent))),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= WALLET TOP-UP SCREEN =================
class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({super.key});
  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final UpiIndia _upi = UpiIndia();
  List<UpiApp>? _apps;
  final _amountController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _upi.getAllUpiApps(mandatoryTransactionId: false).then((value) {
      setState(() { _apps = value; _loading = false; });
    }).catchError((e) {
      setState(() => _loading = false);
    });
  }

  void _processTopup(UpiApp app) async {
    if (_amountController.text.isEmpty) return;
    int amount = int.parse(_amountController.text);
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimum top-up is ₹10")));
      return;
    }

    setState(() => _loading = true);
    try {
      UpiResponse res = await _upi.startTransaction(
        app: app,
        receiverUpiId: "8406962570@ybl", // Admin UPI ID
        receiverName: "Rooter Shop Wallet",
        transactionRefId: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount.toDouble(),
      );

      if (res.status == UpiPaymentStatus.SUCCESS) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        // Logic: Add money to wallet in Firebase
        final ref = FirebaseDatabase.instance.ref("users/$uid/balance");
        await ref.runTransaction((Object? current) {
          int bal = current == null ? 0 : (current as num).toInt();
          return Transaction.success(bal + amount);
        });
        
        // Save Top-up history for admin
        await FirebaseDatabase.instance.ref("topups").push().set({
          'uid': uid, 'amount': amount, 'method': app.name, 'txnId': res.transactionId, 'timestamp': ServerValue.timestamp
        });

        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wallet Recharge Successful!")));
           Navigator.pop(context);
        }
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Failed or Cancelled")));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Money to Wallet")),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(prefixText: "₹ ", filled: true, fillColor: const Color(0xFF1A1A1A), labelText: "Enter Amount", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 30),
            const Text("Pay using UPI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_apps != null) ..._apps!.map((a) => Card(
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                leading: Image.memory(a.icon, width: 30),
                title: Text(a.name),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _processTopup(a),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ================= BGMI PACKS SCREEN =================
class BgmiPacksScreen extends StatelessWidget {
  const BgmiPacksScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final packs = [{'uc': 60, 'price': 75}, {'uc': 300, 'extra': 25, 'price': 380}, {'uc': 600, 'extra': 60, 'price': 750}];
    return Scaffold(
      appBar: AppBar(title: const Text("Select Pack")),
      body: ListView.builder(
        itemCount: packs.length,
        itemBuilder: (context, index) {
          final p = packs[index];
          int total = p['uc']! + (p['extra'] ?? 0);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.monetization_on, color: Colors.amber, size: 36),
              title: Text("$total UC", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: p['extra'] != null ? Text("+ ${p['extra']} Bonus") : null,
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(uc: total, price: p['price']!))),
                child: Text("₹${p['price']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= DELIVERY DETAILS =================
class DeliveryDetailsScreen extends StatefulWidget {
  final int uc; final int price;
  const DeliveryDetailsScreen({super.key, required this.uc, required this.price});
  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final _idController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delivery Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _idController, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1A1A1A), labelText: "BGMI Game ID", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  if (_idController.text.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(price: widget.price, pack: "${widget.uc} UC", gameId: _idController.text.trim())));
                  }
                },
                child: Text("Proceed to Pay ₹${widget.price}", style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ================= DIRECT PAYMENT (ITEM PURCHASE) SCREEN =================
class PaymentScreen extends StatefulWidget {
  final int price; final String pack; final String gameId;
  const PaymentScreen({super.key, required this.price, required this.pack, required this.gameId});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final UpiIndia _upi = UpiIndia();
  List<UpiApp>? _apps;
  int _wallet = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseDatabase.instance.ref("users/$uid/balance").get();
    if (snap.exists) _wallet = (snap.value as num).toInt();
    _upi.getAllUpiApps(mandatoryTransactionId: false).then((v) { setState(() { _apps = v; _loading = false; }); }).catchError((e) { setState(() => _loading = false); });
  }

  void _payWithWallet() async {
    if (_wallet < widget.price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient Wallet Balance!")));
      return;
    }
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref();
    
    final res = await db.child("users/$uid/balance").runTransaction((current) {
      int bal = current == null ? 0 : (current as num).toInt();
      if (bal < widget.price) return Transaction.abort();
      return Transaction.success(bal - widget.price);
    });

    if (res.committed) {
      await db.child("orders").push().set({'uid': uid, 'gameId': widget.gameId, 'pack': widget.pack, 'price': widget.price, 'method': 'Wallet', 'status': 'Paid', 'timestamp': ServerValue.timestamp});
      _successDialog();
    } else {
      setState(() => _loading = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction Failed!")));
    }
  }

  void _payWithUPI(UpiApp app) async {
    setState(() => _loading = true);
    try {
      UpiResponse res = await _upi.startTransaction(
        app: app, receiverUpiId: "8406962570@ybl", receiverName: "Rooter Shop", transactionRefId: DateTime.now().millisecondsSinceEpoch.toString(), amount: widget.price.toDouble(),
      );
      if (res.status == UpiPaymentStatus.SUCCESS) {
        await FirebaseDatabase.instance.ref("orders").push().set({'uid': FirebaseAuth.instance.currentUser!.uid, 'gameId': widget.gameId, 'pack': widget.pack, 'price': widget.price, 'method': app.name, 'status': 'Paid', 'timestamp': ServerValue.timestamp});
        _successDialog();
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Failed or Cancelled")));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _loading = false);
  }

  void _successDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Text("Success ✅"), content: const Text("Order Placed Successfully!"),
      actions: [TextButton(onPressed: () { Navigator.pop(ctx); Navigator.popUntil(context, (r) => r.isFirst); }, child: const Text("OK"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Methods")),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Pay using Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Card(
            color: const Color(0xFF1A1A1A),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent, size: 30),
              title: const Text("Wallet Balance"),
              subtitle: Text("₹$_wallet", style: TextStyle(color: _wallet < widget.price ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _wallet >= widget.price ? Colors.blueAccent : Colors.grey),
                onPressed: _wallet >= widget.price ? _payWithWallet : null,
                child: const Text("Pay", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text("Direct UPI Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          if (_apps != null) ..._apps!.map((a) => Card(
            color: const Color(0xFF1A1A1A),
            child: ListTile(leading: Image.memory(a.icon, width: 30), title: Text(a.name), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => _payWithUPI(a)),
          )),
        ],
      ),
    );
  }
}
