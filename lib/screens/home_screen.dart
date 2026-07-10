import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'bgmi_packs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBalance = 0;
  final _database = FirebaseDatabase.instance.ref();
  late Stream<DatabaseEvent> _balanceStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _balanceStream = _database.child("users/$uid/balance").onValue;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF121214),
        activeColor: const Color(0xFF007AFF),
        inactiveColor: CupertinoColors.systemGrey2,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2_fill), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.bag_fill), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_fill), label: 'Profile'),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoPageScaffold(
          backgroundColor: const Color(0xFF0A0A0C), // Deep Premium Dark Background
          navigationBar: CupertinoNavigationBar(
            border: Border(bottom: BorderSide(color: const Color(0xFF1F1F24), width: 0.5)),
            backgroundColor: const Color(0xFF121214).withOpacity(0.8),
            leading: const Icon(CupertinoIcons.sparkles, color: Color(0xFF007AFF), size: 24),
            middle: const Text(
              'EPIC SHOP', 
              style: TextStyle(
                color: CupertinoColors.white, 
                fontWeight: FontWeight.extrabold, 
                letterSpacing: 1.2,
                fontSize: 18
              )
            ),
            trailing: StreamBuilder<DatabaseEvent>(
              stream: _balanceStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  _currentBalance = (snapshot.data!.snapshot.value as num).toInt();
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F1F24), Color(0xFF2C2C35)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF3A3A45), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.tokens, size: 16, color: Color(0xFFFFD700)), // Gold Token Icon
                      const SizedBox(width: 6),
                      Text(
                        "₹$_currentBalance", 
                        style: const TextStyle(
                          color: CupertinoColors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 14
                        )
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18.0),
              children: [
                const SizedBox(height: 8),
                const CupertinoSearchTextField(
                  backgroundColor: Color(0xFF121214),
                  placeholder: 'Search BGMI UC, Valorant Points...',
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text(
                      'Featured For You', 
                      style: TextStyle(
                        color: CupertinoColors.white, 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5
                      )
                    ),
                    GestureDetector(
                      child: const Text('See All', style: TextStyle(color: Color(0xFF007AFF), fontSize: 14)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InteractiveCard(
                        onTap: () {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => const BgmiPacksScreen()));
                        },
                        child: _buildProductCard(
                          'BATTLEGROUNDS India', 
                          'BGMI UC Instant Pack', 
                          '10% OFF', 
                          imageIcon: CupertinoIcons.gamecontroller_fill,
                          accentColor: const Color(0xFFF3A63B)
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InteractiveCard(
                        onTap: () {
                          // Valorant route action here
                        },
                        child: _buildProductCard(
                          'VALORANT PC', 
                          'Valorant Riot Points', 
                          '17.8% SAVE', 
                          imageIcon: CupertinoIcons.device_desktop,
                          accentColor: const Color(0xFFFF4655)
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modern Clean Card Design
  Widget _buildProductCard(String gameTitle, String packName, String savings, {required IconData imageIcon, required Color accentColor}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121214),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F1F24), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Top Image Area
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1E),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [const Color(0xFF121214), accentColor.withOpacity(0.15)],
                  ),
                ),
                child: Center(
                  child: Icon(imageIcon, size: 44, color: accentColor),
                ),
              ),
              // Dynamic Savings Tag/Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    savings,
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.extrabold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content Area
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameTitle.toUpperCase(), 
                  style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                ),
                const SizedBox(height: 6),
                Text(
                  packName, 
                  style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w700, fontSize: 13, height: 1.2), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text('View Packs', style: TextStyle(color: Color(0xFF007AFF), fontSize: 11, fontWeight: FontWeight.w600)),
                    Icon(CupertinoIcons.chevron_right, size: 12, color: const Color(0xFF007AFF).withOpacity(0.8)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🎯 Custom Click Animation Wrapper Widget (Bouncy Feedback)
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const InteractiveCard({super.key, required this.child, this.onTap});

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
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
        scale: _isPressed ? 0.95 : 1.0, // 5% Scale Down Effect on Press
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
