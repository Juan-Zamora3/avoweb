// lib/screens/murousuario_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MuroUsuarioScreen extends StatefulWidget {
  const MuroUsuarioScreen({Key? key}) : super(key: key);

  @override
  State<MuroUsuarioScreen> createState() => _MuroUsuarioScreenState();
}

class _MuroUsuarioScreenState extends State<MuroUsuarioScreen> {
  /// Definición de la paleta de colores
  final Color primaryColor = const Color(0xFFD1D92C); // Verde Lima
  final Color secondaryColor = const Color(0xFFFCC039); // Amarillo
  final Color blackColor = Colors.black;

  String nombreUsuario = 'Usuario'; // Variable para almacenar el nombre del usuario
  bool isLoadingUser = true; // Estado de carga para el nombre del usuario

  @override
  void initState() {
    super.initState();
    _loadNombreUsuario();
  }

  /// Función para cargar el nombre del usuario desde Firestore
  Future<void> _loadNombreUsuario() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final docUser = await FirebaseFirestore.instance
            .collection('trabajadores')
            .doc(uid)
            .get();

        if (docUser.exists) {
          final data = docUser.data()!;
          setState(() {
            nombreUsuario = data['nombre'] ?? 'Usuario';
          });
        }
      }
    } catch (e) {
      print("Error al cargar el nombre del usuario: $e");
      // Puedes manejar errores aquí, por ejemplo, mostrando un mensaje al usuario
    } finally {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  /// Construye cada tarjeta de notificación con interactividad
  Widget _buildNotificacionCard(BuildContext context, Map<String, dynamic> data) {
    String mensaje = data['mensaje'] ?? 'Sin mensaje';
    Timestamp timestamp = data['fecha'] ?? Timestamp.now();
    DateTime fecha = timestamp.toDate();
    String formattedDate =
        "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";

    return Dismissible(
      key: Key(data['id'] ?? UniqueKey().toString()), // Asegura que cada Dismissible tenga una clave única
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // Eliminar la notificación de Firestore
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
          leading: Icon(Icons.notifications, color: secondaryColor, size: 30), // Color ajustado
          title: Text(
            mensaje,
            style: GoogleFonts.sen(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            formattedDate,
            style: GoogleFonts.sen(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: IconButton(
            icon: Icon(Icons.mark_email_read, color: primaryColor),
            onPressed: () {
              // Acción al presionar el botón (por ejemplo, marcar como leída)
              // Implementa la lógica según tus necesidades
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificación marcada como leída')),
              );
            },
          ),
          onTap: () {
            // Acción al tocar la notificación (por ejemplo, mostrar detalles)
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Detalles de la Notificación'),
                content: Text(mensaje),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cerrar', style: GoogleFonts.sen(color: primaryColor)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construye la lista de notificaciones
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
            data['id'] = doc.id; // Añadir el ID del documento para acciones posteriores
            return _buildNotificacionCard(context, data);
          },
        );
      },
    );
  }

  /// Cabecera de la pantalla con diseño integrado
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black87,
        image: const DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'), // Asegúrate de tener esta imagen
          fit: BoxFit.cover, // Ajusta la imagen para cubrir toda el área
          colorFilter: ColorFilter.mode(
            Colors.black38, // Ajusta la opacidad del filtro
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
              backgroundColor: secondaryColor, // Color ajustado según la paleta
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: isLoadingUser
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Column(
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
                      Text(
                        "Tus Notificaciones",
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

  /// Diseño Completo de la Pantalla con interactividad mejorada
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // No necesitas un AppBar si ya tienes un encabezado personalizado
      body: Column(
        children: [
          _buildHeader(context),
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
    );
  }
}
