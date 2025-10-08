import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    // Store the ScaffoldMessenger before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenue sur',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lava Ring',
               style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              icon: Image.asset('assets/google_logo.png', height: 24.0),
              label: const Text('Se connecter avec Google'),
              onPressed: () async {
                final user = await authService.signInWithGoogle();
                // Check if the widget is still mounted before showing the SnackBar
                if (!scaffoldMessenger.mounted) return;
                if (user == null) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('La connexion avec Google a échoué.'),
                       backgroundColor: Colors.red,
                    ),
                  );
                }
              },
               style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
