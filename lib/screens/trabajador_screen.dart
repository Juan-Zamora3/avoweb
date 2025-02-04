import 'package:avocatooapp/screens/sss.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Pantalla Principal para Gestionar Trabajadores, Incentivos y Equipos
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
                  _buildSpeedDial(), // FAB principal
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

  // Widget para construir el Speed Dial
  Widget _buildSpeedDial() {
    return SpeedDial(
      // ADVERTENCIA: Más de 5 SpeedDialChild produce un warning en Material
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
          child: const Icon(Icons.people, color: Colors.white),
          backgroundColor: const Color(0xFF8BC34A),
          label: 'Equipos',
          labelStyle: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onTap: () => _showEquiposDialog(context),
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

  // Diálogo para manejar equipos
  void _showEquiposDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EquiposDialog(),
    );
  }

  // Diálogo para asignar puntos a trabajadores seleccionados
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

  // Función para asignar puntos (Suma de puntos, "tipo": "agregado"),
  // con validación de tope mensual
  Future<void> _asignarPuntos(
      String incentivoId,
      String descripcion,
      int puntos,
      ) async {
    try {
      // 1) Verificar tope mensual para este incentivo
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      DocumentSnapshot incentivoSnapshot = await FirebaseFirestore.instance
          .collection('incentivos')
          .doc(incentivoId)
          .get();

      if (!incentivoSnapshot.exists) {
        throw Exception("El incentivo seleccionado no existe.");
      }

      final data = incentivoSnapshot.data() as Map<String, dynamic>;
      final String nombreIncentivo = data['nombre'] ?? 'Sin Nombre';
      final String descIncentivo = data['descripcion'] ?? 'Sin Descripción';
      final int topeMensual = data['topeMensual'] ?? 0;

      // IMPORTANTE: Esta query con varios where requiere un índice en Firestore.
      QuerySnapshot historialQuery = await FirebaseFirestore.instance
          .collection('historial_puntos')
          .where('incentivoId', isEqualTo: incentivoId)
          .where('fecha', isGreaterThanOrEqualTo: startOfMonth)
          .where('fecha', isLessThanOrEqualTo: endOfMonth)
          .get();

      int totalAsignadoEsteMes = 0;
      for (var doc in historialQuery.docs) {
        final hData = doc.data() as Map<String, dynamic>;
        totalAsignadoEsteMes += (hData['cantidad'] ?? 0) as int;
      }

      // Puntos totales que se van a asignar = puntos * número de trabajadores
      int puntosTotalesPorAsignar = puntos * _selectedWorkerIds.length;
      if (topeMensual > 0 &&
          (totalAsignadoEsteMes + puntosTotalesPorAsignar) > topeMensual) {
        Fluttertoast.showToast(
          msg:
          "Se excede el tope mensual para este incentivo. No se asignaron puntos.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
        return;
      }

      // 2) Asignar los puntos si no excede el tope
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var workerId in _selectedWorkerIds) {
        DocumentSnapshot trabajadorSnapshot = await FirebaseFirestore.instance
            .collection('trabajadores')
            .doc(workerId)
            .get();

        String nombreTrabajador =
            trabajadorSnapshot['nombre'] ?? 'Sin Nombre';

        // (A) Actualizar puntos en 'trabajadores'
        DocumentReference trabajadorRef =
        FirebaseFirestore.instance.collection('trabajadores').doc(workerId);
        batch.update(trabajadorRef, {
          'puntos': FieldValue.increment(puntos),
        });

        // (B) Registrar en 'historial_puntos'
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
          'tipo': 'agregado',
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

/// ---------------------------------------------------------------------------
/// Widget para la Tarjeta de Trabajador
/// ---------------------------------------------------------------------------
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
    // Para evitar errores cuando no exista 'area', usamos un default
    final data = trabajador.data() as Map<String, dynamic>;
    final area = data['area'] ?? 'Desconocida';
    final nombre = data['nombre'] ?? 'Sin Nombre';
    final correo = data['correo'] ?? 'Sin Correo';

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
          nombre,
          style: GoogleFonts.sen(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '@$correo\nÁrea: $area',
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
/// DIÁLOGO: CREAR TRABAJADOR
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
  String _selectedArea = 'Servicio'; // Valor por defecto
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
        final email = correoController.text.trim();
        final password = contrasenaController.text.trim();

        // 1) Verificar si ya existe un trabajador con el mismo correo
        final query = await FirebaseFirestore.instance
            .collection('trabajadores')
            .where('correo', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          // Ya existe un trabajador con el mismo correo
          Fluttertoast.showToast(
            msg: "El correo '$email' ya está registrado.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.shade600,
            textColor: Colors.white,
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // 2) Crear el trabajador en Firestore sin hashear la contraseña
        await FirebaseFirestore.instance.collection('trabajadores').add({
          'nombre': nombreController.text.trim(),
          'correo': email,
          'telefono': telefonoController.text.trim(),
          'contrasena': password, // Almacenamiento en texto plano
          'puntos': 0,
          'area': _selectedArea, // nuevo campo
          'role': 'user', // Establecer rol como 'user'
        });

        Navigator.of(context).pop();
        Fluttertoast.showToast(
          msg: "Trabajador creado exitosamente.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green.shade600,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              const SizedBox(height: 10),
              // Dropdown para área
              DropdownButtonFormField<String>(
                value: _selectedArea,
                decoration: InputDecoration(
                  labelText: "Área",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Servicio',
                    child: Text('Servicio'),
                  ),
                  DropdownMenuItem(
                    value: 'Cocina',
                    child: Text('Cocina'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedArea = value ?? 'Servicio';
                  });
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
/// DIÁLOGO: EDITAR TRABAJADOR
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
  String _selectedArea = 'Servicio';
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
        final data = trabajadorSnapshot.data() as Map<String, dynamic>;
        setState(() {
          nombreController.text = data['nombre'] ?? '';
          correoController.text = data['correo'] ?? '';
          telefonoController.text = data['telefono'] ?? '';
          contrasenaController.text = ''; // No mostrar contraseña existente
          _selectedArea = data['area'] ?? 'Servicio';
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
        final updatedEmail = correoController.text.trim();
        final updatedPassword = contrasenaController.text.trim();

        // Verificar si ya existe otro trabajador con el mismo correo,
        // excluyendo el doc actual (trabajadorId).
        final query = await FirebaseFirestore.instance
            .collection('trabajadores')
            .where('correo', isEqualTo: updatedEmail)
            .limit(1)
            .get();

        bool yaExisteOtro = false;

        for (var doc in query.docs) {
          if (doc.id != widget.trabajadorId) {
            // Existe otro doc con el mismo correo que no es el actual
            yaExisteOtro = true;
            break;
          }
        }

        if (yaExisteOtro) {
          Fluttertoast.showToast(
            msg: "El correo '$updatedEmail' ya está registrado por otro trabajador.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.shade600,
            textColor: Colors.white,
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Preparar datos para actualizar
        Map<String, dynamic> updateData = {
          'nombre': nombreController.text.trim(),
          'correo': updatedEmail,
          'telefono': telefonoController.text.trim(),
          'area': _selectedArea,
          'role': 'user', // Asegurarse de que el rol sea 'user'
        };

        if (updatedPassword.isNotEmpty) {
          updateData['contrasena'] = updatedPassword; // Almacenamiento en texto plano
        }

        // Actualizar datos en la colección 'trabajadores'
        await FirebaseFirestore.instance
            .collection('trabajadores')
            .doc(widget.trabajadorId)
            .update(updateData);

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                "Nueva Contraseña",
                obscureText: true,
                validator: (value) {
                  // Contraseña opcional al editar
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return "La contraseña debe tener al menos 6 caracteres.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // Dropdown para área
              DropdownButtonFormField<String>(
                value: _selectedArea,
                decoration: InputDecoration(
                  labelText: "Área",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Servicio',
                    child: Text('Servicio'),
                  ),
                  DropdownMenuItem(
                    value: 'Cocina',
                    child: Text('Cocina'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedArea = value ?? 'Servicio';
                  });
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
  final topeMensualController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    cantidadController.dispose();
    topeMensualController.dispose();
    super.dispose();
  }

  Future<void> _agregarIncentivo() async {
    if (nombreController.text.isEmpty ||
        descripcionController.text.isEmpty ||
        cantidadController.text.isEmpty ||
        topeMensualController.text.isEmpty) {
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
    int? topeMensual = int.tryParse(topeMensualController.text.trim());
    if (cantidad == null || topeMensual == null) {
      Fluttertoast.showToast(
        msg: "Ingrese valores numéricos válidos.",
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
        'topeMensual': topeMensual,
      });
      // Limpiamos los campos
      nombreController.clear();
      descripcionController.clear();
      cantidadController.clear();
      topeMensualController.clear();
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
      int topeMensual,
      ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await incentivo.reference.update({
        'nombre': nombre,
        'descripcion': descripcion,
        'cantidad': cantidad,
        'topeMensual': topeMensual,
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
        height: 450,
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
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                      incentivo.data() as Map<String, dynamic>;

                      final nombre = data['nombre'] ?? 'Sin Nombre';
                      final descripcion =
                          data['descripcion'] ?? 'Sin Descripción';
                      final cantidad =
                          data['cantidad']?.toString() ?? '0';
                      final topeMensual =
                          data['topeMensual']?.toString() ?? '0';

                      return ListTile(
                        key: ValueKey(incentivo.id),
                        leading:
                        const Icon(Icons.star, color: Colors.amber),
                        title: Text(nombre),
                        subtitle: Text(
                          "Descripción: $descripcion\n"
                              "Puntos base: $cantidad\n"
                              "Tope mensual: $topeMensual",
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
                                await _showConfirmDeleteDialog(nombre);
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
                                    backgroundColor:
                                    Colors.red.shade600,
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
            ),
            _customTextField(
              descripcionController,
              "Descripción",
            ),
            _customTextField(
              cantidadController,
              "Cantidad de Puntos",
              keyboardType: TextInputType.number,
            ),
            _customTextField(
              topeMensualController,
              "Tope Mensual",
              keyboardType: TextInputType.number,
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
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
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
    final data = incentivo.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? '';
    final descripcion = data['descripcion'] ?? '';
    final cantidad = data['cantidad']?.toString() ?? '0';
    final topeMensual = data['topeMensual']?.toString() ?? '0';

    final nombreCtrl = TextEditingController(text: nombre);
    final descCtrl = TextEditingController(text: descripcion);
    final cantCtrl = TextEditingController(text: cantidad);
    final topeCtrl = TextEditingController(text: topeMensual);

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
            _customTextFieldEditar(
              nombreCtrl,
              "Nombre del incentivo",
            ),
            _customTextFieldEditar(
              descCtrl,
              "Descripción",
            ),
            _customTextFieldEditar(
              cantCtrl,
              "Cantidad de Puntos",
              keyboardType: TextInputType.number,
            ),
            _customTextFieldEditar(
              topeCtrl,
              "Tope Mensual",
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
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
                  cantCtrl.text.isEmpty ||
                  topeCtrl.text.isEmpty) {
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
              int? t = int.tryParse(topeCtrl.text.trim());
              if (c == null || t == null) {
                Fluttertoast.showToast(
                  msg: "Ingrese valores numéricos válidos.",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red.shade600,
                  textColor: Colors.white,
                );
                return;
              }

              Navigator.of(context).pop();
              await _editarIncentivo(
                incentivo,
                nombreCtrl.text.trim(),
                descCtrl.text.trim(),
                c,
                t,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _customTextFieldEditar(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
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
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DIÁLOGO: EQUIPOS (Crear, Editar, Eliminar)
/// ---------------------------------------------------------------------------
class EquiposDialog extends StatefulWidget {
  const EquiposDialog({Key? key}) : super(key: key);

  @override
  State<EquiposDialog> createState() => _EquiposDialogState();
}

class _EquiposDialogState extends State<EquiposDialog> {
  final nombreEquipoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nombreEquipoController.dispose();
    super.dispose();
  }

  Future<void> _crearEquipo() async {
    if (nombreEquipoController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "El nombre del equipo es obligatorio.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crea el equipo con un array vacío de miembros inicialmente
      await FirebaseFirestore.instance.collection('equipos').add({
        'nombre': nombreEquipoController.text.trim(),
        'miembros': [],
      });

      nombreEquipoController.clear();

      Fluttertoast.showToast(
        msg: "Equipo creado exitosamente.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al crear equipo: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editarEquipo(
      DocumentSnapshot equipoDoc, String nuevoNombre, List<String> nuevosMiembros) async {
    setState(() => _isLoading = true);

    try {
      await equipoDoc.reference.update({
        'nombre': nuevoNombre,
        'miembros': nuevosMiembros,
      });

      Fluttertoast.showToast(
        msg: "Equipo actualizado exitosamente.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al actualizar equipo: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarEquipo(DocumentSnapshot equipoDoc) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text(
          "¿Estás seguro de eliminar el equipo '${equipoDoc['nombre']}'? Esta acción no se puede deshacer.",
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

    if (!confirm) return;

    try {
      await equipoDoc.reference.delete();
      Fluttertoast.showToast(
        msg: "Equipo eliminado exitosamente.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al eliminar equipo: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    }
  }

  /// Mostramos un diálogo con "StatefulBuilder" para evitar problemas de foco
  /// y refrescar la lista cuando marquemos el checkbox.
  void _showEditarEquipoDialog(DocumentSnapshot equipoDoc) {
    final nombreEquipo = equipoDoc['nombre'] ?? '';
    final List<dynamic> miembros = equipoDoc['miembros'] ?? [];

    final nombreCtrl = TextEditingController(text: nombreEquipo);
    // IDs seleccionados
    final Set<String> miembrosSeleccionados = miembros.cast<String>().toSet();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Esto permite usar setState() dentro del diálogo
          builder: (BuildContext context, void Function(void Function()) setStateDialog) {
            return AlertDialog(
              title: Text("Editar Equipo", style: GoogleFonts.sen()),
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
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 10),
                    // Lista de trabajadores con check
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('trabajadores')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text("No hay trabajadores registrados."),
                            );
                          }

                          final trabajadores = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: trabajadores.length,
                            itemBuilder: (context, index) {
                              final trabajador = trabajadores[index];
                              final tid = trabajador.id;
                              final tData = trabajador.data() as Map<String, dynamic>;
                              final nombreTrab = tData['nombre'] ?? 'Sin Nombre';
                              final bool isSelected = miembrosSeleccionados.contains(tid);

                              return CheckboxListTile(
                                title: Text(nombreTrab),
                                value: isSelected,
                                onChanged: (selected) {
                                  setStateDialog(() {
                                    if (selected == true) {
                                      miembrosSeleccionados.add(tid);
                                    } else {
                                      miembrosSeleccionados.remove(tid);
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Cancelar",
                      style: GoogleFonts.sen(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final nuevoNombre = nombreCtrl.text.trim();
                    if (nuevoNombre.isEmpty) {
                      Fluttertoast.showToast(
                        msg: "El nombre del equipo es obligatorio.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red.shade600,
                        textColor: Colors.white,
                      );
                      return;
                    }

                    final nuevosMiembros = miembrosSeleccionados.toList();
                    Navigator.of(context).pop();
                    await _editarEquipo(
                      equipoDoc,
                      nuevoNombre,
                      nuevosMiembros.cast<String>(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D92C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Guardar",
                      style: GoogleFonts.sen(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAsignarPuntosEquipoDialog(
      BuildContext context, DocumentSnapshot equipoDoc) {
    showDialog(
      context: context,
      builder: (_) => AsignarPuntosEquipoDialog(equipoDoc: equipoDoc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Gestión de Equipos", style: GoogleFonts.sen()),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                FirebaseFirestore.instance.collection('equipos').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay equipos registrados."),
                    );
                  }

                  final equipos = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: equipos.length,
                    itemBuilder: (context, index) {
                      final equipoDoc = equipos[index];
                      final data = equipoDoc.data() as Map<String, dynamic>;
                      final nombre = data['nombre'] ?? 'Sin Nombre';
                      final List miembros = data['miembros'] ?? [];

                      return ListTile(
                        title: Text(nombre),
                        subtitle: Text(
                          "Miembros: ${miembros.length} trabajador(es)",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                              const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditarEquipoDialog(equipoDoc),
                            ),
                            IconButton(
                              icon:
                              const Icon(Icons.star, color: Colors.amber),
                              tooltip: "Asignar puntos al equipo",
                              onPressed: () =>
                                  _showAsignarPuntosEquipoDialog(context, equipoDoc),
                            ),
                            IconButton(
                              icon:
                              const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarEquipo(equipoDoc),
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
            TextField(
              controller: nombreEquipoController,
              decoration: const InputDecoration(
                labelText: 'Nombre del equipo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Cerrar",
              style: GoogleFonts.sen(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: _crearEquipo,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD1D92C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Crear",
              style: GoogleFonts.sen(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// DIÁLOGO: ASIGNAR PUNTOS A UN EQUIPO (dividido entre sus miembros)
/// ---------------------------------------------------------------------------
class AsignarPuntosEquipoDialog extends StatefulWidget {
  final DocumentSnapshot equipoDoc;

  const AsignarPuntosEquipoDialog({Key? key, required this.equipoDoc}) : super(key: key);

  @override
  State<AsignarPuntosEquipoDialog> createState() => _AsignarPuntosEquipoDialogState();
}

class _AsignarPuntosEquipoDialogState extends State<AsignarPuntosEquipoDialog> {
  String? _selectedIncentiveId;
  String _incentiveDescription = "";
  int _incentivePoints = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final equipoData = widget.equipoDoc.data() as Map<String, dynamic>;
    final List<dynamic> miembros = equipoData['miembros'] ?? [];
    final String nombreEquipo = equipoData['nombre'] ?? 'Sin Nombre';

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        "Asignar puntos a Equipo: $nombreEquipo",
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
            controller: TextEditingController(text: _incentiveDescription),
          ),
          const SizedBox(height: 10),

          // Cantidad de puntos (solo lectura)
          TextField(
            readOnly: true,
            decoration: const InputDecoration(labelText: "Cantidad de puntos"),
            controller: TextEditingController(text: _incentivePoints.toString()),
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
            if (miembros.isEmpty) {
              Fluttertoast.showToast(
                msg: "El equipo no tiene miembros.",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red.shade600,
                textColor: Colors.white,
              );
              return;
            }

            setState(() => _isLoading = true);

            await _asignarPuntosAlEquipo(miembros);

            setState(() => _isLoading = false);
          },
        ),
      ],
    );
  }

  // Asignar puntos divididos a cada miembro del equipo,
  // validando el tope mensual del incentivo
  Future<void> _asignarPuntosAlEquipo(List<dynamic> miembros) async {
    try {
      // 1) Verificar tope mensual para este incentivo
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      DocumentSnapshot incentivoSnapshot = await FirebaseFirestore.instance
          .collection('incentivos')
          .doc(_selectedIncentiveId)
          .get();

      if (!incentivoSnapshot.exists) {
        throw Exception("El incentivo seleccionado no existe.");
      }

      final data = incentivoSnapshot.data() as Map<String, dynamic>;
      final String nombreIncentivo = data['nombre'] ?? 'Sin Nombre';
      final String descIncentivo = data['descripcion'] ?? 'Sin Descripción';
      final int topeMensual = data['topeMensual'] ?? 0;

      // IMPORTANTE: requiere un índice si usas varios where.
      QuerySnapshot historialQuery = await FirebaseFirestore.instance
          .collection('historial_puntos')
          .where('incentivoId', isEqualTo: _selectedIncentiveId)
          .where('fecha', isGreaterThanOrEqualTo: startOfMonth)
          .where('fecha', isLessThanOrEqualTo: endOfMonth)
          .get();

      int totalAsignadoEsteMes = 0;
      for (var doc in historialQuery.docs) {
        final hData = doc.data() as Map<String, dynamic>;
        totalAsignadoEsteMes += (hData['cantidad'] ?? 0) as int;
      }

      final int puntosBase = _incentivePoints;
      final int numMiembros = miembros.length;

      // Dividir los puntos en partes iguales, sin decimales
      final int puntosPorMiembro = (puntosBase / numMiembros).floor();
      if (puntosPorMiembro <= 0) {
        // Si es 0, no vale la pena asignar
        Fluttertoast.showToast(
          msg: "Los puntos son insuficientes para dividir entre los miembros.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
        Navigator.of(context).pop();
        return;
      }

      // Puntos totales que se van a asignar
      final int puntosTotalesPorAsignar = puntosPorMiembro * numMiembros;

      if (topeMensual > 0 &&
          (totalAsignadoEsteMes + puntosTotalesPorAsignar) > topeMensual) {
        Fluttertoast.showToast(
          msg:
          "Se excede el tope mensual para este incentivo. No se asignaron puntos.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
        Navigator.of(context).pop();
        return;
      }

      // 2) Asignar puntos a cada miembro
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var miembroId in miembros) {
        final trabajadorRef = FirebaseFirestore.instance
            .collection('trabajadores')
            .doc(miembroId);

        final trabajadorSnapshot = await trabajadorRef.get();
        if (!trabajadorSnapshot.exists) {
          // Si algún miembro no existe, lo ignoramos
          continue;
        }
        final nombreTrabajador = trabajadorSnapshot['nombre'] ?? 'Sin Nombre';

        // (A) Actualizar puntos en 'trabajadores'
        batch.update(trabajadorRef, {
          'puntos': FieldValue.increment(puntosPorMiembro),
        });

        // (B) Registrar en 'historial_puntos'
        DocumentReference historialRef =
        FirebaseFirestore.instance.collection('historial_puntos').doc();

        batch.set(historialRef, {
          'trabajadorId': miembroId,
          'nombreTrabajador': nombreTrabajador,
          'incentivoId': _selectedIncentiveId,
          'nombreIncentivo': nombreIncentivo,
          'descripcion': descIncentivo,
          'cantidad': puntosPorMiembro,
          'fecha': DateTime.now(),
          'tipo': 'agregado',
        });
      }

      await batch.commit();

      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: "Puntos asignados exitosamente (divididos entre miembros).",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
      );
    } catch (e) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: "Error al asignar puntos al equipo: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    }
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
