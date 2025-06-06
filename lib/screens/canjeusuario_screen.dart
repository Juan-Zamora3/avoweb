import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CanjeUsuarioScreen extends StatefulWidget {
  final String trabajadorId;

  const CanjeUsuarioScreen({Key? key, required this.trabajadorId})
      : super(key: key);

  @override
  State<CanjeUsuarioScreen> createState() => _CanjeUsuarioScreenState();
}

class _CanjeUsuarioScreenState extends State<CanjeUsuarioScreen> {
  String nombreUsuario = 'Usuario';
  String? fotoPerfil; // Base64
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Carga el nombre y la foto de perfil del trabajador
  Future<void> _loadUserData() async {
    setState(() => isLoadingUser = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
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
      backgroundColor: Colors.black, // Fondo negro detrás
      body: SafeArea(
        child: Stack(
          children: [
            // Imagen de fondo
            Container(
              width: double.infinity,
              height: double.infinity,
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
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: _buildPanelContent(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Cabecera con "Canje de puntos" y "Hola, <nombre>"
  Widget _buildHeader() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: isLoadingUser
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUserAvatar(fotoPerfil),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Canje de puntos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sen(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hola, $nombreUsuario!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sen(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Avatar base64
  Widget _buildUserAvatar(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) {
      return const CircleAvatar(
        radius: 30,
        backgroundColor: Colors.amber,
        child: Icon(Icons.person, color: Colors.white, size: 30),
      );
    }
    try {
      final bytes = base64Decode(base64Str);
      return CircleAvatar(
        radius: 30,
        backgroundImage: MemoryImage(bytes),
      );
    } catch (_) {
      return const CircleAvatar(
        radius: 30,
        backgroundColor: Colors.amber,
        child: Icon(Icons.person, color: Colors.white, size: 30),
      );
    }
  }

  /// Contenido principal (puntos, lista de incentivos)
  Widget _buildPanelContent(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('No se encontraron datos del trabajador.'),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        return Column(
          children: [
            _buildRowPuntosYBoton(context, data),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Incentivos a obtener",
                  style: GoogleFonts.sen(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildIncentivosList(context)),
          ],
        );
      },
    );
  }

  /// Tarjeta de puntos + botón
  Widget _buildRowPuntosYBoton(BuildContext context, Map<String, dynamic> data) {
    final int puntos = data['puntos'] is int ? data['puntos'] : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Tarjeta de puntos
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Puntos disponibles:',
                      style: GoogleFonts.sen(fontSize: 18, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$puntos',
                      style: GoogleFonts.sen(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A90E2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            onPressed: () => _showCanjeDialog(context, puntos),
            child: Text(
              'Canjear Puntos',
              style: GoogleFonts.sen(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de incentivos
  Widget _buildIncentivosList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('incentivos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No hay incentivos disponibles.",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          );
        }

        final incentivos = snapshot.data!.docs;
        return ListView.builder(
          itemCount: incentivos.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final incentivo = incentivos[index];
            final incentivoData = incentivo.data() as Map<String, dynamic>? ?? {};
            final String nombre = incentivoData['nombre'] ?? 'Incentivo';
            final String descripcion =
                incentivoData['descripcion'] ?? 'Sin descripción';
            final int cantidad = incentivoData['cantidad'] is int
                ? incentivoData['cantidad']
                : 0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.card_giftcard, color: Colors.amber[700], size: 24),
                ),
                title: Text(
                  nombre,
                  style: GoogleFonts.sen(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  descripcion,
                  style: GoogleFonts.sen(color: Colors.black54, fontSize: 14),
                ),
                trailing: Text(
                  '$cantidad pts',
                  style: GoogleFonts.sen(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Diálogo para canjear puntos
  void _showCanjeDialog(BuildContext context, int puntosDisponibles) {
    final TextEditingController puntosController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Canjear Puntos',
            style: GoogleFonts.sen(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1 punto = 1 peso', style: GoogleFonts.sen(color: Colors.black54)),
              const SizedBox(height: 10),
              Text('Puntos disponibles: $puntosDisponibles',
                  style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: puntosController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Puntos a canjear',
                  labelStyle: GoogleFonts.sen(),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar', style: GoogleFonts.sen()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final int puntosACanjear = int.tryParse(puntosController.text) ?? 0;
                if (puntosACanjear <= 0 || puntosACanjear > puntosDisponibles) {
                  Navigator.of(ctx).pop();
                  _showErrorDialog(context, 'Cantidad inválida o excede los disponibles.');
                  return;
                }
                try {
                  // Obtener el nombre REAL del trabajador
                  final trabajadorSnap = await FirebaseFirestore.instance
                      .collection('trabajadores')
                      .doc(widget.trabajadorId)
                      .get();
                  final trabajadorData = trabajadorSnap.data() ?? {};
                  final String nombreTrabajador =
                      trabajadorData['nombre'] ?? 'Sin nombre';

                  // (1) Actualizar puntos
                  await FirebaseFirestore.instance
                      .collection('trabajadores')
                      .doc(widget.trabajadorId)
                      .update({
                    'puntos': puntosDisponibles - puntosACanjear,
                  });

                  // (2) Guardar en historial
                  await FirebaseFirestore.instance
                      .collection('historial_puntos')
                      .add({
                    'trabajadorId': widget.trabajadorId,
                    'nombreTrabajador': nombreTrabajador,
                    'nombreIncentivo': 'Descripción canje',
                    'descripcion': 'Canje de puntos',
                    'cantidad': puntosACanjear,
                    'fecha': DateTime.now(),
                    'tipo': 'canjeado',
                  });

                  Navigator.of(ctx).pop();
                  _showSuccessDialog(context, 'Canje realizado con éxito.');
                } catch (e) {
                  Navigator.of(ctx).pop();
                  _showErrorDialog(context, 'Ocurrió un error al realizar el canje.');
                }
              },
              child: Text('Canjear', style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Diálogo de error
  void _showErrorDialog(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFFFE5E5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error',
                  style: GoogleFonts.sen(
                    color: Colors.redAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sen(color: Colors.black87, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cerrar', style: GoogleFonts.sen(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Diálogo de éxito
  void _showSuccessDialog(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFE4F7E4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                Text(
                  '¡Éxito!',
                  style: GoogleFonts.sen(
                    color: Colors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sen(color: Colors.black87, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cerrar', style: GoogleFonts.sen(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
