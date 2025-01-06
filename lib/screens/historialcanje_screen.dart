import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// Import adicional
import 'package:intl/date_symbol_data_local.dart';

class HistorialCanjeScreen extends StatefulWidget {
  const HistorialCanjeScreen({Key? key}) : super(key: key);

  @override
  State<HistorialCanjeScreen> createState() => _HistorialCanjeScreenState();
}

class _HistorialCanjeScreenState extends State<HistorialCanjeScreen> {
  /// Controla si mostramos “agregado” o “canjeado”.
  String _filtroTipo = 'canjeado';

  /// Mes y año seleccionados
  String _mesSeleccionado = 'Todos';
  String _anioSeleccionado = 'Todos';

  /// Lista de meses y años
  final List<String> _meses = [
    'Todos',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  final List<String> _anios = [
    'Todos',
    '2022',
    '2023',
    '2024',
    '2025',
  ];

  /// Aquí guardaremos **todos** los documentos del historial,
  /// cargados **una sola vez** desde Firestore.
  List<QueryDocumentSnapshot> _allRegistros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 1) Inicializar localización para español
    initializeDateFormatting('es_ES', null).then((_) {
      // 2) Cargar registros (ya con localización lista)
      _loadAllRegistros();
    });
  }

  /// Carga todos los documentos de 'historial_puntos' sin filtros.
  Future<void> _loadAllRegistros() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('historial_puntos')
          .orderBy('fecha', descending: true)
          .get();

      setState(() {
        _allRegistros = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error al cargar historial: $e');
    }
  }

  /// Aplica el filtro en memoria
  List<QueryDocumentSnapshot> _applyFilters() {
    // 1) Filtrar por tipo
    final filtradoPorTipo = _allRegistros.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final tipo = data['tipo'] ?? '';
      return tipo == _filtroTipo;
    }).toList();

    // 2) Filtrar por mes y año
    int? anioInt =
    _anioSeleccionado != 'Todos' ? int.tryParse(_anioSeleccionado) : null;
    int mesIndex = _meses.indexOf(_mesSeleccionado); // 0..12

    return filtradoPorTipo.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final Timestamp? fechaTs = data['fecha'] as Timestamp?;
      if (fechaTs == null) return false;

      final fechaDt = fechaTs.toDate();
      final anioDoc = fechaDt.year;
      final mesDoc = fechaDt.month;

      if (anioInt != null && anioDoc != anioInt) {
        return false;
      }
      if (mesIndex > 0 && mesDoc != mesIndex) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildHistorialPanel(context)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 220,
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
              'Historial de Puntos',
              style: GoogleFonts.sen(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Registros de puntos agregados y canjeados',
              style: GoogleFonts.sen(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Botones: “Agregados” y “Canjeados”
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFiltroButton(
                  titulo: 'Agregados',
                  seleccionado: _filtroTipo == 'agregado',
                  onTap: () {
                    setState(() {
                      _filtroTipo = 'agregado';
                    });
                  },
                ),
                _buildFiltroButton(
                  titulo: 'Canjeados',
                  seleccionado: _filtroTipo == 'canjeado',
                  onTap: () {
                    setState(() {
                      _filtroTipo = 'canjeado';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filtros de mes y año
            Row(
              children: [
                Expanded(
                  child: _buildFiltroDropdown(
                    label: "Mes",
                    value: _mesSeleccionado,
                    items: _meses,
                    onChanged: (nuevoMes) {
                      if (nuevoMes == null) return;
                      setState(() {
                        _mesSeleccionado = nuevoMes;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFiltroDropdown(
                    label: "Año",
                    value: _anioSeleccionado,
                    items: _anios,
                    onChanged: (nuevoAnio) {
                      if (nuevoAnio == null) return;
                      setState(() {
                        _anioSeleccionado = nuevoAnio;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Lista expandida con historial ya filtrado en memoria
            Expanded(
              child: _buildHistorialList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.sen(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.arrow_drop_down),
              underline: const SizedBox(),
              style: GoogleFonts.sen(
                fontSize: 14,
                color: Colors.black87,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroButton({
    required String titulo,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF4CAF50) : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          titulo,
          style: GoogleFonts.sen(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: seleccionado ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildHistorialList() {
    final registrosFiltrados = _applyFilters();

    if (registrosFiltrados.isEmpty) {
      return Center(
        child: Text(
          "No hay registros en este periodo.",
          style: GoogleFonts.sen(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: registrosFiltrados.length,
      itemBuilder: (context, index) {
        final doc = registrosFiltrados[index];
        final data = doc.data() as Map<String, dynamic>? ?? {};

        final String nombreTrabajador =
            data['nombreTrabajador'] ?? 'Sin nombre';
        final String nombreIncentivo =
            data['nombreIncentivo'] ?? 'Desconocido';
        final String descripcion =
            data['descripcion'] ?? 'Sin descripción';
        final int cantidad =
        data['cantidad'] is int ? data['cantidad'] : 0;

        // Fecha (Timestamp)
        final Timestamp? fechaTs = data['fecha'] as Timestamp?;
        final DateTime? fechaDt = fechaTs?.toDate();

        // Si la fecha existe, formateamos con locale español
        final String fechaStr = fechaDt != null
            ? DateFormat('d MMM y, HH:mm', 'es_ES').format(fechaDt)
            : 'Sin fecha';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
          child: ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _filtroTipo == 'agregado'
                    ? Colors.blue[100]
                    : Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _filtroTipo == 'agregado'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: _filtroTipo == 'agregado'
                    ? Colors.blue
                    : Colors.green,
                size: 24,
              ),
            ),
            title: Text(
              _filtroTipo == 'agregado'
                  ? 'Agregados a: $nombreTrabajador'
                  : 'Canjeado a: $nombreTrabajador',
              style: GoogleFonts.sen(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Incentivo: $nombreIncentivo\n$descripcion',
              style: GoogleFonts.sen(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$cantidad pts',
                  style: GoogleFonts.sen(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  fechaStr,
                  style: GoogleFonts.sen(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
