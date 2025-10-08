import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        developer.log("Connexion annulée par l'utilisateur.", name: 'auth_service');
        return null;
      }
      developer.log("Étape 1/3 : Compte Google récupéré.", name: 'auth_service');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      developer.log("Étape 2/3 : Identifiants Firebase créés.", name: 'auth_service');

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      developer.log("Étape 3/3 : Connexion à Firebase réussie !", name: 'auth_service');
      return userCredential.user;
    } on PlatformException catch (e, s) {
      developer.log(
        "Une erreur est survenue lors de la communication avec la plateforme native (Android/iOS).",
        name: 'auth_service',
        error: e,
        stackTrace: s,
        level: 1000, // SEVERE
      );
      return null;
    } catch (e, s) {
      developer.log(
        "Une erreur inattendue est survenue.",
        name: 'auth_service',
        error: e,
        stackTrace: s,
        level: 1000, // SEVERE
      );
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
