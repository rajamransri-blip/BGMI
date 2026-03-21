import 'package:flutter/cupertino.dart';
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
    await Firebase.initializeApp();
    isFirebaseInit = true;
  } catch (e) {
    errorMsg = e.toString();
    debugPrint("Firebase Error: $e");
  }

  runApp(RooterShopApp(isInitialized: isFirebaseInit, error: errorMsg));
}

class RooterShopApp extends StatelessWidget {
  final bool isInitialized;
  final String error;
  
  const RooterShopApp({super.key, required this.isInitialized, required this.error});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Rooter SHOP',
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: Color(0xFF0F0F0F),
      ),
      home: isInitialized 
          ? const AuthStateWrapper() 
          : _buildErrorScreen(error),
    );
  }

  Widget _buildErrorScreen(String error) {
    return CupertinoPageScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.destructiveRed, size: 60),
              const SizedBox(height: 20),
              const Text("Firebase Setup Error", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
              const SizedBox(height: 10),
              Text("Error: $error\n\nShayad android/app/ folder me google-services.json file missing hai.", textAlign: TextAlign.center, style: const TextStyle(color: CupertinoColors.systemGrey)),
            ],
          ),
        ),
      ),
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
          return const CupertinoPageScaffold(child: Center(child: CupertinoActivityIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const AuthScreen();
      },
    );
  }
}

// ================= AUTH (LOGIN/REGISTER) SCREEN =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      } else {
        UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
        await FirebaseDatabase.instance.ref("users/${user.user!.uid}").set({'balance': 0, 'email': _emailController.text.trim()});
      }
    } catch (e) {
      _showError(e.toString());
    }
    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(title: const Text("Error"), content: Text(msg), actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(ctx))]));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Login / Register")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Rooter SHOP", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
              const SizedBox(height: 32),
              CupertinoTextField(controller: _emailController, placeholder: "Email", keyboardType: TextInputType.emailAddress, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 12),
              CupertinoTextField(controller: _passwordController, placeholder: "Password", obscureText: true, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 24),
              _isLoading ? const CupertinoActivityIndicator() : CupertinoButton.filled(onPressed: _submit, child: Text(_isLogin ? "Login" : "Register")),
              CupertinoButton(child: Text(_isLogin ? "Create an account" : "I already have an account"), onPressed: () => setState(() => _isLogin = !_isLogin)),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= HOME SCREEN =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _balance = 0;
  late Stream<DatabaseEvent> _balanceStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _balanceStream = FirebaseDatabase.instance.ref("users/$uid/balance").onValue;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF1A1A1A),
        activeColor: CupertinoColors.activeBlue,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube), label: 'Orders'),
        ],
      ),
      tabBuilder: (context, index) {
        if (index == 1) return const OrdersScreen(); // Simple orders screen placeholder
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: const Color(0xFF1A1A1A),
            leading: const Icon(CupertinoIcons.bag_fill, color: CupertinoColors.activeBlue),
            middle: const Text('SHOP', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
            trailing: StreamBuilder<DatabaseEvent>(
              stream: _balanceStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  _balance = (snapshot.data!.snapshot.value as num).toInt();
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.creditcard, size: 16, color: CupertinoColors.white),
                      const SizedBox(width: 4),
                      Text("₹$_balance", style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const CupertinoSearchTextField(backgroundColor: Color(0xFF1A1A1A), placeholder: 'Search for BGMI UC...'),
                const SizedBox(height: 20),
                const Text('For You', style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const BgmiPacksScreen())),
                        child: _buildCard('BGMI UC', '10% Savings', CupertinoIcons.game_controller_solid),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCard('Valorant Points', '17.8% Savings', CupertinoIcons.desktopcomputer)),
                  ],
                ),
                const SizedBox(height: 30),
                CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  child: const Text("Logout"),
                  onPressed: () => FirebaseAuth.instance.signOut(),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 100, decoration: const BoxDecoration(color: Color(0xFF333333), borderRadius: BorderRadius.vertical(top: Radius.circular(16))), child: Center(child: Icon(icon, size: 40, color: CupertinoColors.systemGrey))),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: CupertinoColors.activeBlue, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= BGMI PACKS SCREEN =================
