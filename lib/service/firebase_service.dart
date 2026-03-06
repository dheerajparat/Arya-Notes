import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String getErrorMessage(Object error) {
    try {
      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'weak-password':
            return 'Password is too weak. Use at least 6 characters.';
          case 'email-already-in-use':
            return 'This email is already registered.';
          case 'invalid-email':
            return 'Please enter a valid email address.';
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            return 'Invalid email or password.';
          case 'user-disabled':
            return 'This account has been disabled.';
          case 'too-many-requests':
            return 'Too many login attempts. Try again later.';
          case 'operation-not-allowed':
            return 'Email/password authentication is disabled.';
          case 'network-request-failed':
            return 'Network error. Check your internet connection.';
          default:
            return 'Authentication failed: ${error.message ?? 'Unknown error'}';
        }
      }
      return 'Authentication error occurred.';
    } catch (e) {
      debugPrint('Error parsing auth exception: $e');
      return 'An unexpected error occurred.';
    }
  }

  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('SignUp error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('SignIn error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
      rethrow;
    }
  }

  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  Stream<User?> authStateChanges() {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      debugPrint('Auth state changes error: $e');
      return Stream.empty();
    }
  }
}
