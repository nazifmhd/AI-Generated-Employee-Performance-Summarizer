import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = kIsWeb 
      ? GoogleSignIn(
          clientId: '1049212865852-fq8fq4scerhprhles16glkmmt1mg7hvf.apps.googleusercontent.com', // Replace with your actual web client ID
        ) 
      : GoogleSignIn();
  
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isAuthenticated => currentUser != null; // Added for compatibility with your other code
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      notifyListeners();
      return credential;
    } catch (e) {
      debugPrint("Error signing in with email: $e");
      rethrow;
    }
  }
  
  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // The sign-in process is slightly different for web vs other platforms
      if (kIsWeb) {
        // Web implementation
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        final UserCredential userCredential = 
            await _auth.signInWithPopup(authProvider);
        notifyListeners();
        return userCredential;
      } else {
        // Mobile/desktop implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) return null;
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        notifyListeners();
        return userCredential;
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      rethrow;
    }
  }
  
  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      notifyListeners();
      return credential;
    } catch (e) {
      debugPrint("Error signing up with email: $e");
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint("Error signing out: $e");
      rethrow;
    }
  }
}