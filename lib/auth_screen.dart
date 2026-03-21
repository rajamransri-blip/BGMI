import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Initialize wallet for new user in Firebase RTDB
        await FirebaseDatabase.instance.ref("users/${userCredential.user!.uid}").set({
          'balance': 0,
          'email': _emailController.text.trim()
        });
      }
    } catch (e) {
      _showError(e.toString());
    }
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(ctx))],
      ),
    );
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
              _isLoading
                  ? const CupertinoActivityIndicator()
                  : CupertinoButton.filled(onPressed: _submit, child: Text(_isLogin ? "Login" : "Register")),
              CupertinoButton(
                child: Text(_isLogin ? "Create an account" : "I already have an account"),
                onPressed: () => setState(() => _isLogin = !_isLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
