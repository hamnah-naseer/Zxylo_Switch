import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAuthenticated = false;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;

  // 🔹 LOGIN
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      _isAuthenticated = true;
      _userEmail = email;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login error: ${e.message}");
      return false;
    }
  }

  // 🔹 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    _isAuthenticated = false;
    _userEmail = null;
    notifyListeners();
  }

  // 🔹 SIGNUP
  Future<bool> signup({
    required String houseName,
    required String fullName,
    required String email,
    required String contact,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      _isAuthenticated = true;
      _userEmail = email;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Signup error: ${e.message}");
      return false;
    }
  }

  // 🔹 RESET PASSWORD (with detailed error)
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // null = no error
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "user-not-found":
          return "No user found with this email.";
        case "invalid-email":
          return "The email address is not valid.";
        case "missing-email":
          return "Please provide an email.";
        default:
          return "Something went wrong. Try again later.";
      }
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  // 🔹 AUTO LOGIN CHECK
  void checkAuthState() {
    final user = _auth.currentUser;
    if (user != null) {
      _isAuthenticated = true;
      _userEmail = user.email;
    } else {
      _isAuthenticated = false;
      _userEmail = null;
    }
    notifyListeners();
  }
}
