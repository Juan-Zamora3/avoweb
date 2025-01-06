// lib/screens/ajustes_admin.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Mantenido si es necesario en futuras funcionalidades

class AjustesAdminScreen extends StatefulWidget {
  const AjustesAdminScreen({Key? key}) : super(key: key);

  @override
  State<AjustesAdminScreen> createState() => _AjustesAdminScreenState();
}

class _AjustesAdminScreenState extends State<AjustesAdminScreen> {
  // Obtener dinámicamente el UID del usuario autenticado
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    // Verificar si el usuario está autenticado
    if (userId == null) {
      // Redirigir a la pantalla de inicio de sesión si no está autenticado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para evitar pantalla negra al final
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildAjustesPanel(),
          ],
        ),
      ),
    );
  }

  // Encabezado con fondo e imagen decorativa
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black26, // Ajustado a una opacidad menor para mejorar el contraste
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ajustes de Admin',
              style: GoogleFonts.sen(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Administra tu cuenta y preferencias',
              style: GoogleFonts.sen(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Panel con las opciones de ajustes
  Widget _buildAjustesPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white, // Fondo blanco para el panel de ajustes
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuraciones',
            style: GoogleFonts.sen(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // 1) Cambiar Contraseña
          _buildAjusteOption(
            icon: Icons.lock,
            title: "Cambiar Contraseña",
            subtitle: "Actualiza tu contraseña de acceso",
            onTap: _cambiarContrasena,
          ),

          const Divider(height: 30, thickness: 1, color: Colors.grey),

          // 2) Cerrar Sesión
          _buildAjusteOption(
            icon: Icons.logout,
            title: "Cerrar Sesión",
            subtitle: "Salir de tu cuenta actual",
            onTap: _cerrarSesion,
          ),
        ],
      ),
    );
  }

  // Widget base para cada opción de ajustes
  Widget _buildAjusteOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.amber[700],
          size: 30,
        ),
        title: Text(
          title,
          style: GoogleFonts.sen(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.sen(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  // ---------------- LÓGICA DE CADA BOTÓN: ------------------

  /// 1) Cambiar Contraseña (FirebaseAuth)
  Future<void> _cambiarContrasena() async {
    final passOldCtrl = TextEditingController();
    final passNewCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Cambiar Contraseña",
            style: GoogleFonts.sen(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _customTextField(passOldCtrl, "Contraseña Actual",
                    obscureText: true),
                const SizedBox(height: 8),
                _customTextField(passNewCtrl, "Nueva Contraseña",
                    obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancelar",
                style: GoogleFonts.sen(color: Colors.white), // Texto blanco
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red, // Fondo rojo para "Cancelar"
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Fondo verde para "Actualizar"
                foregroundColor: Colors.white, // Texto blanco
              ),
              onPressed: () async {
                final oldPass = passOldCtrl.text.trim();
                final newPass = passNewCtrl.text.trim();

                if (oldPass.isEmpty || newPass.isEmpty) {
                  _showSnackBar(
                    "Todos los campos son obligatorios.",
                    isError: true,
                  );
                  return;
                }

                if (newPass.length < 6) {
                  _showSnackBar(
                    "La nueva contraseña debe tener al menos 6 caracteres.",
                    isError: true,
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    throw "No hay usuario logueado.";
                  }

                  // Reautenticar
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPass,
                  );
                  await user.reauthenticateWithCredential(cred);

                  // Actualizar contraseña
                  await user.updatePassword(newPass);

                  Navigator.of(context).pop();
                  _showSnackBar(
                    "Contraseña cambiada correctamente.",
                    isError: false,
                  );
                } on FirebaseAuthException catch (e) {
                  Navigator.of(context).pop();
                  String errorMessage;
                  switch (e.code) {
                    case 'wrong-password':
                      errorMessage = "La contraseña actual es incorrecta.";
                      break;
                    case 'weak-password':
                      errorMessage =
                      "La nueva contraseña es demasiado débil. Debe tener al menos 6 caracteres.";
                      break;
                    default:
                      errorMessage = "Error al cambiar contraseña: ${e.message}";
                  }
                  _showSnackBar(errorMessage, isError: true);
                } catch (e) {
                  Navigator.of(context).pop();
                  _showSnackBar("Error inesperado: $e", isError: true);
                }
              },
              child: Text(
                "Actualizar",
                style: GoogleFonts.sen(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 2) Cerrar Sesión
  Future<void> _cerrarSesion() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Cerrar Sesión",
            style: GoogleFonts.sen(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "¿Estás seguro de que deseas cerrar sesión?",
            style: GoogleFonts.sen(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancelar",
                style: GoogleFonts.sen(color: Colors.white), // Texto blanco
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red, // Fondo rojo para "Cancelar"
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Fondo rojo para "Salir"
                foregroundColor: Colors.white, // Texto blanco
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  // Redirigir a la pantalla de inicio de sesión
                  Navigator.pushReplacementNamed(context, '/login');
                  _showSnackBar("Sesión cerrada exitosamente.", isError: false);
                } catch (e) {
                  _showSnackBar("Error al cerrar sesión: $e", isError: true);
                }
              },
              child: Text(
                "Salir",
                style: GoogleFonts.sen(),
              ),
            ),
          ],
        );
      },
    );
  }

  // Mostrar SnackBar con mensajes personalizados
  void _showSnackBar(String message, {required bool isError}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.sen(),
      ),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // TextField con estilo unificado
  Widget _customTextField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.sen(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.sen(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// Widget personalizado para las opciones de ajustes
class AjustesOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AjustesOptionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: GoogleFonts.sen(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.sen(
          color: Colors.black54,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
      onTap: onTap,
    );
  }
}
