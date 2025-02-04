import 'package:flutter/material.dart';
import 'package:avocatooapp/screens/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;

    // Degradado con mayor intensidad
    final LinearGradient backgroundGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.black.withOpacity(0.9), // Más oscuro en la parte inferior
        Colors.black.withOpacity(0.6),
        Colors.transparent, // Transparente hacia la parte superior
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/avocato_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Capa de degradado
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: backgroundGradient,
              ),
            ),
          ),
          // Contenido principal
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo adaptado a pantallas grandes y pequeñas
                  Image.asset(
                    'assets/images/avocato_logo.png',
                    width: screenWidth * 0.35, // 35% del ancho de la pantalla
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 48), // Espaciado extra para centrado
                  // Botón “Iniciar”
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Navega a la pantalla de inicio de sesión
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Iniciar',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
