import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AjustesUserScreen extends StatefulWidget {
  const AjustesUserScreen({Key? key}) : super(key: key);

  @override
  State<AjustesUserScreen> createState() => _AjustesUserScreenState();
}

class _AjustesUserScreenState extends State<AjustesUserScreen> {
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
      body: Stack(
        children: [
          // Fondo completo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondopantalla.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenido principal con header y panel blanco
          Column(
            children: [
              // Encabezado
              _buildHeader(),
              // Panel blanco
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildAjustesPanel(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Encabezado con fondo e imagen
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        image: const DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black54,
            BlendMode.darken,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ajustes de Usuario',
              style: GoogleFonts.sen(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Administra tu cuenta y preferencias',
              style: GoogleFonts.sen(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Panel con las opciones de ajustes
  Widget _buildAjustesPanel() {
    return Column(
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

        // 1) Editar Perfil
        _buildAjusteOption(
          icon: Icons.account_circle,
          title: "Editar Perfil",
          subtitle: "Actualiza tu información personal",
          onTap: _editarPerfil,
        ),

        // 2) Cambiar Contraseña
        _buildAjusteOption(
          icon: Icons.lock,
          title: "Cambiar Contraseña",
          subtitle: "Actualiza tu contraseña de acceso",
          onTap: _cambiarContrasena,
        ),

        const Divider(height: 30),

        // 3) Cerrar Sesión
        _buildAjusteOption(
          icon: Icons.logout,
          title: "Cerrar Sesión",
          subtitle: "Salir de tu cuenta actual",
          onTap: _cerrarSesion,
        ),
      ],
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

  /// 1) Editar Perfil: Carga datos SOLO cuando se presiona el botón
  Future<void> _editarPerfil() async {
    try {
      // Consulta a Firestore en el momento que se presiona el botón
      final docTrabajador = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(userId)
          .get();

      if (!docTrabajador.exists) {
        throw "No existe el documento del trabajador.";
      }

      final data = docTrabajador.data()!;
      final nombreActual = data['nombre'] ?? '';
      final correoActual = data['correo'] ?? '';
      final telActual = data['telefono'] ?? '';

      final nombreCtrl = TextEditingController(text: nombreActual);
      final correoCtrl = TextEditingController(text: correoActual);
      final telCtrl = TextEditingController(text: telActual);

      // Mostramos el diálogo con los campos
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Editar Perfil",
              style: GoogleFonts.sen(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _customTextField(nombreCtrl, "Nombre Completo"),
                  const SizedBox(height: 8),
                  _customTextField(correoCtrl, "Correo Electrónico"),
                  const SizedBox(height: 8),
                  _customTextField(telCtrl, "Teléfono"),
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
                  backgroundColor: Colors.green, // Fondo verde para "Guardar"
                  foregroundColor: Colors.white, // Texto blanco
                ),
                onPressed: () async {
                  final nuevoNombre = nombreCtrl.text.trim();
                  final nuevoCorreo = correoCtrl.text.trim();
                  final nuevoTel = telCtrl.text.trim();

                  if (nuevoNombre.isEmpty ||
                      nuevoCorreo.isEmpty ||
                      nuevoTel.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Todos los campos son obligatorios.",
                          style: GoogleFonts.sen(),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  // Validación básica de correo electrónico
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                      .hasMatch(nuevoCorreo)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Ingresa un correo electrónico válido.",
                          style: GoogleFonts.sen(),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('trabajadores')
                        .doc(userId)
                        .update({
                      'nombre': nuevoNombre,
                      'correo': nuevoCorreo,
                      'telefono': nuevoTel,
                    });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Perfil actualizado con éxito",
                          style: GoogleFonts.sen(),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Error al actualizar perfil: $e",
                          style: GoogleFonts.sen(),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: Text(
                  "Guardar",
                  style: GoogleFonts.sen(),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Si algo falla antes del diálogo, se notifica
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
            style: GoogleFonts.sen(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// 2) Cambiar Contraseña (FirebaseAuth)
  void _cambiarContrasena() {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customTextField(passOldCtrl, "Contraseña Actual",
                  obscureText: true),
              const SizedBox(height: 8),
              _customTextField(passNewCtrl, "Nueva Contraseña",
                  obscureText: true),
            ],
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Todos los campos son obligatorios.",
                        style: GoogleFonts.sen(),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "La nueva contraseña debe tener al menos 6 caracteres.",
                        style: GoogleFonts.sen(),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Contraseña cambiada correctamente.",
                        style: GoogleFonts.sen(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Error al cambiar contraseña: $e",
                        style: GoogleFonts.sen(),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
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

  /// 3) Cerrar Sesión
  void _cerrarSesion() {
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
                  // Redirigir a la pantalla de inicio de sesión
                  Navigator.pushReplacementNamed(context, '/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Sesión cerrada.",
                        style: GoogleFonts.sen(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Error al cerrar sesión: $e",
                        style: GoogleFonts.sen(),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
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
