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
        primaryColor: const Color(0xFFFF334B),
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161920),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
      ),
      home: isInit ? const AuthWrapper() : Scaffold(body: Center(child: Text("Initialization Error: $error"))),
    );
  }
}

// ================= UNIVERSAL BOUNCY INTERACTION WRAPPER =================
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const BouncyButton({super.key, required this.child, this.onTap});

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF334B))));
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
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF161920),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _emailPasswordSubmit() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      _showSnackbar("Please fill all fields");
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      } else {
        UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        await FirebaseDatabase.instance.ref("users/${user.user!.uid}").set({
          'balance': 0,
          'email': _email.text.trim(),
          'createdAt': ServerValue.timestamp,
        });
        _showSnackbar("Account created! Welcome onboard.");
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
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
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
      _showSnackbar("Google Sign-In failed: ${e.toString()}");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _animationController,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF334B).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF334B).withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(CupertinoIcons.gamecontroller_fill, size: 60, color: Color(0xFFFF334B)),
                  ),
                  const SizedBox(height: 16),
                  // FIXED: FontWeight.black changed to FontWeight.w900
                  const Text("ROOTER SHOP", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  Text("Premium Gaming Destination", style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _email,
                    decoration: InputDecoration(
                      hintText: "Email Account",
                      prefixIcon: const Icon(CupertinoIcons.mail, color: Color(0xFFFF334B)),
                      filled: true,
                      fillColor: const Color(0xFF161920),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Security Password",
                      prefixIcon: const Icon(CupertinoIcons.lock_fill, color: Color(0xFFFF334B)),
                      filled: true,
                      fillColor: const Color(0xFF161920),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Color(0xFFFF334B))
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF334B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _emailPasswordSubmit,
                            child: Text(_isLogin ? "AUTHENTICATE" : "REGISTER", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade800)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.grey.shade600))),
                            Expanded(child: Divider(color: Colors.grey.shade800)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        BouncyButton(
                          onTap: _signInWithGoogle,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFF161920),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade800),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png', height: 20),
                                const SizedBox(width: 12),
                                const Text("Continue with Google", style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? "Create New Cyber Identity" : "Sign In into Existing Account",
                      style: const TextStyle(color: Color(0xFFFF334B), fontWeight: FontWeight.w600),
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
        title: const Text("DASHBOARD"),
        actions: [
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref("users/$uid/balance").onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                _balance = (snapshot.data!.snapshot.value as num).toInt();
              }
              return BouncyButton(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletTopupScreen())),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E222D), Color(0xFF161920)]),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFFF334B).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.creditcard_fill, size: 16, color: Color(0xFFFF334B)),
                      const SizedBox(width: 8),
                      Text("₹$_balance", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 6),
                      const Icon(CupertinoIcons.add_circled_solid, size: 16, color: Color(0xFF00E676)),
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
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search custom packages, assets...",
                prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF161920),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(CupertinoIcons.gift_fill, color: Color(0xFFFF334B), size: 22),
                const SizedBox(width: 8),
                // FIXED: FontWeight.black changed to FontWeight.w900
                const Text("LIVE GIVEAWAYS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
              ],
            ),
            const SizedBox(height: 12),
            _buildGiveawayCard(),
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(CupertinoIcons.flame_fill, color: Color(0xFFFF4500), size: 22),
                const SizedBox(width: 8),
                // FIXED: FontWeight.black changed to FontWeight.w900
                const Text("PREMIUM PACKS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
              ],
            ),
            const SizedBox(height: 14),
            ..._buildPackCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildGiveawayCard() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref("giveaways").limitToLast(1).onValue,
      builder: (context, snapshot) {
        bool hasData = snapshot.hasData && snapshot.data!.snapshot.value != null;
        String title = "Next Giveaway Dropping Soon";
        String code = "STAY TUNED CHANNEL";
        
        if (hasData) {
          Map data = snapshot.data!.snapshot.value as Map;
          var codeData = data[data.keys.first];
          title = "Google Play Voucher";
          code = codeData['code'] ?? "XXXX-XXXX-XXXX";
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFF334B).withOpacity(0.15), const Color(0xFF161920)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF334B).withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFF334B).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(CupertinoIcons.ticket_fill, color: Color(0xFFFF334B), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(code, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
                    ],
                  ),
                ),
                if (hasData)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF334B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Voucher Copied to Clipboard"))),
                    child: const Text("CLAIM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPackCards() {
    final packs = [
      {'uc': 60, 'price': 75, 'discount': 0},
      {'uc': 300, 'extra': 25, 'price': 380, 'discount': 12},
      {'uc': 600, 'extra': 60, 'price': 750, 'discount': 18},
      {'uc': 1500, 'extra': 225, 'price': 1800, 'discount': 35},
    ];

    return packs.map((pack) {
      int total = pack['uc']! + (pack['extra'] ?? 0);
      int discount = pack['discount']!;
      int originalPrice = pack['price']!;
      int discountedPrice = discount > 0 ? (originalPrice * (100 - discount) / 100).round() : originalPrice;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161920),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF232835), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(uc: total, price: discountedPrice, packName: "$total UC Pack")));
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFC107).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.stars, color: Color(0xFFFFC107), size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$total Game UC", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (pack['extra'] != null)
                            Text("+ ${pack['extra']} Stack Bonus Included", style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.w500)),
                          if (discount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text("₹$originalPrice", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFFF334B), borderRadius: BorderRadius.circular(8)),
                                  // FIXED: FontWeight.black changed to FontWeight.w900
                                  child: Text("SAVE $discount%", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFFF334B), borderRadius: BorderRadius.circular(16)),
                      child: Text("₹$discountedPrice", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPremiumDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0D0E12),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFF334B), Color(0xFF8B0000)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.profile_circled, size: 54, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Active Soldier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(FirebaseAuth.instance.currentUser?.email ?? "User Profile", style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(CupertinoIcons.house_fill, "Home Inventory", () => Navigator.pop(context)),
            _buildDrawerItem(CupertinoIcons.square_list_fill, "My Orders Status", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
            }),
            const Spacer(),
            const Divider(color: Color(0xFF232835)),
            _buildDrawerItem(CupertinoIcons.power, "Disconnect Session", () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            }, isRed: true),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isRed = false}) {
    return ListTile(
      leading: Icon(icon, color: isRed ? Colors.redAccent : const Color(0xFFFF334B), size: 20),
      title: Text(title, style: TextStyle(color: isRed ? Colors.redAccent : Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
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
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delivery Coordinates")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ENTER PLAYER CREDENTIALS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "BGMI Game UID",
                labelStyle: const TextStyle(color: Color(0xFFFF334B)),
                filled: true,
                fillColor: const Color(0xFF161920),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CupertinoCheckbox(
                  value: _saveDetails,
                  activeColor: const Color(0xFFFF334B),
                  onChanged: (val) => setState(() => _saveDetails = val ?? false),
                ),
                const SizedBox(width: 8),
                const Text("Cache parameters for faster processing", style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF334B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  if (_idController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Valid Character UID is mandatory")));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(price: widget.price, pack: widget.packName, gameId: _idController.text.trim())));
                },
                child: Text("SECURE CHECKOUT • ₹${widget.price}", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
      _showSnackbar("Insufficient Vault Reserves!");
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
        'method': 'Vault Balance',
        'status': 'Pending',
        'timestamp': ServerValue.timestamp,
      });
      if (mounted) _showSuccessDialog();
    } else {
      setState(() => _loading = false);
      _showSnackbar("Transaction Rejected!");
    }
  }

  Future<void> _payWithUPI(UpiApp app) async {
    setState(() => _loading = true);
    try {
      UpiResponse res = await _upi.startTransaction(
        app: app,
        receiverUpiId: "paynearby.8406962570@indus",
        receiverName: "Rooter Shop Operations",
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
        _showSnackbar("Gateway Timeout or Aborted");
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
        title: const Text("ORDER TRANSMITTED"),
        content: const Text("Your assets package is being routed to your specified Game ID account."),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text("CONFIRM"),
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
      appBar: AppBar(title: const Text("Secure Gateway Options")),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF334B)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("VAULT RESERVES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF161920), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF232835))),
                  child: ListTile(
                    // FIXED: Changed CupertinoIcons.wallet_fill to CupertinoIcons.creditcard_fill for SDK compatibility
                    leading: const Icon(CupertinoIcons.creditcard_fill, color: Color(0xFFFF334B), size: 26),
                    title: const Text("Internal Store Wallet"),
                    subtitle: Text("Available: ₹$_wallet", style: TextStyle(color: _wallet < widget.price ? Colors.redAccent : const Color(0xFF00E676), fontWeight: FontWeight.bold)),
                    trailing: CupertinoButton(
                      color: const Color(0xFFFF334B),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _wallet >= widget.price ? _payWithWallet : null,
                      child: const Text("PAY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text("BANKING INSTANT NODES (UPI)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 10),
                if (_apps != null)
                  ..._apps!.map((a) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: const Color(0xFF161920), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF232835))),
                        child: ListTile(
                          leading: Image.memory(a.icon, width: 28),
                          title: Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: Colors.grey),
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
    if (_amountController.text.isEmpty) return;
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount < 10) return;

    setState(() => _loading = true);
    try {
      UpiResponse res = await _upi.startTransaction(
        app: app,
        receiverUpiId: "paynearby.8406962570@indus",
        receiverName: "Rooter Shop Operations",
        transactionRefId: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount.toDouble(),
      );

      if (res.status == UpiPaymentStatus.SUCCESS) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseDatabase.instance.ref("users/$uid/balance").runTransaction((Object? current) {
          int bal = current == null ? 0 : (current as num).toInt();
          return Transaction.success(bal + amount);
        });
        Navigator.pop(context);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recharge Vault Reserves")),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF334B)))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                    decoration: InputDecoration(
                      prefixText: "₹ ",
                      labelText: "Load Capital Amount",
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF161920),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text("EXECUTE VIA APPS NETWORK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  if (_apps != null)
                    Expanded(
                      child: ListView(
                        children: _apps!.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: const Color(0xFF161920), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF232835))),
                          child: ListTile(
                            leading: Image.memory(a.icon, width: 28),
                            title: Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            onTap: () => _processTopup(a),
                          ),
                        )).toList(),
                      ),
                    ),
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
      appBar: AppBar(title: const Text("Procurement History")),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref("orders").orderByChild("uid").equalTo(uid).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF334B)));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.tray_fill, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No historical transactions initialized"),
                ],
              ),
            );
          }

          Map orders = snapshot.data!.snapshot.value as Map;
          List<MapEntry> entries = orders.entries.toList();
          entries.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: entries.length,
            itemBuilder: (ctx, index) {
              var orderId = entries[index].key;
              var data = entries[index].value;
              String status = data['status'] ?? "Pending";
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFF161920), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF232835))),
                child: ListTile(
                  leading: const Icon(CupertinoIcons.cube_box_fill, color: Color(0xFFFF334B)),
                  title: Text(data['pack'] ?? "Assets Pack", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Text("₹${data['price']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: _getStatusColor(status))),
                          // FIXED: FontWeight.black changed to FontWeight.w900
                          child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId, orderData: data))),
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
      case "Delivered": return const Color(0xFF00E676);
      default: return Colors.grey;
    }
  }
}

