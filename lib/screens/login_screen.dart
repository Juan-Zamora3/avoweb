import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Variables para validaciones
  String? _emailError;
  String? _passwordError;

  // Función para iniciar sesión
  void _login() async {
    // Resetear errores
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validar entradas
    bool isValid = _validateInputs();
    if (!isValid) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Intentar iniciar sesión con Firebase Authentication
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // UID del usuario autenticado
      final String? uid = userCredential.user?.uid;

      // Obtener datos del usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      Navigator.of(context).pop(); // Cerrar el indicador de carga

      if (!userDoc.exists) {
        _showDialog("Usuario no encontrado en la base de datos.");
        return;
      }

      final role = userDoc['role'];

      // Guardar sesión en SharedPreferences si se selecciona "Recordar"
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', role);
      }

      // Redirigir según el rol
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (role == 'user') {
        Navigator.pushReplacementNamed(context, '/homeUser');
      } else {
        _showDialog("Rol no reconocido.");
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Cerrar el indicador de carga
      if (e.code == 'user-not-found') {
        _showDialog("Usuario no encontrado.");
      } else if (e.code == 'wrong-password') {
        _showDialog("Contraseña incorrecta.");
      } else if (e.code == 'invalid-email') {
        _showDialog("Correo electrónico inválido.");
      } else {
        _showDialog("Error de inicio de sesión: ${e.message}");
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar el indicador de carga
      _showDialog("Error inesperado: $e");
    }
  }

  // Función de validación de entradas
  bool _validateInputs() {
    bool isValid = true;
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Validar correo electrónico
    if (email.isEmpty) {
      setState(() {
        _emailError = "El correo electrónico no puede estar vacío.";
      });
      isValid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        _emailError = "Ingresa un correo electrónico válido.";
      });
      isValid = false;
    }

    // Validar contraseña
    if (password.isEmpty) {
      setState(() {
        _passwordError = "La contraseña no puede estar vacía.";
      });
      isValid = false;
    } else if (password.length < 6) {
      setState(() {
        _passwordError = "La contraseña debe tener al menos 6 caracteres.";
      });
      isValid = false;
    }

    return isValid;
  }

  // Mostrar alertas en una pestaña emergente
  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Advertencia"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar la pestaña emergente
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }

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
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Inicio de Sesión',
              style: GoogleFonts.sen(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Inicia sesión con una cuenta ya existente',
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

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 250,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
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
          _buildTextField('CORREO ELECTRÓNICO', 'example@gmail.com', _emailController, errorText: _emailError),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildOptionsRow(),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _login,
            child: Text(
              'INICIAR SESIÓN',
              style: GoogleFonts.sen(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sen(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[200],
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTRASEÑA',
          style: GoogleFonts.sen(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '********',
            filled: true,
            fillColor: Colors.grey[200],
            errorText: _passwordError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value!;
                });
              },
            ),
            Text(
              'Recordar',
              style: GoogleFonts.sen(
                color: Colors.black54,
              ),
            ),
          ],
        ),
        // Eliminado el botón de "¿Olvidaste tu contraseña?"
      ],
    );
  }
}