class BgmiPacksScreen extends StatelessWidget {
  const BgmiPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = [
      {'uc': 60, 'price': 75},
      {'uc': 300, 'extra': 25, 'price': 380},
      {'uc': 600, 'extra': 60, 'price': 750},
    ];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Select BGMI UC Pack")),
      child: SafeArea(
        child: ListView.separated(
          itemCount: packs.length,
          separatorBuilder: (_, __) => const Divider(color: Color(0xFF333333), height: 1),
          itemBuilder: (context, index) {
            final p = packs[index];
            int total = p['uc']! + (p['extra'] ?? 0);
            return Material(
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                leading: const Icon(CupertinoIcons.money_dollar_circle, color: Color(0xFFFFD700), size: 30),
                title: Text("$total UC", style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                trailing: Text("₹${p['price']}", style: const TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => DeliveryDetailsScreen(uc: total, price: p['price']!))),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================= DELIVERY DETAILS (GAME ID) =================
class DeliveryDetailsScreen extends StatefulWidget {
  final int uc;
  final int price;
  const DeliveryDetailsScreen({super.key, required this.uc, required this.price});
  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final _idController = TextEditingController();

  void _pay() {
    if (_idController.text.isEmpty) return;
    Navigator.push(context, CupertinoPageRoute(builder: (_) => PaymentScreen(price: widget.price, pack: "${widget.uc} UC", gameId: _idController.text.trim())));
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
                  const Text("BGMI Game Id", style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  CupertinoTextField(controller: _idController, placeholder: "Enter Game ID", keyboardType: TextInputType.number, style: const TextStyle(color: CupertinoColors.white), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A1A),
              child: SizedBox(width: double.infinity, child: CupertinoButton.filled(onPressed: _pay, child: Text("Pay ₹${widget.price}"))),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= PAYMENT SCREEN (UPI & WALLET) =================
class PaymentScreen extends StatefulWidget {
  final int price;
  final String pack;
  final String gameId;
  const PaymentScreen({super.key, required this.price, required this.pack, required this.gameId});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final UpiIndia _upi = UpiIndia();
  List<UpiApp>? _apps;
  String? _selected;
  bool _loading = true;
  int _wallet = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseDatabase.instance.ref("users/$uid/balance").get();
    if (snap.exists) _wallet = (snap.value as num).toInt();
    try {
      _apps = await _upi.getAllUpiApps(mandatoryTransactionId: false);
    } catch (e) {
      debugPrint("UPI Error: $e");
    }
    setState(() => _loading = false);
  }

  void _processUPI(UpiApp app) async {
    setState(() => _loading = true);
    try {
      UpiResponse res = await _upi.startTransaction(
        app: app,
        receiverUpiId: "8406962570@ybl",
        receiverName: "Rooter Shop",
        transactionRefId: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: widget.price.toDouble(),
      );
      if (res.status == UpiPaymentStatus.SUCCESS) {
        await FirebaseDatabase.instance.ref("orders").push().set({'uid': FirebaseAuth.instance.currentUser!.uid, 'gameId': widget.gameId, 'pack': widget.pack, 'price': widget.price, 'method': app.name, 'status': 'Paid'});
        _showDialog("Success", "Order Placed!");
      } else {
        _showDialog("Failed", "Payment not completed.");
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    }
    setState(() => _loading = false);
  }

  void _showDialog(String title, String msg) {
    showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(title: Text(title), content: Text(msg), actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () { Navigator.pop(ctx); if (title == "Success") Navigator.popUntil(context, (r) => r.isFirst); })]));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Payment")),
      child: SafeArea(
        child: _loading ? const Center(child: CupertinoActivityIndicator()) : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Wallet", style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Material(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), child: ListTile(leading: const Icon(CupertinoIcons.creditcard, color: CupertinoColors.activeBlue), title: const Text("Pay using Wallet", style: TextStyle(color: CupertinoColors.white)), subtitle: Text("Bal: ₹$_wallet", style: TextStyle(color: _wallet < widget.price ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey)), onTap: () => setState(() => _selected = 'wallet'), trailing: _selected == 'wallet' ? const Icon(CupertinoIcons.check_mark_circled, color: CupertinoColors.activeBlue) : null)),
            const SizedBox(height: 24),
            const Text("UPI", style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_apps != null) ..._apps!.map((a) => Material(color: const Color(0xFF1A1A1A), child: ListTile(leading: Image.memory(a.icon, width: 30), title: Text(a.name, style: const TextStyle(color: CupertinoColors.white)), onTap: () => setState(() => _selected = a.name), trailing: _selected == a.name ? const Icon(CupertinoIcons.check_mark_circled, color: CupertinoColors.activeBlue) : null))),
            const SizedBox(height: 40),
            CupertinoButton.filled(
              child: Text("Pay ₹${widget.price}"),
              onPressed: () {
                if (_selected == null) return _showDialog("Select", "Choose a payment method");
                if (_selected == 'wallet') {
                  if (_wallet < widget.price) return _showDialog("Error", "Low balance");
                  // Add wallet deduction logic here
                } else {
                  _processUPI(_apps!.firstWhere((a) => a.name == _selected));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

// ================= ORDERS SCREEN PLACEHOLDER =================
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(navigationBar: CupertinoNavigationBar(middle: Text("My Orders")), child: Center(child: Text("No Orders Yet", style: TextStyle(color: CupertinoColors.systemGrey))));
  }
}
