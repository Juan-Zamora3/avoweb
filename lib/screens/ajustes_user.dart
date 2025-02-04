import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AjustesUserScreen extends StatefulWidget {
  const AjustesUserScreen({Key? key}) : super(key: key);

  @override
  State<AjustesUserScreen> createState() => _AjustesUserScreenState();
}

class _AjustesUserScreenState extends State<AjustesUserScreen> {
  String? _trabajadorId;
  bool _isLoading = true; // Estado de carga para verificar el login

  @override
  void initState() {
    super.initState();
    _loadTrabajadorId();
  }

  /// Carga el trabajadorId desde SharedPreferences
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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trabajadorId == null || _trabajadorId!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondopantalla.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(),
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
        _buildAjusteOption(Icons.account_circle, "Editar Perfil", "Actualiza tu información", _editarPerfil),
        _buildAjusteOption(Icons.lock, "Cambiar Contraseña", "Actualiza tu contraseña de acceso", _cambiarContrasena),
        const Divider(height: 30),
        _buildAjusteOption(Icons.logout, "Cerrar Sesión", "Salir de tu cuenta actual", _cerrarSesion),
      ],
    );
  }

  Widget _buildAjusteOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
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

  /// Editar Perfil
  Future<void> _editarPerfil() async {
    final doc = await FirebaseFirestore.instance.collection('trabajadores').doc(_trabajadorId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final nombreCtrl = TextEditingController(text: data['nombre']);
    final correoCtrl = TextEditingController(text: data['correo']);
    final telCtrl = TextEditingController(text: data['telefono']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar Perfil", style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customTextField(nombreCtrl, "Nombre Completo"),
              _customTextField(correoCtrl, "Correo Electrónico"),
              _customTextField(telCtrl, "Teléfono"),
            ],
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
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customTextField(passOldCtrl, "Contraseña Actual", obscureText: true),
              _customTextField(passNewCtrl, "Nueva Contraseña", obscureText: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                final doc = await FirebaseFirestore.instance.collection('trabajadores').doc(_trabajadorId).get();
                final data = doc.data();
                if (data == null || passOldCtrl.text != data['contrasena']) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña incorrecta")));
                  return;
                }
                await FirebaseFirestore.instance.collection('trabajadores').doc(_trabajadorId).update({
                  'contrasena': passNewCtrl.text.trim(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña actualizada")));
              },
              child: const Text("Actualizar"),
            ),
          ],
        );
      },
    );
  }

  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _customTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return TextField(controller: controller, obscureText: obscureText, decoration: InputDecoration(labelText: label));
  }
}
