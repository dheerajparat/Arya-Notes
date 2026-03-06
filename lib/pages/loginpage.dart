import 'package:arya/service/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      Get.snackbar(
        'Success',
        'Login successful!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
      Get.offAllNamed('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Login Failed',
        _authService.getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Login error: $e');
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
      appBar: AppBar(title: const Text('Login')),
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
                  if ((value ?? '').isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => Get.toNamed('/signup'),
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
