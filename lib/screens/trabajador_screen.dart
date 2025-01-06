import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Pantalla Principal para Gestionar Trabajadores e Incentivos
class TrabajadorScreen extends StatefulWidget {
  const TrabajadorScreen({Key? key}) : super(key: key);

  @override
  State<TrabajadorScreen> createState() => _TrabajadorScreenState();
}

class _TrabajadorScreenState extends State<TrabajadorScreen> {
  /// Conjunto de IDs de trabajadores seleccionados
  final Set<String> _selectedWorkerIds = {};

  /// Referencia a la colección de trabajadores
  final CollectionReference _trabajadoresCollection =
  FirebaseFirestore.instance.collection('trabajadores');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),

            /// Fila que contiene el título y el FAB
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Lista de Trabajadores",
                      style: GoogleFonts.sen(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildSpeedDial(), // Insertamos el Speed Dial aquí
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// Lista de trabajadores
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _trabajadoresCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No hay trabajadores registrados.",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final trabajadores = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: trabajadores.length,
                    itemBuilder: (context, index) {
                      final trabajador = trabajadores[index];
                      return WorkerCard(
                        key: ValueKey(trabajador.id),
                        trabajador: trabajador,
                        isSelected: _selectedWorkerIds.contains(trabajador.id),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedWorkerIds.add(trabajador.id);
                            } else {
                              _selectedWorkerIds.remove(trabajador.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Encabezado con imagen de fondo y saludo
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: const BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage('assets/images/fondopantalla.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/avatar.png'),
            ),
            const SizedBox(width: 10),
            Text(
              "Hola, Administrador.",
              style: GoogleFonts.sen(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir el Speed Dial FAB dentro de la Row
  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      backgroundColor: const Color(0xFFD1D92C),
      activeBackgroundColor: const Color(0xFFD1D92C),
      overlayOpacity: 0.4,
      spacing: 12,
      spaceBetweenChildren: 12,
      direction: SpeedDialDirection.down,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: const Color(0xFFD1D92C),
          label: 'Agregar Trabajador',
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onTap: () => _showCrearTrabajadorDialog(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.star, color: Colors.white),
          backgroundColor: const Color(0xFF607D8B),
          label: 'Incentivos',
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onTap: () => _showIncentivosDialog(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.point_of_sale, color: Colors.white),
          backgroundColor: const Color(0xFFFFC107),
          label: 'Asignar Puntos',
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onTap: _selectedWorkerIds.isNotEmpty
              ? () => _showAsignarPuntosDialog(context)
              : null,
          visible: _selectedWorkerIds.isNotEmpty,
        ),
        SpeedDialChild(
          child: const Icon(Icons.edit, color: Colors.white),
          backgroundColor: const Color(0xFF009688),
          label: 'Editar Trabajador',
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onTap: _selectedWorkerIds.length == 1
              ? () => _showEditarTrabajadorDialog(
            context,
            _selectedWorkerIds.first,
          )
              : null,
          visible: _selectedWorkerIds.length == 1,
        ),
        SpeedDialChild(
          child: const Icon(Icons.delete, color: Colors.white),
          backgroundColor: const Color(0xFFD32F2F),
          label: _selectedWorkerIds.isEmpty
              ? 'Eliminar Trabajador'
              : 'Eliminar (${_selectedWorkerIds.length})',
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onTap: _selectedWorkerIds.isNotEmpty
              ? () => _deleteTrabajadores(_selectedWorkerIds)
              : null,
          visible: _selectedWorkerIds.isNotEmpty,
        ),
      ],
    );
  }

  // Diálogo para crear un trabajador
  void _showCrearTrabajadorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CrearTrabajadorDialog(),
    );
  }

  // Diálogo para editar un trabajador
  void _showEditarTrabajadorDialog(BuildContext context, String trabajadorId) {
    showDialog(
      context: context,
      builder: (context) => EditarTrabajadorDialog(trabajadorId: trabajadorId),
    );
  }

  // Eliminar múltiples trabajadores
  void _deleteTrabajadores(Set<String> trabajadorIds) async {
    bool confirm = await _showConfirmDeleteDialog(trabajadorIds.length);
    if (!confirm) return;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String id in trabajadorIds) {
        DocumentReference workerRef =
        FirebaseFirestore.instance.collection('trabajadores').doc(id);
        batch.delete(workerRef);

        // También eliminamos de la colección 'users'
        DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(id);
        batch.delete(userRef);
      }

      await batch.commit();

      setState(() {
        _selectedWorkerIds.clear();
      });

      Fluttertoast.showToast(
        msg:
        "Trabajador${trabajadorIds.length > 1 ? 'es' : ''} eliminado${trabajadorIds.length > 1 ? 's' : ''} exitosamente.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg:
        "Error al eliminar trabajador${trabajadorIds.length > 1 ? 'es' : ''}: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    }
  }

  // Diálogo de confirmación para eliminar trabajadores
  Future<bool> _showConfirmDeleteDialog(int count) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text(
          "¿Estás seguro de eliminar ${count > 1 ? 'los $count trabajadores seleccionados' : 'este trabajador'}? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancelar",
              style: GoogleFonts.sen(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Eliminar",
              style: GoogleFonts.sen(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  // Diálogo para manejar incentivos
  void _showIncentivosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => IncentivosDialog(),
    );
  }

  // Diálogo para asignar puntos
  void _showAsignarPuntosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AsignarPuntosDialog(
          selectedWorkerIds: _selectedWorkerIds,
          onAsignar: _asignarPuntos,
        );
      },
    );
  }

  // Función para asignar puntos (Suma de puntos, "tipo": "agregado")
  Future<void> _asignarPuntos(
      String incentivoId,
      String descripcion,
      int puntos,
      ) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Obtener detalles del incentivo
      DocumentSnapshot incentivoSnapshot = await FirebaseFirestore.instance
          .collection('incentivos')
          .doc(incentivoId)
          .get();

      String nombreIncentivo = incentivoSnapshot['nombre'] ?? 'Sin Nombre';
      String descIncentivo = incentivoSnapshot['descripcion'] ?? 'Sin Descripción';

      for (var workerId in _selectedWorkerIds) {
        // Obtener detalles del trabajador
        DocumentSnapshot trabajadorSnapshot = await FirebaseFirestore.instance
            .collection('trabajadores')
            .doc(workerId)
            .get();

        String nombreTrabajador = trabajadorSnapshot['nombre'] ?? 'Sin Nombre';

        // (1) Actualizar puntos en la colección 'trabajadores'
        DocumentReference trabajadorRef =
        FirebaseFirestore.instance.collection('trabajadores').doc(workerId);
        batch.update(trabajadorRef, {
          'puntos': FieldValue.increment(puntos),
        });

        // (2) Registrar en 'historial_puntos'
        DocumentReference historialRef =
        FirebaseFirestore.instance.collection('historial_puntos').doc();

        batch.set(historialRef, {
          'trabajadorId': workerId,
          'nombreTrabajador': nombreTrabajador,
          'incentivoId': incentivoId,
          'nombreIncentivo': nombreIncentivo,
          'descripcion': descIncentivo,
          'cantidad': puntos,
          'fecha': DateTime.now(),
          'tipo': 'agregado', // Importante para diferenciar en el historial
        });
      }

      await batch.commit();

      // Limpiamos la selección de trabajadores
      setState(() {
        _selectedWorkerIds.clear();
      });

      Navigator.of(context).pop();

      Fluttertoast.showToast(
        msg: "Puntos asignados exitosamente.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al asignar puntos: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    }
  }
}

