import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatalogoUserScreen extends StatefulWidget {
  const CatalogoUserScreen({Key? key}) : super(key: key);

  @override
  State<CatalogoUserScreen> createState() => _CatalogoUserScreenState();
}

class _CatalogoUserScreenState extends State<CatalogoUserScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> catalogoItems = [];
  int currentPoints = 0; // Puntos actuales del usuario

  @override
  void initState() {
    super.initState();
    _loadCatalogo();      // Cargar el catálogo de productos
    _loadUserPoints();    // Cargar puntos del trabajador
  }

  /// Carga el catálogo de productos desde Firestore
  Future<void> _loadCatalogo() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('productos')
          .orderBy('precio', descending: false)
          .get();

      setState(() {
        catalogoItems = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'nombre': data['nombre'] ?? 'Producto',
            'descripcion': data['descripcion'] ?? 'Sin descripción',
            // Aseguramos que sea int
            'precio': ((data['precio'] ?? 0) as num).toInt(),

            'imagen': data['imagen'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print("Error al cargar el catálogo: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Carga los puntos del usuario desde Firestore utilizando SharedPreferences
  Future<void> _loadUserPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trabajadorId = prefs.getString('trabajadorId');

      if (trabajadorId == null || trabajadorId.isEmpty) {
        print("No se encontró el trabajadorId en SharedPreferences.");
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(trabajadorId)
          .get();

      if (userDoc.exists) {
        setState(() {
          currentPoints = ((userDoc['puntos'] ?? 0) as num).toInt();

        });
      } else {
        print("El documento del usuario no existe en Firestore.");
      }
    } catch (e) {
      print("Error al cargar los puntos del usuario: $e");
    }
  }

  /// Muestra un AlertDialog para confirmar el canje
  void _confirmCanje(Map<String, dynamic> item) {
    // Verificamos si el usuario tiene puntos suficientes
    if (currentPoints < (item['precio'] ?? 0).toInt()) {
      _showSnackBar("No tienes suficientes puntos para este canje.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Confirmar Canje",
            style: GoogleFonts.sen(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "¿Deseas canjear ${item['nombre']} por ${item['precio']} puntos?",
            style: GoogleFonts.sen(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _realizarCanje(item);
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }

  /// Realiza el canje y actualiza puntos e historial en Firestore
  Future<void> _realizarCanje(Map<String, dynamic> item) async {
    try {
      // Cargamos nuevamente el trabajadorId de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final trabajadorId = prefs.getString('trabajadorId');

      if (trabajadorId == null || trabajadorId.isEmpty) {
        _showSnackBar("Error al realizar el canje. Trabajador no encontrado.");
        return;
      }

      // Obtenemos el nombre REAL del trabajador
      final trabajadorSnap = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(trabajadorId)
          .get();
      final trabajadorData = trabajadorSnap.data();
      final String nombreTrabajador = trabajadorData?['nombre'] ?? 'Sin nombre';

      // Calculamos los nuevos puntos
      final int newPoints = (currentPoints - (item['precio'] ?? 0) as num).toInt();

      // Actualizamos los puntos del trabajador
      await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(trabajadorId)
          .update({'puntos': newPoints});

      // Registramos el canje en el historial
      await FirebaseFirestore.instance.collection('historial_puntos').add({
        'trabajadorId': trabajadorId,
        'nombreTrabajador': nombreTrabajador,
        'productoId': item['id'],
        'nombre': item['nombre'],
        'precio': item['precio'],
        'fecha': DateTime.now(),
        'tipo': 'canjeado',
      });

      // Actualizamos los puntos en la UI
      setState(() {
        currentPoints = newPoints;
      });

      _showSnackBar("Canje realizado con éxito.");
    } catch (e) {
      print("Error al realizar el canje: $e");
      _showSnackBar("Error al realizar el canje.");
    }
  }

  /// Muestra un mensaje temporal en la parte inferior de la pantalla
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.sen())),
    );
  }

  /// Muestra una imagen desde base64 o URL
  Widget _buildImage(String imageData) {
    if (imageData.startsWith('base64:')) {
      final base64String = imageData.substring(7);
      try {
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      }
    } else if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
        },
      );
    } else {
      return const Icon(Icons.image, size: 50, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCatalogList(),
          ),
        ],
      ),
    );
  }

  /// Cabecera con imagen de fondo y puntos disponibles
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
              "Catálogo de Canjes",
              style: GoogleFonts.sen(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Selecciona productos para canjear con tus puntos",
              style: GoogleFonts.sen(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Puntos disponibles: $currentPoints",
              style: GoogleFonts.sen(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la lista principal del catálogo
  Widget _buildCatalogList() {
    if (catalogoItems.isEmpty) {
      return Center(
        child: Text(
          "No hay productos disponibles en el catálogo.",
          style: GoogleFonts.sen(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: catalogoItems.length,
      itemBuilder: (context, index) {
        final item = catalogoItems[index];
        return _buildCatalogItem(item);
      },
    );
  }

  /// Tarjeta individual de cada producto
  Widget _buildCatalogItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _confirmCanje(item),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del producto (base64 o URL)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildImage(item['imagen']),
              ),
            ),
            // Información del producto
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nombre'],
                    style: GoogleFonts.sen(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['descripcion'],
                    style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item['precio']} pts",
                    style: GoogleFonts.sen(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.amber[700],
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
}
