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
    // Subscribe to balance changes in Firebase
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _balanceStream = _database.child("users/$uid/balance").onValue;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF1A1A1A),
        activeColor: CupertinoColors.activeBlue,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_crop_circle_fill), label: 'Profile'),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: const Color(0xFF1A1A1A),
            leading: const Icon(CupertinoIcons.bag_fill, color: CupertinoColors.activeBlue),
            middle: const Text('SHOP', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.sparkles, color: CupertinoColors.white), onPressed: () {}),
                
                // WORKING WALLET UI FROM image_0.png
                StreamBuilder<DatabaseEvent>(
                  stream: _balanceStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      _currentBalance = (snapshot.data!.snapshot.value as num).toInt();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.creditcard, size: 16, color: CupertinoColors.white),
                          const SizedBox(width: 4),
                          Text("₹$_currentBalance", style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const CupertinoSearchTextField(backgroundColor: Color(0xFF1A1A1A), placeholder: 'Search for BGMI UC, Valorant & more'),
                const SizedBox(height: 20),
                const Text('For You', style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // BGMI UC Product Card - Handles navigation on click
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Navegate to packs screen when clicked
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => const BgmiPacksScreen()));
                        },
                        child: _buildProductCard('Battlegrounds Mobile India', 'BGMI UC', '10% Savings', imageIcon: CupertinoIcons.game_controller_solid),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildProductCard('Valorant', 'Valorant Points', '17.8% Savings', imageIcon: CupertinoIcons.desktopcomputer)),
                  ],
                ),
                // categories filters replication ...
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(String gameTitle, String packName, String savings, {required IconData imageIcon}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(color: Color(0xFF333333), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Center(child: Icon(imageIcon, size: 40, color: CupertinoColors.systemGrey)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gameTitle, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 10)),
                const SizedBox(height: 4),
                Text(packName, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(savings, style: const TextStyle(color: CupertinoColors.activeBlue, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
