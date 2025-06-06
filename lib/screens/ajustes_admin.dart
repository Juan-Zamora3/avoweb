import 'dart:convert'; // Para la conversión a Base64
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imágenes
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AjustesAdminScreen extends StatefulWidget {
  const AjustesAdminScreen({Key? key}) : super(key: key);

  @override
  State<AjustesAdminScreen> createState() => _AjustesAdminScreenState();
}

class _AjustesAdminScreenState extends State<AjustesAdminScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildAjustesPanel(),
            const SizedBox(height: 20),
            _buildImagesList(), // Muestra y elimina imágenes
          ],
        ),
      ),
    );
  }

  // -------------------- ENCABEZADO --------------------
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
            Colors.black26,
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

  // -------------------- PANEL DE AJUSTES --------------------
  Widget _buildAjustesPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
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

          // Cambiar Contraseña
          _buildAjusteOption(
            icon: Icons.lock,
            title: "Cambiar Contraseña",
            subtitle: "Actualiza tu contraseña de acceso",
            onTap: _cambiarContrasena,
          ),
          const Divider(height: 30, thickness: 1, color: Colors.grey),

          // Cerrar Sesión
          _buildAjusteOption(
            icon: Icons.logout,
            title: "Cerrar Sesión",
            subtitle: "Salir de tu cuenta actual",
            onTap: _cerrarSesion,
          ),
          const Divider(height: 30, thickness: 1, color: Colors.grey),

          // Botón para agregar imagen
          Center(
            child: ElevatedButton(
              onPressed: _pickImageAndUpload,
              child: Text("Agregar Imagen al Carrusel", style: GoogleFonts.sen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAjusteOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.amber[700], size: 30),
        title: Text(
          title,
          style: GoogleFonts.sen(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.sen(color: Colors.black54, fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        onTap: onTap,
      ),
    );
  }

  // -------------------- MANEJO DE IMÁGENES --------------------
  Future<void> _pickImageAndUpload() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);

      if (imageFile == null) {
        // Usuario canceló la selección
        return;
      }

      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // Subir a la colección "carrusel"
      await FirebaseFirestore.instance.collection('carrusel').add({
        'base64': base64Image,
        'fecha': FieldValue.serverTimestamp(),
      });

      _showSnackBar("Imagen agregada correctamente.", isError: false);
      setState(() {});
    } catch (e) {
      _showSnackBar("Error al agregar la imagen: $e", isError: true);
    }
  }

  /// Muestra y elimina imágenes del carrusel
  Widget _buildImagesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carrusel')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Text("No hay imágenes en el carrusel.", style: GoogleFonts.sen());
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final docId = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final base64Str = data['base64'] as String? ?? '';

              // Decodificamos la imagen para la vista previa
              final imageBytes = _tryDecodeBase64(base64Str);

              return ListTile(
                leading: (imageBytes == null)
                    ? CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.black54),
                )
                    : CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  backgroundImage: MemoryImage(imageBytes),
                ),
                title: Text(
                  "Imagen $index",
                  style: GoogleFonts.sen(),
                ),
                subtitle: Text(
                  "Tamaño base64: ${base64Str.length} caracteres",
                  style: GoogleFonts.sen(fontSize: 12, color: Colors.black54),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteImage(docId),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Intenta decodificar la imagen base64; si falla, regresa null
  Uint8List? _tryDecodeBase64(String base64Str) {
    try {
      return base64Decode(base64Str);
    } catch (e) {
      return null;
    }
  }

  Future<void> _deleteImage(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Eliminar imagen", style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
        content: Text("¿Estás seguro de que deseas eliminar esta imagen?", style: GoogleFonts.sen()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(backgroundColor: Colors.grey),
            child: Text("Cancelar", style: GoogleFonts.sen(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text("Eliminar", style: GoogleFonts.sen()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('carrusel').doc(docId).delete();
        _showSnackBar("Imagen eliminada correctamente.", isError: false);
      } catch (e) {
        _showSnackBar("Error al eliminar la imagen: $e", isError: true);
      }
    }
  }

  // -------------------- LÓGICA DE BOTONES EXISTENTES --------------------
  Future<void> _cambiarContrasena() async {
    final passOldCtrl = TextEditingController();
    final passNewCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cambiar Contraseña", style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _customTextField(passOldCtrl, "Contraseña Actual", obscureText: true),
                const SizedBox(height: 8),
                _customTextField(passNewCtrl, "Nueva Contraseña", obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Cancelar", style: GoogleFonts.sen(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                final oldPass = passOldCtrl.text.trim();
                final newPass = passNewCtrl.text.trim();

                if (oldPass.isEmpty || newPass.isEmpty) {
                  _showSnackBar("Todos los campos son obligatorios.", isError: true);
                  return;
                }
                if (newPass.length < 6) {
                  _showSnackBar("La nueva contraseña debe tener al menos 6 caracteres.", isError: true);
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) throw "No hay usuario logueado.";

                  // Reautenticar
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPass,
                  );
                  await user.reauthenticateWithCredential(cred);

                  // Actualizar contraseña
                  await user.updatePassword(newPass);

                  Navigator.of(context).pop();
                  _showSnackBar("Contraseña cambiada correctamente.", isError: false);
                } on FirebaseAuthException catch (e) {
                  Navigator.of(context).pop();
                  String errorMessage;
                  switch (e.code) {
                    case 'wrong-password':
                      errorMessage = "La contraseña actual es incorrecta.";
                      break;
                    case 'weak-password':
                      errorMessage = "La nueva contraseña es demasiado débil. Debe tener al menos 6 caracteres.";
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
              child: Text("Actualizar", style: GoogleFonts.sen()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cerrarSesion() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cerrar Sesión", style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
          content: Text("¿Estás seguro de que deseas cerrar sesión?", style: GoogleFonts.sen()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Cancelar", style: GoogleFonts.sen(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacementNamed(context, '/login');
                  _showSnackBar("Sesión cerrada exitosamente.", isError: false);
                } catch (e) {
                  _showSnackBar("Error al cerrar sesión: $e", isError: true);
                }
              },
              child: Text("Salir", style: GoogleFonts.sen()),
            ),
          ],
        );
      },
    );
  }

  // -------------------- UTILS --------------------
  void _showSnackBar(String message, {required bool isError}) {
    final snackBar = SnackBar(
      content: Text(message, style: GoogleFonts.sen()),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

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
        labelStyle: GoogleFonts.sen(fontSize: 14, color: Colors.grey.shade700),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