/// Widget para la Tarjeta de Trabajador
class WorkerCard extends StatelessWidget {
  final QueryDocumentSnapshot trabajador;
  final bool isSelected;
  final Function(bool) onSelected;

  const WorkerCard({
    Key? key,
    required this.trabajador,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () {
          onSelected(!isSelected);
        },
        leading: Checkbox(
          value: isSelected,
          activeColor: const Color(0xFFD1D92C),
          onChanged: (bool? value) {
            if (value != null) {
              onSelected(value);
            }
          },
        ),
        title: Text(
          trabajador['nombre'] ?? 'Sin Nombre',
          style: GoogleFonts.sen(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '@${trabajador['correo'] ?? 'Sin Correo'}',
          style: GoogleFonts.sen(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        trailing: const Icon(Icons.person_outline, color: Colors.grey),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DIÁLOGO: CREAR TRABAJADOR
/// ---------------------------------------------------------------------------
class CrearTrabajadorDialog extends StatefulWidget {
  @override
  _CrearTrabajadorDialogState createState() => _CrearTrabajadorDialogState();
}

class _CrearTrabajadorDialogState extends State<CrearTrabajadorDialog> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final telefonoController = TextEditingController();
  final contrasenaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _guardarTrabajador() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Crear el usuario en Firebase Authentication
        final UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: correoController.text.trim(),
          password: contrasenaController.text.trim(),
        );

        final String userId = userCredential.user!.uid;

        // Agregar trabajador a la colección 'trabajadores'
        await FirebaseFirestore.instance.collection('trabajadores').doc(userId).set({
          'nombre': nombreController.text.trim(),
          'correo': correoController.text.trim(),
          'telefono': telefonoController.text.trim(),
          'puntos': 0,
        });

        // Agregar al trabajador a la colección 'users' con role 'user'
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'email': correoController.text.trim(),
          'role': 'user',
        });

        Navigator.of(context).pop();
        Fluttertoast.showToast(
          msg: "Trabajador creado exitosamente.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
        );
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(
          msg: "Error en Firebase Authentication: ${e.message}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error al crear trabajador: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        "Crear Trabajador",
        style: GoogleFonts.sen(fontWeight: FontWeight.bold),
      ),
      content: _isLoading
          ? const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customTextField(
                nombreController,
                "Nombre Completo",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo es obligatorio.";
                  }
                  return null;
                },
              ),
              _customTextField(
                correoController,
                "Correo Electrónico",
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo es obligatorio.";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Correo inválido.";
                  }
                  return null;
                },
              ),
              _customTextField(
                telefonoController,
                "Teléfono",
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo es obligatorio.";
                  }
                  return null;
                },
              ),
              _customTextField(
                contrasenaController,
                "Contraseña",
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo es obligatorio.";
                  }
                  if (value.length < 6) {
                    return "La contraseña debe tener al menos 6 caracteres.";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: _isLoading
          ? []
          : [
        _dialogButton(
          label: "Cancelar",
          backgroundColor: Colors.grey.shade600,
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        _dialogButton(
          label: "Guardar",
          backgroundColor: const Color(0xFFD1D92C),
          textColor: Colors.black,
          onPressed: _guardarTrabajador,
        ),
      ],
    );
  }

  // TextField con estilo unificado
  Widget _customTextField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.sen(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: validator,
      ),
    );
  }

  // Botón con diseño “Cancelar/Guardar”
  Widget _dialogButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DIÁLOGO: EDITAR TRABAJADOR
