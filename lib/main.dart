// lib/main.dart

import 'package:avocatooapp/%20utils/firebase_options.dart';
// Import corregido

import 'package:avocatooapp/screens/SplashScreen.dart';
import 'package:avocatooapp/screens/home_screenuser.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import añadido
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import de tus pantallas
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar datos de localización para español (España)
  await initializeDateFormatting('es_ES', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Avocato',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Configuración de localización
      locale: const Locale('es', 'ES'), // Establece el locale predeterminado
      supportedLocales: const [
        Locale('es', 'ES'),
        // Agrega más locales si es necesario
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Cambiamos la ruta inicial a la SplashScreen
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/homeUser': (context) => const HomeScreenUser(),
      },
    );
  }
}
