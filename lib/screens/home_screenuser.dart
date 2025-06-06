import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'canjeusuario_screen.dart';
import 'historialcanje_screen.dart';
import 'ajustes_user.dart';
import 'murousuario_screen.dart';
import 'catalogouser_screen.dart';

class HomeScreenUser extends StatefulWidget {
  const HomeScreenUser({Key? key}) : super(key: key);

  @override
  State<HomeScreenUser> createState() => _HomeScreenUserState();
}

class _HomeScreenUserState extends State<HomeScreenUser> {
  String uid = '';
  String nombreUsuario = 'Usuario';
  String? fotoPerfil; // Guardar la foto de perfil base64
  int userPoints = 0;
  int nextGoal = 1000;
  bool isLoadingUser = true;
  bool isLoadingTopWorkers = true;

  List<Map<String, dynamic>> topWorkers = [];
  List<String> imageBase64List = [];

  int _selectedIndex = 0;

  final Color primaryColor = const Color(0xFFD1D92C);
  final Color secondaryColor = const Color(0xFFFCC039);
  final Color blackColor = Colors.black;

  // PageView controller para el carrusel
  late PageController _pageController;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadTrabajadorId();
    _loadImages();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Carga el trabajadorId y llama a los demás métodos
  Future<void> _loadTrabajadorId() async {
    setState(() => isLoadingUser = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('trabajadorId');
      if (id == null || id.isEmpty) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() => uid = id);

      await _loadUserData();
      await _loadTopWorkers();
    } catch (e) {
      print("Error al cargar el trabajadorId: $e");
    } finally {
      setState(() => isLoadingUser = false);
    }
  }

  /// Carga los datos del usuario (nombre, puntos, fotoPerfil, etc.)
  Future<void> _loadUserData() async {
    setState(() => isLoadingUser = true);
    try {
      final docUser = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(uid)
          .get();
      if (docUser.exists) {
        final data = docUser.data()!;
        setState(() {
          nombreUsuario = data['nombre'] ?? 'Usuario';
          userPoints = data['puntos'] ?? 0;
          nextGoal = ((userPoints ~/ 1000) + 1) * 1000;

          // Foto de perfil (base64)
          fotoPerfil = data['fotoPerfil'] as String?; // null si no existe
        });
      }
    } catch (e) {
      print("Error al cargar usuario: $e");
    } finally {
      setState(() => isLoadingUser = false);
    }
  }

  /// Carga top 3 para el ranking (incluye fotoPerfil)
  Future<void> _loadTopWorkers() async {
    setState(() => isLoadingTopWorkers = true);
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
            'fotoPerfil': d['fotoPerfil'] ?? null, // base64 o null
          };
        }).toList();
      });
    } catch (e) {
      print("Error al cargar ranking: $e");
    } finally {
      setState(() => isLoadingTopWorkers = false);
    }
  }

  /// Carga imágenes base64 del carrusel
  Future<void> _loadImages() async {
    try {
      final imagesSnapshot = await FirebaseFirestore.instance
          .collection('carrusel')
          .orderBy('fecha', descending: true)
          .get();
      setState(() {
        imageBase64List = imagesSnapshot.docs
            .map((doc) => doc['base64'] as String)
            .toList();
      });
      _startAutoScroll();
    } catch (e) {
      print("Error al cargar imágenes: $e");
    }
  }

  /// Inicia auto-scroll del carrusel si hay más de una imagen
  void _startAutoScroll() {
    _carouselTimer?.cancel();
    if (imageBase64List.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_pageController.hasClients) {
          int nextPage = _pageController.page!.round() + 1;
          if (nextPage >= imageBase64List.length) {
            nextPage = 0;
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  /// Maneja la navegación inferior
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      _loadUserData();
      _loadTopWorkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildHomeContent(),
      CanjeUsuarioScreen(trabajadorId: uid),
      const HistorialCanjeScreen(),
      MuroUsuarioScreen(trabajadorId: uid),
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

  /// Contenido principal (cabecera, tarjeta de puntos, ranking, carrusel)
  Widget _buildHomeContent() {
    return Stack(
      children: [
        // Fondo negro con imagen
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
            // Cabecera
            _buildHeader(),

            // Sección blanca con puntos, ranking y carrusel
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
                      const SizedBox(height: 20),
                      _buildUserPointsCard(),
                      _buildRankingSection(),
                      const SizedBox(height: 20),
                      // Carrusel al final, más pequeño
                      SizedBox(
                        height: 150,
                        child: _buildCarousel(),
                      ),
                      const SizedBox(height: 20),
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

  /// Cabecera con saludo y foto de perfil
  Widget _buildHeader() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black87,
        image: const DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black38,
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
            // Si fotoPerfil != null, la decodificamos, sino ícono
            _buildUserAvatar(fotoPerfil),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MuroUsuarioScreen( trabajadorId: uid,),
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

  /// Construye un avatar a partir de la base64
  Widget _buildUserAvatar(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: secondaryColor,
        child: const Icon(Icons.person, color: Colors.white, size: 40),
      );
    }
    try {
      final bytes = base64Decode(base64Str);
      return CircleAvatar(
        radius: 40,
        backgroundImage: MemoryImage(bytes),
      );
    } catch (_) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: secondaryColor,
        child: const Icon(Icons.person, color: Colors.white, size: 40),
      );
    }
  }

  /// Carrusel con PageView
  Widget _buildCarousel() {
    if (imageBase64List.isEmpty) return const SizedBox();

    return PageView.builder(
      controller: _pageController,
      itemCount: imageBase64List.length,
      itemBuilder: (context, index) {
        final base64Str = imageBase64List[index];
        final bytes = base64Decode(base64Str);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      },
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
                  style: GoogleFonts.sen(fontSize: 14, color: blackColor),
                ),
                Text(
                  "$nextGoal puntos",
                  style: GoogleFonts.sen(fontSize: 14, color: blackColor),
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
          if (isLoadingTopWorkers)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (index) {
                if (index >= topWorkers.length) {
                  return _buildRankingItem(
                    nombre: "N/A",
                    puntos: 0,
                    fotoPerfil: null,
                  );
                }
                final worker = topWorkers[index];
                return _buildRankingItem(
                  nombre: worker['nombre'],
                  puntos: worker['puntos'],
                  fotoPerfil: worker['fotoPerfil'],
                );
              }),
            ),
        ],
      ),
    );
  }

  /// Construye un item del ranking (avatar, nombre, puntos)
  Widget _buildRankingItem({
    required String nombre,
    required int puntos,
    required String? fotoPerfil,
  }) {
    return SizedBox(
      width: 80, // Ajusta para evitar romper layout
      child: Column(
        children: [
          _buildUserAvatarRanking(fotoPerfil),
          const SizedBox(height: 5),
          Text(
            nombre,
            style: GoogleFonts.sen(color: blackColor, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Para nombres largos
            textAlign: TextAlign.center,
          ),
          Text(
            "$puntos pts",
            style: GoogleFonts.sen(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// Avatar para ranking (más pequeño)
  Widget _buildUserAvatarRanking(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: secondaryColor,
        child: const Icon(Icons.person, color: Colors.white, size: 30),
      );
    }
    try {
      final bytes = base64Decode(base64Str);
      return CircleAvatar(
        radius: 30,
        backgroundImage: MemoryImage(bytes),
      );
    } catch (_) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: secondaryColor,
        child: const Icon(Icons.person, color: Colors.white, size: 30),
      );
    }
  }

  /// Barra de navegación inferior
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Canjes'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificaciones'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Catálogo'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
      ],
    );
  }
}
