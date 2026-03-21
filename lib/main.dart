import 'package:flutter/material.dart';
// 1. Firebase package import karein
import 'package:firebase_core/firebase_core.dart';

// Aapke dusre local screens ke import bhi yahan honge
// Jaise ke: import 'package:bgmi_uc_shop/screens/home_screen.dart';

void main() async {
  // 2. Yeh line mandatory hai async functions ke liye jo initialization karte hain
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Yahan Firebase ko initialize karein
  await Firebase.initializeApp();

  // 4. Uske baad app run karein
  runApp(const RooterShopApp());
}

class RooterShopApp extends StatelessWidget {
  const RooterShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rooter SHOP',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF101010), // image_0 ke dark look ke liye
      ),
      // Yahan aap apna original Home screen ka code link karein
      // home: const HomeScreen(), 
      home: const Scaffold(body: Center(child: Text('Firebase Initialized!'))), // Yeh testing ke liye hai
    );
  }
}
