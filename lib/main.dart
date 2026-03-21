import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:upi_india/upi_india.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isInit = false;
  String errorMsg = '';

  try {
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
    isInit = true;
  } catch (e) {
    errorMsg = e.toString();
  }

  runApp(MyApp(isInit: isInit, error: errorMsg));
}

class MyApp extends StatelessWidget {
  final bool isInit;
  final String error;
  const MyApp({super.key, required this.isInit, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rooter SHOP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF3B30),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardTheme(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
        ),
      ),
      home: isInit ? const AuthWrapper() : Scaffold(body: Center(child: Text("Error: $error"))),
    );
  }
}

// ================= AUTH WRAPPER =================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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

// ================= AUTH SCREEN =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _emailPasswordSubmit() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      _showSnackbar("Please fill all fields");
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _pass.text.trim(),
        );
      } else {
        UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _pass.text.trim(),
        );
        await FirebaseDatabase.instance.ref("users/${user.user!.uid}").set({
          'balance': 0,
          'email': _email.text.trim(),
          'createdAt': ServerValue.timestamp,
        });
        _showSnackbar("Account created! Please login.");
        setState(() => _isLogin = true);
      }
    } catch (e) {
      _showSnackbar(e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final userRef = FirebaseDatabase.instance.ref("users/${userCred.user!.uid}");
      final snap = await userRef.get();
      if (!snap.exists) {
        await userRef.set({
          'balance': 0,
          'email': userCred.user!.email,
          'createdAt': ServerValue.timestamp,
        });
      }
    } catch (e) {
      _showSnackbar("Google Sign-In failed: ${e.toString()}\n\nMake sure you've added SHA-1 fingerprint in Firebase Console.");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGitHub() async {
    setState(() => _isLoading = true);
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GitHubOAuthWebView()),
      );
      if (result != null && result is String) {
        _showSnackbar("GitHub sign-in requires a backend to exchange the code.");
      } else {
        _showSnackbar("GitHub sign-in cancelled.");
      }
    } catch (e) {
      _showSnackbar("GitHub Sign-In failed: ${e.toString()}");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _animationController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag, size: 80, color: Color(0xFFFF3B30)),
                  const SizedBox(height: 12),
                  const Text("Rooter SHOP", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "Password",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _emailPasswordSubmit,
                            child: Text(_isLogin ? "Sign In" : "Create Account"),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata),
                            label: const Text("Continue with Google"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF8E8E93)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _signInWithGitHub,
                            icon: const Icon(Icons.code),
                            label: const Text("Continue with GitHub"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF8E8E93)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? "Don't have an account? Sign up" : "Already have an account? Sign in",
                      style: const TextStyle(color: Color(0xFF8E8E93)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= GITHUB OAuth WEBVIEW =================
class GitHubOAuthWebView extends StatefulWidget {
  const GitHubOAuthWebView({super.key});
  @override
  State<GitHubOAuthWebView> createState() => _GitHubOAuthWebViewState();
}

class _GitHubOAuthWebViewState extends State<GitHubOAuthWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final clientId = 'YOUR_GITHUB_CLIENT_ID';
    final redirectUri = Uri.encodeComponent('https://bgmiuc-74295.firebaseapp.com/__/auth/handler');
    final authUrl = 'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&scope=user:email';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            if (url.contains('code=')) {
              final code = Uri.parse(url).queryParameters['code'];
              if (code != null) Navigator.pop(context, code);
            }
          },
          onPageFinished: (String url) => setState(() => _isLoading = false),
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GitHub Sign In")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Error: $_error"),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Go Back"),
                  ),
                ],
              ),
            ),
        ],
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _balance = 0;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      drawer: _buildPremiumDrawer(),
      appBar: AppBar(
        title: const Text("SHOP"),
        actions: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 18),
                      const SizedBox(width: 6),
                      Text("₹$_balance", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.add_circle, size: 16, color: Colors.greenAccent),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: "Search for BGMI UC...",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Color(0xFF1C1C1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
              ),
            ),
            const SizedBox(height: 24),
            const Text("🎁 Free Giveaways", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref("giveaways").limitToLast(1).onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map data = snapshot.data!.snapshot.value as Map;
                  var key = data.keys.first;
                  var codeData = data[key];
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade900.withOpacity(0.3), Colors.black.withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.5)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.card_giftcard, color: Color(0xFFFF3B30), size: 30),
                      title: const Text("Google Play Redeem Code", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(codeData['code'] ?? "XXXX-XXXX-XXXX", style: const TextStyle(color: Colors.greenAccent, letterSpacing: 2)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code Copied!")));
                        },
                        child: const Text("COPY"),
                      ),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade900.withOpacity(0.3), Colors.black.withOpacity(0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.card_giftcard, color: Colors.grey),
                    title: Text("No active giveaways"),
                    subtitle: Text("Check back later for free codes!"),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text("🔥 BGMI UC Packs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._buildPackCards(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPackCards() {
    final packs = [
      {'uc': 60, 'price': 75, 'discount': 0},
      {'uc': 300, 'extra': 25, 'price': 380, 'discount': 12},
      {'uc': 600, 'extra': 60, 'price': 750, 'discount': 18},
      {'uc': 1500, 'extra': 225, 'price': 1800, 'discount': 35},
      {'uc': 3000, 'extra': 600, 'price': 3200, 'discount': 59},
    ];

    return packs.map((pack) {
      int total = pack['uc']! + (pack['extra'] ?? 0);
      int discount = pack['discount']!;
      int originalPrice = pack['price']!;
      int discountedPrice = discount > 0 ? (originalPrice * (100 - discount) / 100).round() : originalPrice;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade900.withOpacity(0.3), Colors.black.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.5)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryDetailsScreen(
                    uc: total,
                    price: discountedPrice,
                    packName: "$total UC",
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$total UC",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (pack['extra'] != null)
                          Text("+ ${pack['extra']} Bonus", style: const TextStyle(color: Colors.greenAccent)),
                        if (discount > 0)
                          Row(
                            children: [
                              Text("₹$originalPrice", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text("-$discount%", style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "₹$discountedPrice",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPremiumDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF3B30), Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_circle, size: 80, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? "User",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(Icons.home, "Home", () => Navigator.pop(context)),
            _buildDrawerItem(Icons.history, "My Orders", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
            }),
            const Divider(color: Color(0xFF2C2C2E), thickness: 1),
            _buildDrawerItem(Icons.logout, "Logout", () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            }, isRed: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isRed = false}) {
    return ListTile(
      leading: Icon(icon, color: isRed ? Colors.redAccent : const Color(0xFFFF3B30)),
      title: Text(title, style: TextStyle(color: isRed ? Colors.redAccent : Colors.white)),
      onTap: onTap,
    );
  }
}

// ================= DELIVERY DETAILS =================
class DeliveryDetailsScreen extends StatefulWidget {
  final int uc;
  final int price;
  final String packName;
  const DeliveryDetailsScreen({super.key, required this.uc, required this.price, required this.packName});
  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final _idController = TextEditingController();
  bool _saveDetails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delivery Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "BGMI Game ID",
                hintText: "Enter your Player ID",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _saveDetails,
                  onChanged: (val) => setState(() => _saveDetails = val ?? false),
                ),
                const Text("Save details for future deliveries"),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_idController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Game ID")));
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        price: widget.price,
                        pack: widget.packName,
                        gameId: _idController.text.trim(),
                      ),
                    ),
                  );
                },
                child: Text("Proceed to Pay ₹${widget.price}"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= PAYMENT SCREEN =================
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
  int _wallet = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseDatabase.instance.ref("users/$uid/balance").get();
    if (snap.exists) _wallet = (snap.value as num).toInt();
    try {
      final apps = await _upi.getAllUpiApps(mandatoryTransactionId: false);
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _payWithWallet() async {
    if (_wallet < widget.price) {
      _showSnackbar("Insufficient Wallet Balance!");
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
      await db.child("orders").push().set({
        'uid': uid,
        'gameId': widget.gameId,
        'pack': widget.pack,
        'price': widget.price,
        'method': 'Wallet',
        'status': 'Pending',
        'timestamp': ServerValue.timestamp,
      });
      if (mounted) _showSuccessDialog();
    } else {
      setState(() => _loading = false);
      _showSnackbar("Transaction Failed!");
    }
  }

  Future<void> _payWithUPI(UpiApp app) async {
    setState(() => _loading = true);
    try {
      UpiResponse res = await _upi.startTransaction(
        app: app,
        receiverUpiId: "paynearby.8406962570@indus",
        receiverName: "Rooter Shop",
        transactionRefId: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: widget.price.toDouble(),
      );
      if (res.status == UpiPaymentStatus.SUCCESS) {
        await FirebaseDatabase.instance.ref("orders").push().set({
          'uid': FirebaseAuth.instance.currentUser!.uid,
          'gameId': widget.gameId,
          'pack': widget.pack,
          'price': widget.price,
          'method': app.name,
          'status': 'Pending',
          'timestamp': ServerValue.timestamp,
        });
        if (mounted) _showSuccessDialog();
      } else {
        _showSnackbar("Payment Failed or Cancelled");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    }
    setState(() => _loading = false);
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Success"),
        content: const Text("Your order has been placed successfully."),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Methods")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("Pay using Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                Card(
                  color: const Color(0xFF1C1C1E),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet, color: Color(0xFFFF3B30), size: 30),
                    title: const Text("Wallet Balance"),
                    subtitle: Text(
                      "₹$_wallet",
                      style: TextStyle(
                        color: _wallet < widget.price ? Colors.redAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: _wallet >= widget.price ? _payWithWallet : null,
                      child: const Text("Pay"),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Direct UPI Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                if (_apps != null)
                  ..._apps!.map((a) => Card(
                        color: const Color(0xFF1C1C1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Image.memory(a.icon, width: 30),
                          title: Text(a.name),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _payWithUPI(a),
                        ),
                      )),
              ],
            ),
    );
  }
}

// ================= WALLET TOP-UP =================
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
    _loadUpiApps();
  }

  Future<void> _loadUpiApps() async {
    try {
      final apps = await _upi.getAllUpiApps(mandatoryTransactionId: false);
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _processTopup(UpiApp app) async {
    if (_amountController.text.isEmpty) {
      _showSnackbar("Enter amount");
      return;
    }
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount < 10) {
      _showSnackbar("Minimum top-up is ₹10");
      return;
    }

    setState(() => _loading = true);
    try {
      UpiResponse res = await _upi.startTransaction(
        app: app,
        receiverUpiId: "paynearby.8406962570@indus",
        receiverName: "Rooter Shop",
        transactionRefId: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount.toDouble(),
      );

      if (res.status == UpiPaymentStatus.SUCCESS) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final ref = FirebaseDatabase.instance.ref("users/$uid/balance");
        await ref.runTransaction((Object? current) {
          int bal = current == null ? 0 : (current as num).toInt();
          return Transaction.success(bal + amount);
        });

        await FirebaseDatabase.instance.ref("transactions").push().set({
          'uid': uid,
          'type': 'wallet_topup',
          'amount': amount,
          'method': app.name,
          'txnId': res.transactionId,
          'timestamp': ServerValue.timestamp,
          'approved': true,
        });

        if (mounted) {
          _showSnackbar("Wallet Recharge Successful!");
          Navigator.pop(context);
        }
      } else {
        _showSnackbar("Payment Failed or Cancelled");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    }
    setState(() => _loading = false);
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Money to Wallet")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      prefixText: "₹ ",
                      labelText: "Enter Amount",
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text("Pay using UPI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_apps != null)
                    ..._apps!.map((a) => Card(
                          color: const Color(0xFF1C1C1E),
                          margin: const EdgeInsets.only(bottom: 12),
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

// ================= ORDER HISTORY =================
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref("orders").orderByChild("uid").equalTo(uid).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No orders yet", style: TextStyle(fontSize: 18)),
                  Text("Start shopping to see your orders here"),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> orders = snapshot.data!.snapshot.value as Map;
          List<MapEntry> entries = orders.entries.toList();
          entries.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (ctx, index) {
              var orderId = entries[index].key;
              var data = entries[index].value;
              String status = data['status'] ?? "Pending";
              return Card(
                color: const Color(0xFF1C1C1E),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Color(0xFFFF3B30)),
                  title: Text(data['pack'] ?? "Order", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Game ID: ${data['gameId']}"),
                      Text("Amount: ₹${data['price']}"),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: orderId, orderData: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending": return Colors.orange;
      case "Processing": return Colors.blue;
      case "Shipped": return Colors.purple;
      case "Delivered": return Colors.green;
      default: return Colors.grey;
    }
  }
}

// ================= ORDER DETAIL + LIVE TRACKING =================
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<dynamic, dynamic> orderData;
  const OrderDetailScreen({super.key, required this.orderId, required this.orderData});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final List<String> _statusFlow = ["Pending", "Processing", "Shipped", "Delivered"];
  String? _currentStatus;
  late DatabaseReference _statusRef;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.orderData['status'] ?? "Pending";
    _statusRef = FirebaseDatabase.instance.ref("orders/${widget.orderId}/status");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _statusRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            _currentStatus = snapshot.data!.snapshot.value as String;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: const Color(0xFF1C1C1E),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Order ID: ${widget.orderId}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(),
                        Text("Pack: ${widget.orderData['pack']}"),
                        Text("Game ID: ${widget.orderData['gameId']}"),
                        Text("Amount: ₹${widget.orderData['price']}"),
                        Text("Payment Method: ${widget.orderData['method']}"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text("Current Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_currentStatus),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_currentStatus!, style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Live Tracking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._statusFlow.map((status) => _buildTimelineItem(status)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(String status) {
    bool isCompleted = _statusFlow.indexOf(status) <= _statusFlow.indexOf(_currentStatus!);
    bool isCurrent = status == _currentStatus;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isCompleted ? _getStatusColor(status) : Colors.grey.shade700,
        child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
      ),
      title: Text(status, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
      subtitle: isCurrent ? const Text("Current status") : null,
      trailing: isCurrent ? const Icon(Icons.location_on, color: Colors.green) : null,
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case "Pending": return Colors.orange;
      case "Processing": return Colors.blue;
      case "Shipped": return Colors.purple;
      case "Delivered": return Colors.green;
      default: return Colors.grey;
    }
  }
}