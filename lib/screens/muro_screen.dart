// lib/screens/muro_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MuroScreen extends StatefulWidget {
  const MuroScreen({Key? key}) : super(key: key);

  @override
  _MuroScreenState createState() => _MuroScreenState();
}

class _MuroScreenState extends State<MuroScreen> {
  final TextEditingController _mensajeController = TextEditingController();

  /// Agrega un nuevo mensaje al muro
  Future<void> _agregarMensaje() async {
    String mensaje = _mensajeController.text.trim();
    if (mensaje.isEmpty) return;

    await FirebaseFirestore.instance.collection('muro').add({
      'mensaje': mensaje,
      'fecha': Timestamp.now(),
      'admin': true, // Puedes ajustar esto según tu lógica de autenticación
    });

    _mensajeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificación agregada correctamente.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Edita un mensaje existente en el muro
  Future<void> _editarMensaje(String docId, String mensajeActual) async {
    _mensajeController.text = mensajeActual;

    await showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar el diálogo al tocar fuera
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 80% de ancho
            height: 250, // Tamaño fijo
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Editar Notificación',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _mensajeController,
                          decoration: const InputDecoration(
                            hintText: 'Actualiza tu mensaje aquí',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null, // Permite múltiples líneas
                          maxLength: 300, // Longitud máxima del mensaje
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _mensajeController.clear();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          String mensajeEditado = _mensajeController.text.trim();
                          if (mensajeEditado.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('muro')
                                .doc(docId)
                                .update({
                              'mensaje': mensajeEditado,
                              'fecha': Timestamp.now(), // Actualiza la fecha de edición
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Notificación actualizada correctamente.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          _mensajeController.clear();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Guardar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Elimina un mensaje del muro
  Future<void> _eliminarMensaje(String docId) async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Notificación'),
          content: const Text('¿Estás seguro de que deseas eliminar este mensaje?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                confirm = true;
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        );
      },
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection('muro').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notificación eliminada correctamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Muestra un cuadro de diálogo para agregar un nuevo mensaje
  void _mostrarAgregarMensajeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar el diálogo al tocar fuera
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 80% de ancho
            height: 250, // Tamaño fijo
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Agregar Nueva Notificación',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _mensajeController,
                          decoration: const InputDecoration(
                            hintText: 'Escribe tu mensaje aquí',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null, // Permite múltiples líneas
                          maxLength: 300, // Longitud máxima del mensaje
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _mensajeController.clear();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _agregarMensaje();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construye cada tarjeta de mensaje
  Widget _buildMensajeCard(String docId, Map<String, dynamic> data) {
    String mensaje = data['mensaje'] ?? '';
    Timestamp timestamp = data['fecha'] ?? Timestamp.now();
    DateTime fecha = timestamp.toDate();
    String formattedDate =
        "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.message, color: Colors.amber),
        title: Text(
          mensaje,
          style: GoogleFonts.sen(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          formattedDate,
          style: GoogleFonts.sen(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'editar') {
              _editarMensaje(docId, mensaje);
            } else if (value == 'eliminar') {
              _eliminarMensaje(docId);
            }
          },
          icon: const Icon(Icons.more_vert),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'editar',
              child: Text('Editar'),
            ),
            const PopupMenuItem<String>(
              value: 'eliminar',
              child: Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el encabezado similar al de HomeScreen
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black38, // Ajustado para menor opacidad
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Row(
          children: [
            // Avatar con ícono de Flutter
            Stack(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/avatar.png'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.amber[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            // Saludo con ícono
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hola, Administrador.",
                    style: GoogleFonts.sen(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Gestiona las notificaciones aquí.",
                    style: GoogleFonts.sen(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Puedes agregar otros íconos o widgets aquí si es necesario
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo gris claro para contraste
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                final mensajes = snapshot.data!.docs;

                if (mensajes.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay notificaciones.',
                      style: GoogleFonts.sen(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Puedes implementar la lógica de refresco si es necesario
                    // Por ejemplo, recargar los datos de Firestore
                  },
                  child: ListView.builder(
                    physics:
                    const AlwaysScrollableScrollPhysics(), // Para que funcione el RefreshIndicator
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) {
                      var doc = mensajes[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return _buildMensajeCard(doc.id, data);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarAgregarMensajeDialog,
        backgroundColor: Colors.amber[700],
        child: const Icon(Icons.add, size: 30),
        tooltip: 'Agregar Notificación',
      ),
    );
  }
}
