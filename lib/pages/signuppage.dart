import 'package:arya/service/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      Get.snackbar(
        'Success',
        'Account created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Get.offAllNamed('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Signup Failed',
        _authService.getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Signup error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Email is required';
                  }
                  if (!email.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) {
                    return 'Password is required';
                  }
                  if (password.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if ((value ?? '') != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => Get.back(),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
