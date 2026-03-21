import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // basic list tile uses material but style it for ios
import 'delivery_details_screen.dart';

class BgmiPacksScreen extends StatelessWidget {
  const BgmiPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded BGMI UC packs for demo
    final packs = [
      {'uc': 60, 'price': 75},
      {'uc': 300, 'extra': 25, 'price': 380},
      {'uc': 600, 'extra': 60, 'price': 750},
      {'uc': 1500, 'extra': 300, 'price': 1900},
    ];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Select BGMI UC Pack")),
      child: SafeArea(
        child: ListView.separated(
          itemCount: packs.length,
          separatorBuilder: (context, index) => const Divider(color: Color(0xFF333333), height: 1),
          itemBuilder: (context, index) {
            final pack = packs[index];
            int totalUC = pack['uc']! + (pack['extra'] ?? 0);
            return Material( // wrap with material for inkwell, but use ios colors
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                leading: const Icon(CupertinoIcons.money_dollar_circle, color: Color(0xFFFFD700), size: 30),
                title: Text("$totalUC UC", style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                subtitle: pack['extra'] != null ? Text("${pack['uc']} + ${pack['extra']} Bonus", style: const TextStyle(color: CupertinoColors.systemGrey)) : null,
                trailing: Text("₹${pack['price']}", style: const TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () {
                  // Navigate to details screen with selected pack price
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => DeliveryDetailsScreen(selectedUC: totalUC, price: pack['price']!)));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
