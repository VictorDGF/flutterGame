import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/auth_service.dart';
import '/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
    @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Prisma Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const AuthGate(),
      // Mantengo rutas por si las necesitas en otros lugares
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos el stream de authService para reconstruir cuando cambia el estado
    return StreamBuilder<User?>(
      stream: authService.value.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras se determina el estado, mostramos una pantalla de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si hay un usuario (logueado) mostramos HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        // Si no hay usuario mostramos LoginScreen
        return const LoginScreen();
      },
    );
  }
}
