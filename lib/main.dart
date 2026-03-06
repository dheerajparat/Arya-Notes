import 'package:arya/pages/HomePage.dart';
import 'package:arya/pages/loginpage.dart';
import 'package:arya/pages/signuppage.dart';
import 'package:arya/pages/NoteDetailPage.dart';
import 'package:arya/service/encryption_service.dart';
import 'package:arya/service/firebase_service.dart';
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
