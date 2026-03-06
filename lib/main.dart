import 'package:arya/pages/HomePage.dart';
import 'package:arya/pages/loginpage.dart';
import 'package:arya/pages/signuppage.dart';
import 'package:arya/pages/NoteDetailPage.dart';
import 'package:arya/service/encryption_service.dart';
import 'package:arya/service/firebase_service.dart';
import 'package:arya/service/local_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:get/get.dart";
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    EncryptionService.validateConfiguration();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MainApp());
  } catch (e) {
    runApp(StartupErrorApp(message: e.toString()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final String message;

  const StartupErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'App configuration error:\n$message',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: "/", page: () => const AuthWrapper()),
        GetPage(name: "/home", page: () => const HomePage()),
        GetPage(name: "/login", page: () => const Loginpage()),
        GetPage(name: "/signup", page: () => const Signuppage()),
        GetPage(
          name: "/note-detail",
          page: () => NoteDetailPage(note: Get.arguments),
        ),
      ],
    );
  }
}

class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final LocalAuthService _localAuthService = LocalAuthService();

  bool _isChecking = true;
  bool _isUnlocked = false;
  bool _isAuthenticating = false;
  bool _shouldReauthenticateOnResume = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _localAuthService.stopAuthentication();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_localAuthService.requiresAppUnlock) {
      return;
    }

    final movedToBackground =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused;

    if (movedToBackground && _isUnlocked && !_isAuthenticating) {
      _shouldReauthenticateOnResume = true;
      if (!mounted) return;
      setState(() {
        _isUnlocked = false;
        _isChecking = false;
        _message = 'Unlock Arya to continue.';
      });
    }

    if (state == AppLifecycleState.resumed &&
        _shouldReauthenticateOnResume &&
        !_isAuthenticating) {
      _shouldReauthenticateOnResume = false;
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (!_localAuthService.requiresAppUnlock) {
      if (!mounted) return;
      setState(() {
        _isUnlocked = true;
        _isChecking = false;
        _message = null;
      });
      return;
    }

    if (_isAuthenticating) {
      return;
    }

    if (mounted) {
      setState(() {
        _isChecking = true;
        _isAuthenticating = true;
        _message = null;
      });
    }

    final result = await _localAuthService.authenticate();
    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
      _isChecking = false;
      _isUnlocked = result.didAuthenticate;
      _message = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showLockScreen =
        _localAuthService.requiresAppUnlock && (_isChecking || !_isUnlocked);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (showLockScreen)
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'Unlock Arya',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isChecking
                              ? 'Checking device authentication...'
                              : (_message ?? 'Unlock Arya to continue.'),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_isChecking)
                          const CircularProgressIndicator()
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _authenticate,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Authenticate'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        try {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            debugPrint('Auth error: ${snapshot.error}');
            return const Loginpage();
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }

          return const Loginpage();
        } catch (e) {
          debugPrint('AuthWrapper error: $e');
          return const Loginpage();
        }
      },
    );
  }
}
