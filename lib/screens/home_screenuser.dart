
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'canjeusuario_screen.dart'; // Asegúrate de que la ruta sea correcta
import 'historialcanje_screen.dart'; // Asegúrate de que la ruta sea correcta
import 'ajustes_user.dart'; // Asegúrate de que la ruta sea correcta
import 'murousuario_screen.dart'; // Importa la nueva pantalla
import 'catalogouser_screen.dart';
class HomeScreenUser extends StatefulWidget {
  const HomeScreenUser({Key? key}) : super(key: key);

  @override
  State<HomeScreenUser> createState() => _HomeScreenUserState();
}

class _HomeScreenUserState extends State<HomeScreenUser> {
  String uid = '';
  String nombreUsuario = 'Usuario'; // Variable para almacenar el nombre del usuario
  int userPoints = 0;
  int nextGoal = 1000; // Meta siguiente
  bool isLoadingUser = true; // Estado de carga para los datos del usuario
  bool isLoadingTopWorkers = true; // Estado de carga para los trabajadores top

  List<Map<String, dynamic>> topWorkers = [];

  int _selectedIndex = 0; // Índice actual de la barra de navegación inferior

  // Definición de la paleta de colores
  final Color primaryColor = const Color(0xFFD1D92C); // #D1D92C
  final Color secondaryColor = const Color(0xFFFCC039); // #FCC039
  final Color blackColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadTrabajadorId(); // Llama a la función para cargar el trabajadorId
  }

  /// Función para cargar el trabajadorId desde SharedPreferences
  Future<void> _loadTrabajadorId() async {
    setState(() {
      isLoadingUser = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('trabajadorId'); // Recupera el trabajadorId

      if (id == null || id.isEmpty) {
        // Si no hay trabajadorId, redirige al inicio de sesión
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      setState(() {
        uid = id; // Asigna el trabajadorId a uid
      });

      await _loadUserData(); // Carga los datos del usuario
      await _loadTopWorkers(); // Carga el ranking
    } catch (e) {
      print("Error al cargar el trabajadorId: $e");
    } finally {
      setState(() {
        isLoadingUser = false;
      });
    }
  }


  /// Función para cargar los datos del usuario, incluyendo el nombre y puntos
  Future<void> _loadUserData() async {
    setState(() {
      isLoadingUser = true;
    });
    try {
      final docUser = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(uid)
          .get();
      if (docUser.exists) {
        final data = docUser.data()!;
        setState(() {
          nombreUsuario = data['nombre'] ?? 'Usuario'; // Obtener el nombre del usuario
          userPoints = data['puntos'] ?? 0;
          // Calcular meta en tramos de 1000
          nextGoal = ((userPoints ~/ 1000) + 1) * 1000;
        });
      }
    } catch (e) {
      print("Error al cargar usuario: $e");
    } finally {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  /// Función para cargar los trabajadores top
  Future<void> _loadTopWorkers() async {
    setState(() {
      isLoadingTopWorkers = true;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('trabajadores')
          .orderBy('puntos', descending: true)
          .limit(3)
          .get();

      setState(() {
        topWorkers = snap.docs.map((doc) {
          final d = doc.data();
          return {
            'nombre': d['nombre'] ?? 'N/A',
            'puntos': d['puntos'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      print("Error al cargar ranking: $e");
    } finally {
      setState(() {
        isLoadingTopWorkers = false;
      });
    }
  }

  /// Función para manejar la selección de ítems en la barra de navegación inferior
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // Si se selecciona "Inicio", refrescar los datos
      _loadUserData();
      _loadTopWorkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildHomeContent(),
      CanjeUsuarioScreen(trabajadorId: uid), // Asegúrate de que esta clase exista
      const HistorialCanjeScreen(), // Asegúrate de que esta clase exista
      const MuroUsuarioScreen(), // Nueva pantalla de Notificaciones
      const CatalogoUserScreen(),
      const AjustesUserScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: (_selectedIndex == 0 && (isLoadingUser || isLoadingTopWorkers))
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Contenido de la pantalla "Inicio"
  Widget _buildHomeContent() {
    return Stack(
      children: [
        // Fondo de pantalla
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildUserPointsCard(),
                      _buildRankingSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Cabecera con saludo y avatar
  Widget _buildHeader() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black87,
        image: const DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'),
          fit: BoxFit.cover, // Ajusta la imagen para cubrir toda el área
          colorFilter: ColorFilter.mode(
            Colors.black38, // Ajustado para menor opacidad
            BlendMode.darken,
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: secondaryColor,
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hola, $nombreUsuario!",
                    style: GoogleFonts.sen(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.white70),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // Navegar a la pantalla de notificaciones
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MuroUsuarioScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Ver Notificaciones",
                          style: GoogleFonts.sen(
                            color: Colors.white70,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de puntos del usuario
  Widget _buildUserPointsCard() {
    final remaining = nextGoal - userPoints;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "¡Estás a solo $remaining puntos de conseguir $nextGoal!",
              style: GoogleFonts.sen(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (userPoints / nextGoal).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              color: primaryColor,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$userPoints puntos",
                  style: GoogleFonts.sen(
                    fontSize: 14,
                    color: blackColor,
                  ),
                ),
                Text(
                  "$nextGoal puntos",
                  style: GoogleFonts.sen(
                    fontSize: 14,
                    color: blackColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de ranking (Top 3)
  Widget _buildRankingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ranking (Top 3)",
            style: GoogleFonts.sen(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: blackColor,
            ),
          ),
          const SizedBox(height: 10),
          isLoadingTopWorkers
              ? const Center(child: CircularProgressIndicator())
              : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) {
              if (index >= topWorkers.length) {
                return Column(
                  children: const [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    SizedBox(height: 5),
                    Text("N/A"),
                    Text(
                      "0 pts",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                );
              }
              final worker = topWorkers[index];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: secondaryColor,
                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    worker['nombre'],
                    style: GoogleFonts.sen(
                      color: blackColor,
                    ),
                  ),
                  Text(
                    "${worker['puntos']} pts",
                    style: GoogleFonts.sen(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Barra de navegación inferior con el nuevo ítem de Notificaciones
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed, // Permite más de 3 ítems
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard),
          label: 'Canjes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Historial',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notificaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store), // ✅ NUEVO: Icono de catálogo
          label: 'Catálogo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Ajustes',
        ),
      ],
    );
  }
}