/// ---------------------------------------------------------------------------
class EditarTrabajadorDialog extends StatefulWidget {
  final String trabajadorId;

  const EditarTrabajadorDialog({Key? key, required this.trabajadorId})
      : super(key: key);

  @override
  _EditarTrabajadorDialogState createState() =>
      _EditarTrabajadorDialogState();
}

class _EditarTrabajadorDialogState extends State<EditarTrabajadorDialog> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final telefonoController = TextEditingController();
  final contrasenaController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      DocumentSnapshot trabajadorSnapshot = await FirebaseFirestore.instance
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .get();

      if (trabajadorSnapshot.exists) {
        setState(() {
          nombreController.text = trabajadorSnapshot['nombre'] ?? '';
          correoController.text = trabajadorSnapshot['correo'] ?? '';
          telefonoController.text = trabajadorSnapshot['telefono'] ?? '';
          contrasenaController.text =
              trabajadorSnapshot['contrasena'] ?? '';
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop();
        Fluttertoast.showToast(
          msg: "Trabajador no encontrado.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: "Error al cargar datos: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _guardarEdicion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Actualizar datos en la colección 'trabajadores'
        await FirebaseFirestore.instance
            .collection('trabajadores')
            .doc(widget.trabajadorId)
            .update({
          'nombre': nombreController.text.trim(),
          'correo': correoController.text.trim(),
          'telefono': telefonoController.text.trim(),
          'contrasena': contrasenaController.text.trim(),
        });

        // Actualizar datos en la colección 'users'
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.trabajadorId)
            .update({
          'email': correoController.text.trim(),
        });

        Navigator.of(context).pop();
        Fluttertoast.showToast(
          msg: "Trabajador actualizado exitosamente.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error al actualizar: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        "Editar Trabajador",
        style: GoogleFonts.sen(fontWeight: FontWeight.bold),
      ),
      content: _isLoading
          ? const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _customTextField(
                nombreController,
                "Nombre Completo",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo es obligatorio.";
                  }
                  return null;
                },
              ),
              _customTextField(
                correoController,
                "Correo Electrónico",
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo es obligatorio.";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Correo inválido.";
                  }
                  return null;
                },
              ),
              _customTextField(
                telefonoController,
                "Teléfono",
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo es obligatorio.";
                  }
                  return null;
                },
              ),
              _customTextField(
                contrasenaController,
                "Contraseña",
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo es obligatorio.";
                  }
                  if (value.length < 6) {
                    return "La contraseña debe tener al menos 6 caracteres.";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: _isLoading
          ? []
          : [
        _dialogButton(
          label: "Cancelar",
          backgroundColor: Colors.grey.shade600,
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        _dialogButton(
          label: "Guardar",
          backgroundColor: const Color(0xFFD1D92C),
          textColor: Colors.black,
          onPressed: _guardarEdicion,
        ),
      ],
    );
  }

  // TextField con estilo unificado
  Widget _customTextField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.sen(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: validator,
      ),
    );
  }

  // Botón con diseño “Cancelar/Guardar”
  Widget _dialogButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DIÁLOGO: INCENTIVOS