// ================= ORDER DETAIL + LIVE STEPPER TIMELINE =================
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

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.orderData['status'] ?? "Pending";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Node Diagnostics")),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref("orders/${widget.orderId}/status").onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            _currentStatus = snapshot.data!.snapshot.value as String;
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF161920), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF232835))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIXED: FontWeight.black changed to FontWeight.w900
                    Text("HASH ID: ${widget.orderId}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11, letterSpacing: 0.5)),
                    const Divider(height: 24, color: Color(0xFF232835)),
                    Text("Inventory Package: ${widget.orderData['pack']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Target Player Profile UID: ${widget.orderData['gameId']}", style: const TextStyle(color: Colors.white70)),
                    Text("Frictionless Billing: ₹${widget.orderData['price']}", style: const TextStyle(color: Colors.white70)),
                    Text("Route Protocol: ${widget.orderData['method']}", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // FIXED: FontWeight.black changed to FontWeight.w900
              const Text("LIVE PIPELINE TRACKING", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)),
              const SizedBox(height: 20),
              ..._statusFlow.map((status) {
                int index = _statusFlow.indexOf(status);
                int currentIndex = _statusFlow.indexOf(_currentStatus!);
                bool isDone = index <= currentIndex;
                bool isCurrent = status == _currentStatus;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? const Color(0xFFFF334B) : const Color(0xFF161920),
                            border: Border.all(color: isDone ? const Color(0xFFFF334B) : Colors.grey.shade700, width: 2),
                          ),
                          child: isDone ? const Icon(CupertinoIcons.checkmark, size: 12, color: Colors.white) : null,
                        ),
                        if (index != _statusFlow.length - 1)
                          Container(width: 2, height: 40, color: index < currentIndex ? const Color(0xFFFF334B) : Colors.grey.shade800),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCurrent ? const Color(0xFFFF334B) : Colors.white70)),
                          if (isCurrent) const Text("Assets current vector status allocation", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 20),
                        ],
                      ),
                    )
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
