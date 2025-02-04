import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
      print("Inicio del proceso de login.");
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // 1) Intentar iniciar sesión con Firebase Auth (Admins)
      try {
        print("Intentando autenticar como admin con FirebaseAuth.");
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        final String? uid = userCredential.user?.uid;
        print("Autenticación exitosa. UID: $uid");

        if (uid == null) {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop(); // Cerrar indicador de carga
          _showDialog("Error de autenticación. Inténtalo nuevamente.");
          return;
        }

        // Obtener el doc del admin en Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users') // Colección de admins
            .doc(uid)
            .get();
        print("Datos del admin en Firestore: ${userDoc.exists}");

        FocusScope.of(context).unfocus();
        Navigator.of(context).pop(); // Cerrar indicador de carga

        if (!userDoc.exists) {
          _showDialog("Usuario admin no encontrado en la base de datos.");
          return;
        }

        final role = userDoc['role'] ?? 'user';
        print("Rol del usuario (admin): $role");

        // Guardar en SharedPreferences (OPCIONAL) si el user marcó "Recordar"
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('role', role);
          await prefs.setString('email', email);
          // Los admins quizás no necesiten 'trabajadorId', omitirlo o usar otra clave
        }

        // Redirigir
        if (role == 'admin') {
          print("Redirigiendo a Home Admin.");
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showDialog("Rol no reconocido. Contacta al administrador.");
        }
        return;
      } on FirebaseAuthException catch (e) {
        // Si falla, se intenta login como trabajador
        print("Error de Firebase Auth (admin): ${e.code} - ${e.message}");
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          print("Continuar con login de trabajador en Firestore...");
        } else if (e.code == 'invalid-email') {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop(); // Cerrar indicador de carga
          _showDialog("Correo electrónico inválido.");
          return;
        } else if (e.code == 'wrong-password') {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop(); // Cerrar indicador de carga
          _showDialog("Contraseña incorrecta.");
          return;
        } else {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop(); // Cerrar indicador de carga
          _showDialog("Error de inicio de sesión: ${e.message}");
          return;
        }
      }

      // 2) Autenticar como trabajador (User) por Firestore
      print("Buscando trabajador en Firestore con correo: $email");
      final userQuery = await FirebaseFirestore.instance
          .collection('trabajadores')
          .where('correo', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("Trabajador no encontrado en Firestore.");
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop(); // Cerrar indicador de carga
        _showDialog("Usuario no encontrado.");
        return;
      }

      final trabajadorDoc = userQuery.docs.first;
      final data = trabajadorDoc.data() as Map<String, dynamic>;
      print("Datos del trabajador obtenidos: $data");

      // 3) Verificar contraseña (comparación directa)
      final storedPassword = data['contrasena'] ?? '';
      print("Contraseña almacenada: $storedPassword");
      print("Contraseña ingresada: $password");

      if (password != storedPassword) {
        print("Contraseña incorrecta.");
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop(); // Cerrar indicador de carga
        _showDialog("Contraseña incorrecta.");
        return;
      }

      // 4) Obtener rol
      final role = data['role'] ?? 'user';
      print("Rol del trabajador: $role");

      // 5) Guardar siempre el trabajadorId para poder ingresar a HomeScreenUser
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('trabajadorId', trabajadorDoc.id);

      // Si marcó 'Recordar', almacenamos extra
      if (_rememberMe) {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', role);
        await prefs.setString('email', email);
      }

      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(); // Cerrar indicador de carga

      // 6) Redirigir
      if (role == 'user') {
        print("Redirigiendo a Home User.");
        Navigator.pushReplacementNamed(context, '/homeUser');
      } else {
        _showDialog("Rol no reconocido. Contacta al administrador.");
      }
    } catch (e) {
      print("Error inesperado en el proceso de login: $e");
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(); // Cerrar indicador de carga
      _showDialog("Error inesperado: $e");
    }
  }

  // Validar correo/contraseña
  bool _validateInputs() {
    bool isValid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validar correo
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

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Advertencia"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          _buildTextField(
            'CORREO ELECTRÓNICO',
            'example@gmail.com',
            _emailController,
            errorText: _emailError,
          ),
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

  Widget _buildTextField(
      String label,
      String hint,
      TextEditingController controller, {
        String? errorText,
      }) {
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
                setState(() => _obscurePassword = !_obscurePassword);
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
                setState(() => _rememberMe = value!);
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
        // Aquí podrías agregar un botón "¿Olvidaste tu contraseña?" si quieres
      ],
    );
  }
}
