import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

/// Pantalla base con header y panel de contenido.
class BaseScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final String backgroundImagePath;

  const BaseScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.content,
    this.backgroundImagePath = 'assets/images/fondopantalla.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContentPanel(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        image: DecorationImage(
          image: AssetImage(backgroundImagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.sen(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.sen(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: content,
    );
  }
}

/// Pantalla que muestra el catálogo de productos.
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({Key? key}) : super(key: key);

  @override
  _CatalogoScreenState createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  /// Aquí se guardará la cadena de la imagen.
  /// Lo ideal es que esta cadena sea el contenido Base64 con el prefijo "base64:".
  String? _imageData;
  String? _productId;

  late Stream<QuerySnapshot> _productStream;

  @override
  void initState() {
    super.initState();
    _productStream = FirebaseFirestore.instance.collection('productos').snapshots();
  }

  /// Selecciona una imagen y la convierte a Base64 (con prefijo "base64:") para almacenarla.
  Future<void> _selectImageDialog(void Function(void Function()) dialogSetState) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final base64String = 'base64:$base64Image';
      dialogSetState(() {
        _imageData = base64String;
      });
      setState(() {
        _imageData = base64String;
      });
    }
  }

  /// Guarda o actualiza el producto en Firestore.
  Future<void> _saveProduct(BuildContext dialogContext) async {
    if (_formKey.currentState!.validate()) {
      final product = {
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
        'precio': int.parse(_precioController.text),
        'imagen': _imageData ?? '',
      };
      if (_productId != null) {
        await FirebaseFirestore.instance.collection('productos').doc(_productId).update(product);
      } else {
        await FirebaseFirestore.instance.collection('productos').add(product);
      }

      _nombreController.clear();
      _descripcionController.clear();
      _precioController.clear();
      setState(() {
        _imageData = null;
        _productId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado correctamente')),
      );
      Navigator.of(dialogContext).pop();
    }
  }

  Future<void> _deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('productos').doc(productId).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Producto eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Catálogo',
      subtitle: 'Lista de productos',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () => _showAddProductDialog(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text('Agregar', style: GoogleFonts.sen(color: Colors.black)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar los productos.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay productos disponibles.'));
                }

                final products = snapshot.data!.docs;

                // Usamos LayoutBuilder para determinar el número de columnas en función del ancho
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Se define un ancho mínimo deseado para cada tarjeta.
                    const double minCardWidth = 300;
                    int crossAxisCount = (constraints.maxWidth / minCardWidth).floor();
                    if (crossAxisCount < 1) crossAxisCount = 1;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        // El childAspectRatio puede ajustarse según el diseño deseado.
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onDelete: () => _deleteProduct(product.id),
                          onEdit: () => _showAddProductDialog(product),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo para agregar o editar un producto.
  void _showAddProductDialog([QueryDocumentSnapshot? product]) {
    if (product != null) {
      _productId = product.id;
      _nombreController.text = product['nombre'];
      _descripcionController.text = product['descripcion'];
      _precioController.text = product['precio'].toString();
      _imageData = product['imagen'] ?? '';
    } else {
      _productId = null;
      _nombreController.clear();
      _descripcionController.clear();
      _precioController.clear();
      _imageData = '';
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(_productId == null ? 'Agregar producto' : 'Editar producto'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) =>
                        (value == null || value.isEmpty) ? 'Por favor ingrese un nombre' : null,
                      ),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(labelText: 'Descripción'),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Por favor ingrese una descripción'
                            : null,
                      ),
                      TextFormField(
                        controller: _precioController,
                        decoration: const InputDecoration(labelText: 'Precio (en puntos)'),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                        (value == null || value.isEmpty) ? 'Por favor ingrese un precio' : null,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _selectImageDialog(dialogSetState),
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: _buildImagePreview(_imageData),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => _saveProduct(dialogContext),
                  child: Text(_productId == null ? 'Guardar' : 'Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Construye la vista previa de la imagen en el diálogo.
  Widget _buildImagePreview(String? imageData) {
    if (imageData == null || imageData.trim().isEmpty) {
      return const Center(child: Text('Seleccionar Imagen'));
    } else if (imageData.startsWith('base64:')) {
      final base64Data = imageData.substring(7);
      try {
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return const Center(child: Text('Error al cargar la imagen'));
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
          return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
        },
      );
    } else {
      // Se asume que es una ruta local (esto funcionará en móvil si el archivo existe)
      if (!kIsWeb) {
        final file = File(imageData);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
            },
          );
        }
      }
      return const Center(child: Text('Imagen inválida'));
    }
  }
}

/// Widget que muestra la tarjeta de un producto.
class ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot product;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  /// Construye la imagen del producto usando AspectRatio para que se adapte al ancho.
  Widget _buildProductImage(String imageData) {
    Widget imageWidget;

    if (imageData.trim().isEmpty) {
      imageWidget = Container(
        color: Colors.grey[300],
        child: const Center(
          child: Text(
            "Sin imagen",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    } else if (imageData.startsWith('base64:')) {
      final base64Data = imageData.substring(7);
      try {
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } catch (e) {
        imageWidget = Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        );
      }
    } else if (imageData.startsWith('http')) {
      imageWidget = Image.network(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          );
        },
      );
    } else {
      if (!kIsWeb) {
        final file = File(imageData);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              );
            },
          );
        } else {
          imageWidget = Container(
            color: Colors.grey[300],
            child: const Center(child: Text("Imagen inválida")),
          );
        }
      } else {
        imageWidget = Container(
          color: Colors.grey[300],
          child: const Center(child: Text("Imagen inválida")),
        );
      }
    }

    // Usamos AspectRatio para que la imagen se ajuste proporcionalmente.
    return AspectRatio(
      aspectRatio: 4 / 3, // Puedes ajustar este valor según el diseño deseado.
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: _buildProductImage(product['imagen'] ?? ''),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nombre'] ?? '',
                  style: GoogleFonts.sen(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  product['descripcion'] ?? '',
                  style: GoogleFonts.sen(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product['precio'] ?? 0} P',
                  style: GoogleFonts.sen(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, color: Colors.black),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
