import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// OJO: Se elimina import 'package:firebase_auth/firebase_auth.dart';
// porque ya no lo necesitamos si vamos a usar trabajadorId directamente.

class MuroUsuarioScreen extends StatefulWidget {
  final String trabajadorId; // Recibimos el trabajadorId por parámetro

  const MuroUsuarioScreen({
    Key? key,
    required this.trabajadorId,
  }) : super(key: key);

  @override
  State<MuroUsuarioScreen> createState() => _MuroUsuarioScreenState();
}

class _MuroUsuarioScreenState extends State<MuroUsuarioScreen> {
  final Color primaryColor = const Color(0xFFD1D92C);
  final Color secondaryColor = const Color(0xFFFCC039);

  String nombreUsuario = 'Usuario';
  String? fotoPerfil; // Imagen en Base64
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Cargamos nombre y foto, usando el trabajadorId
  }

  /// Carga el nombre y la foto de perfil del usuario desde Firestore,
  /// de forma similar a como haces en CanjeUsuarioScreen.
  Future<void> _loadUserData() async {
    setState(() => isLoadingUser = true);
    try {
      final docUser = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .get();
      if (docUser.exists) {
        final data = docUser.data()!;
        setState(() {
          nombreUsuario = data['nombre'] ?? 'Usuario';
          fotoPerfil = data['fotoPerfil'] as String?;
        });
      }
    } catch (e) {
      print("Error al cargar datos del trabajador: $e");
    } finally {
      setState(() => isLoadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro de la pantalla
      body: SafeArea(
        child: Column(
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
                child: _buildNotificacionesList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header que muestra la foto de perfil y el nombre del usuario.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black87,
        image: const DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: isLoadingUser
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Row(
          children: [
            _buildUserAvatar(fotoPerfil),
            const SizedBox(width: 16),
            // Muestra el nombre y la opción "Ver Notificaciones"
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hola, $nombreUsuario!",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      Text(
                        "Ver Notificaciones",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sen(
                          color: Colors.white70,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
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

  /// Construye el avatar del usuario a partir de una imagen codificada en Base64.
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

  /// Construye la lista de notificaciones.
  Widget _buildNotificacionesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('muro')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar las notificaciones.',
              style: GoogleFonts.sen(fontSize: 16, color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notificaciones = snapshot.data!.docs;
        if (notificaciones.isEmpty) {
          return Center(
            child: Text(
              'No hay notificaciones disponibles.',
              style: GoogleFonts.sen(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: notificaciones.length,
          itemBuilder: (context, index) {
            var doc = notificaciones[index];
            var data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return _buildNotificacionCard(data);
          },
        );
      },
    );
  }

  /// Construye la tarjeta de cada notificación con la posibilidad de eliminarla (dismiss).
  Widget _buildNotificacionCard(Map<String, dynamic> data) {
    String mensaje = data['mensaje'] ?? 'Sin mensaje';
    Timestamp timestamp = data['fecha'] ?? Timestamp.now();
    DateTime fecha = timestamp.toDate();
    String formattedDate =
        "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";

    return Dismissible(
      key: Key(data['id'] ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        FirebaseFirestore.instance.collection('muro').doc(data['id']).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación eliminada')),
        );
      },
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.amber,
            child: Icon(Icons.notifications, color: Colors.white, size: 25),
          ),
          title: Text(
            mensaje,
            style: GoogleFonts.sen(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            formattedDate,
            style: GoogleFonts.sen(fontSize: 12, color: Colors.grey),
          ),
          trailing: IconButton(
            icon: Icon(Icons.mark_email_read, color: primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificación marcada como leída')),
              );
            },
          ),
        ),
      ),
    );
  }
}
