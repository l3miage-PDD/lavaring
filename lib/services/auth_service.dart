import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        print("Connexion annulée par l'utilisateur.");
        return null;
      }
      print("Étape 1/3 : Compte Google récupéré.");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print("Étape 2/3 : Identifiants Firebase créés.");

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("Étape 3/3 : Connexion à Firebase réussie !");
      return userCredential.user;
    } on PlatformException catch (e) {
      print("--- ERREUR NATIVE DÉTAILLÉE ---");
      print("Une erreur est survenue lors de la communication avec la plateforme native (Android/iOS).");
      print("Code de l'erreur: ${e.code}");
      print("Message de l'erreur: ${e.message}");
      print("Détails de l'erreur: ${e.details}");
      print("---------------------------------");
      return null;
    } catch (e, s) {
      print("--- ERREUR GÉNÉRIQUE DÉTAILLÉE ---");
      print("Une erreur inattendue est survenue dans le code Dart.");
      print("Erreur: $e");
      print("Trace de la pile (Stack Trace):");
      print(s);
      print("----------------------------------");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