/// ---------------------------------------------------------------------------
class IncentivosDialog extends StatefulWidget {
  @override
  _IncentivosDialogState createState() => _IncentivosDialogState();
}

class _IncentivosDialogState extends State<IncentivosDialog> {
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final cantidadController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    cantidadController.dispose();
    super.dispose();
  }

  Future<void> _agregarIncentivo() async {
    if (nombreController.text.isEmpty ||
        descripcionController.text.isEmpty ||
        cantidadController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Todos los campos son obligatorios.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
      return;
    }

    int? cantidad = int.tryParse(cantidadController.text.trim());
    if (cantidad == null) {
      Fluttertoast.showToast(
        msg: "Ingrese un número válido para la cantidad.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('incentivos').add({
        'nombre': nombreController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'cantidad': cantidad,
      });
      // Limpiamos los campos
      nombreController.clear();
      descripcionController.clear();
      cantidadController.clear();
      Fluttertoast.showToast(
        msg: "Incentivo agregado exitosamente.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al agregar incentivo: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editarIncentivo(
      QueryDocumentSnapshot incentivo,
      String nombre,
      String descripcion,
      int cantidad,
      ) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await incentivo.reference.update({
        'nombre': nombre,
        'descripcion': descripcion,
        'cantidad': cantidad,
      });
      Fluttertoast.showToast(
        msg: "Incentivo actualizado exitosamente.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al actualizar incentivo: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        "Incentivos",
        style: GoogleFonts.sen(fontWeight: FontWeight.bold),
      ),
      content: _isLoading
          ? const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      )
          : SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('incentivos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay incentivos registrados."),
                    );
                  }
                  final incentivos = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: incentivos.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final incentivo = incentivos[index];
                      final data =
                      incentivo.data() as Map<String, dynamic>?;

                      final nombre = data?['nombre'] ?? 'Sin Nombre';
                      final descripcion =
                          data?['descripcion'] ?? 'Sin Descripción';
                      final cantidad =
                          data?['cantidad']?.toString() ?? '0';

                      return ListTile(
                        key: ValueKey(incentivo.id),
                        leading:
                        const Icon(Icons.star, color: Colors.amber),
                        title: Text(nombre),
                        subtitle: Text(
                          "Descripción: $descripcion\nPuntos: $cantidad",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue),
                              tooltip: "Editar Incentivo",
                              onPressed: () {
                                _showEditarIncentivoDialog(
                                    context, incentivo);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              tooltip: "Eliminar Incentivo",
                              onPressed: () async {
                                bool confirm =
                                await _showConfirmDeleteDialog(
                                    nombre);
                                if (!confirm) return;

                                try {
                                  await incentivo.reference.delete();
                                  Fluttertoast.showToast(
                                    msg:
                                    "Incentivo eliminado exitosamente.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    backgroundColor:
                                    Colors.green.shade600,
                                    textColor: Colors.white,
                                  );
                                } catch (e) {
                                  Fluttertoast.showToast(
                                    msg:
                                    "Error al eliminar incentivo: $e",
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.BOTTOM,
                                    backgroundColor: Colors.red.shade600,
                                    textColor: Colors.white,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            // Campos para agregar un NUEVO incentivo
            _customTextField(
              nombreController,
              "Nombre del incentivo",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Este campo es obligatorio.";
                }
                return null;
              },
            ),
            _customTextField(
              descripcionController,
              "Descripción",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Este campo es obligatorio.";
                }
                return null;
              },
            ),
            _customTextField(
              cantidadController,
              "Cantidad",
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Este campo es obligatorio.";
                }
                if (int.tryParse(value) == null) {
                  return "Ingrese un número válido.";
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: _isLoading
          ? []
          : [
        _dialogButton(
          label: "Cerrar",
          backgroundColor: Colors.grey.shade600,
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        _dialogButton(
          label: "Agregar",
          backgroundColor: const Color(0xFFD1D92C),
          textColor: Colors.black,
          onPressed: _agregarIncentivo,
        ),
      ],
    );
  }

  Future<bool> _showConfirmDeleteDialog(String incentivoNombre) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text(
          "¿Estás seguro de eliminar el incentivo '$incentivoNombre'? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancelar",
              style: GoogleFonts.sen(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Eliminar",
              style: GoogleFonts.sen(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _customTextField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.sen(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _dialogButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _showEditarIncentivoDialog(
      BuildContext context,
      QueryDocumentSnapshot incentivo,
      ) {
    final data = incentivo.data() as Map<String, dynamic>?;
    final nombre = data?['nombre'] ?? '';
    final descripcion = data?['descripcion'] ?? '';
    final cantidad = data?['cantidad']?.toString() ?? '0';

    final nombreCtrl = TextEditingController(text: nombre);
    final descCtrl = TextEditingController(text: descripcion);
    final cantCtrl = TextEditingController(text: cantidad);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Editar Incentivo",
          style: GoogleFonts.sen(fontWeight: FontWeight.bold),
        ),
        content: _isLoading
            ? const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _customTextField(
              nombreCtrl,
              "Nombre del incentivo",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Este campo es obligatorio.";
                }
                return null;
              },
            ),
            _customTextField(
              descCtrl,
              "Descripción",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Este campo es obligatorio.";
                }
                return null;
              },
            ),
            _customTextField(
              cantCtrl,
              "Cantidad",
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Este campo es obligatorio.";
                }
                if (int.tryParse(value) == null) {
                  return "Ingrese un número válido.";
                }
                return null;
              },
            ),
          ],
        ),
        actions: _isLoading
            ? []
            : [
          _dialogButton(
            label: "Cancelar",
            backgroundColor: Colors.grey.shade600,
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
          _dialogButton(
            label: "Guardar",
            backgroundColor: const Color(0xFFD1D92C),
            textColor: Colors.black,
            onPressed: () async {
              if (nombreCtrl.text.isEmpty ||
                  descCtrl.text.isEmpty ||
                  cantCtrl.text.isEmpty) {
                Fluttertoast.showToast(
                  msg: "Todos los campos son obligatorios.",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red.shade600,
                  textColor: Colors.white,
                );
                return;
              }

              int? c = int.tryParse(cantCtrl.text.trim());
              if (c == null) {
                Fluttertoast.showToast(
                  msg: "Ingrese un número válido para la cantidad.",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red.shade600,
                  textColor: Colors.white,
                );
                return;
              }

              setState(() {
                _isLoading = true;
              });

              try {
                await incentivo.reference.update({
                  'nombre': nombreCtrl.text.trim(),
                  'descripcion': descCtrl.text.trim(),
                  'cantidad': c,
                });

                Navigator.of(context).pop();
                Fluttertoast.showToast(
                  msg: "Incentivo actualizado exitosamente.",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green.shade600,
                  textColor: Colors.white,
                );
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Error al actualizar incentivo: $e",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red.shade600,
                  textColor: Colors.white,
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DIÁLOGO: ASIGNAR PUNTOS
/// ---------------------------------------------------------------------------
class AsignarPuntosDialog extends StatefulWidget {
  final Set<String> selectedWorkerIds;

  /// Función que recibe (String incentivoId, String descripcion, int puntos)
  final Future<void> Function(String, String, int) onAsignar;

  const AsignarPuntosDialog({
    Key? key,
    required this.selectedWorkerIds,
    required this.onAsignar,
  }) : super(key: key);

  @override
  State<AsignarPuntosDialog> createState() => _AsignarPuntosDialogState();
}

class _AsignarPuntosDialogState extends State<AsignarPuntosDialog> {
  String? _selectedIncentiveId;
  String _incentiveDescription = "";
  int _incentivePoints = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        "Asignar puntos",
        style: GoogleFonts.sen(fontWeight: FontWeight.bold),
      ),
      content: _isLoading
          ? const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dropdown para seleccionar un incentivo
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('incentivos')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No hay incentivos disponibles.");
              }

              final incentivos = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Seleccione un incentivo",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                value: _selectedIncentiveId,
                items: incentivos.map((incentivo) {
                  final Map<String, dynamic> data =
                  incentivo.data() as Map<String, dynamic>;
                  final String nombre = data['nombre'] ?? 'Incentivo';
                  return DropdownMenuItem<String>(
                    value: incentivo.id,
                    child: Text(nombre),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final selectedIncentivo =
                  incentivos.firstWhere((doc) => doc.id == value);
                  final Map<String, dynamic> sData =
                  selectedIncentivo.data() as Map<String, dynamic>;

                  setState(() {
                    _selectedIncentiveId = value;
                    _incentiveDescription =
                        sData['descripcion'] ?? "Sin Descripción";
                    _incentivePoints =
                    (sData['cantidad'] ?? 0) is int ? sData['cantidad'] : 0;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 10),

          // Descripción del incentivo (solo lectura)
          TextField(
            readOnly: true,
            decoration: const InputDecoration(labelText: "Descripción"),
            controller:
            TextEditingController(text: _incentiveDescription),
          ),
          const SizedBox(height: 10),

          // Cantidad de puntos (solo lectura)
          TextField(
            readOnly: true,
            decoration:
            const InputDecoration(labelText: "Cantidad de puntos"),
            controller:
            TextEditingController(text: _incentivePoints.toString()),
          ),
        ],
      ),
      actions: _isLoading
          ? []
          : [
        _dialogButton(
          label: "Cancelar",
          backgroundColor: Colors.grey.shade600,
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        _dialogButton(
          label: "Asignar",
          backgroundColor: const Color(0xFFD1D92C),
          textColor: Colors.black,
          onPressed: () async {
            // Validar
            if (_selectedIncentiveId == null) {
              Fluttertoast.showToast(
                msg: "Seleccione un incentivo primero.",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red.shade600,
                textColor: Colors.white,
              );
              return;
            }

            setState(() {
              _isLoading = true;
            });

            // Llamar al callback para asignar puntos
            await widget.onAsignar(
              _selectedIncentiveId!,
              _incentiveDescription,
              _incentivePoints,
            );

            setState(() {
              _isLoading = false;
            });
          },
        ),
      ],
    );
  }

  // Botón con diseño “Cancelar/Asignar”
  Widget _dialogButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
