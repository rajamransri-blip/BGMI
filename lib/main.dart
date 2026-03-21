import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Yahan hum apne banaye hue screens import kar rahe hain
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Flutter engine ko initialize karna
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase ko initialize karna
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase Initialized Successfully!");
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  // 3. App run karna
  runApp(const RooterShopApp());
}

class RooterShopApp extends StatelessWidget {
  const RooterShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    // iOS (Cupertino) design use kar rahe hain jaisa aapne manga tha
    return const CupertinoApp(
      title: 'Rooter SHOP',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: Color(0xFF0F0F0F),
      ),
      // AuthStateWrapper decide karega ki Login screen dikhani hai ya Home screen
      home: AuthStateWrapper(),
    );
  }
}

// Yeh class automatically check karti hai ki user logged in hai ya nahi
class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jab tak Firebase check kar raha hai, loading spinner dikhayega
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        
        // Agar user pehle se login hai, toh direct Home Screen par bhej do
        if (snapshot.hasData) {
          return const HomeScreen(); 
        }
        
        // Agar naya user hai ya logout ho chuka hai, toh Login/Register Screen dikhao
        return const AuthScreen(); 
      },
    );
  }
}
