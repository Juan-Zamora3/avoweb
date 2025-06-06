import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AjustesUserScreen extends StatefulWidget {
  const AjustesUserScreen({Key? key}) : super(key: key);

  @override
  State<AjustesUserScreen> createState() => _AjustesUserScreenState();
}

class _AjustesUserScreenState extends State<AjustesUserScreen> {
  String? _trabajadorId;
  bool _isLoading = true;

  // Datos para vista previa en la cabecera
  String? _fotoPerfilBase64;
  String _nombreUsuario = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadTrabajadorId();
  }

  Future<void> _loadTrabajadorId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('trabajadorId');

    if (savedId == null || savedId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      setState(() {
        _trabajadorId = savedId;
      });
      await _loadUserDoc();
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Carga el documento del usuario para obtener foto y nombre
  Future<void> _loadUserDoc() async {
    if (_trabajadorId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(_trabajadorId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _fotoPerfilBase64 = data['fotoPerfil'] as String?;
          _nombreUsuario = data['nombre'] ?? 'Usuario';
        });
      }
    } catch (e) {
      print("Error al cargar usuario: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se envuelve todo en SingleChildScrollView para evitar overflows
    return Scaffold(
      backgroundColor: Colors.white,
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

  /// Cabecera con fondo, vista previa de foto de perfil y nombre
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
          colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Vista previa del avatar con ícono sobrepuesto para cambiar foto
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildUserAvatar(_fotoPerfilBase64, size: 50),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _nombreUsuario,
              style: GoogleFonts.sen(
                color: Colors.white,
                fontSize: 24,
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

  /// Construye el avatar del usuario para la cabecera; se usa size para ajustar
  Widget _buildUserAvatar(String? base64Str, {double size = 40}) {
    if (base64Str == null || base64Str.isEmpty) {
      return CircleAvatar(
        radius: size,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.black54, size: size),
      );
    }
    try {
      final bytes = base64Decode(base64Str);
      return CircleAvatar(
        radius: size,
        backgroundImage: MemoryImage(bytes),
      );
    } catch (_) {
      return CircleAvatar(
        radius: size,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.black54, size: size),
      );
    }
  }

  /// Panel de ajustes: contiene opciones de editar perfil, cambiar foto, etc.
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
          _buildAjusteOption(
            Icons.account_circle,
            "Editar Perfil",
            "Actualiza tu información",
            _editarPerfil,
          ),
          _buildAjusteOption(
            Icons.photo_camera,
            "Cambiar Foto de Perfil",
            "Actualiza tu foto de perfil",
            _pickProfileImage,
          ),
          _buildAjusteOption(
            Icons.lock,
            "Cambiar Contraseña",
            "Actualiza tu contraseña de acceso",
            _cambiarContrasena,
          ),
          const Divider(height: 30),
          _buildAjusteOption(
            Icons.logout,
            "Cerrar Sesión",
            "Salir de tu cuenta actual",
            _cerrarSesion,
          ),
        ],
      ),
    );
  }

  /// Opción de ajustes genérica
  Widget _buildAjusteOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.amber[700], size: 30),
        title: Text(title, style: GoogleFonts.sen(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: GoogleFonts.sen(color: Colors.black54, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        onTap: onTap,
      ),
    );
  }

  /// Editar Perfil: permite actualizar nombre, correo y teléfono
  Future<void> _editarPerfil() async {
    if (_trabajadorId == null) return;
    final doc = await FirebaseFirestore.instance.collection('trabajadores').doc(_trabajadorId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
    final correoCtrl = TextEditingController(text: data['correo'] ?? '');
    final telCtrl = TextEditingController(text: data['telefono'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar Perfil", style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('trabajadores').doc(_trabajadorId).update({
                  'nombre': nombreCtrl.text.trim(),
                  'correo': correoCtrl.text.trim(),
                  'telefono': telCtrl.text.trim(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
                await _loadUserDoc();
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  /// Cambiar Foto de Perfil: selecciona imagen y actualiza el campo 'fotoPerfil'
  Future<void> _pickProfileImage() async {
    try {
      if (_trabajadorId == null) return;
      final picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);
      if (imageFile == null) return;

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('trabajadores').doc(_trabajadorId).update({
        'fotoPerfil': base64Image,
      });
      setState(() {
        _fotoPerfilBase64 = base64Image;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto de perfil actualizada")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al actualizar foto: $e")));
    }
  }

  /// Cambiar Contraseña
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                final oldPass = passOldCtrl.text.trim();
                final newPass = passNewCtrl.text.trim();

                if (oldPass.isEmpty || newPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Todos los campos son obligatorios.")));
                  return;
                }
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La nueva contraseña debe tener al menos 6 caracteres.")));
                  return;
                }

                try {
                  final doc = await FirebaseFirestore.instance.collection('trabajadores').doc(_trabajadorId).get();
                  final data = doc.data();
                  if (data == null || data['contrasena'] != oldPass) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La contraseña actual es incorrecta.")));
                    return;
                  }
                  await FirebaseFirestore.instance.collection('trabajadores').doc(_trabajadorId).update({'contrasena': newPass});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña actualizada.")));
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Actualizar"),
            ),
          ],
        );
      },
    );
  }

  /// Cerrar Sesión
  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _customTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
    );
  }
}
