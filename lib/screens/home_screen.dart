import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'trabajador_screen.dart';
import 'historialcanje_screen.dart';
import 'ajustes_admin.dart';
import 'muro_screen.dart';
import 'catalogo_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Índice de la pantalla actual

  // Función para cambiar el índice
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Lista de pantallas para la navegación inferior
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigateToMuro: () {
        _onTabTapped(4); // Navegar a MuroScreen
      }),
      const TrabajadorScreen(),
      const HistorialCanjeScreen(),
      const MuroScreen(),
      const CatalogoScreen(),
      const AjustesAdminScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
        ],
      ),
    );
  }
}

/// Pantalla Principal (Dashboard) con Actualización en Tiempo Real
class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToMuro;

  const DashboardScreen({Key? key, required this.onNavigateToMuro})
      : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Se incluyen en los streams ambos tipos de canje:
  // - "canjeado" para canje de puntos
  // - "canje_producto" para canje de producto
  final Stream<QuerySnapshot<Map<String, dynamic>>> lastRedemptionStream =
  FirebaseFirestore.instance
      .collection('historial_puntos')
      .where('tipo', whereIn: ['canjeado', 'canje_producto'])
      .orderBy('fecha', descending: true)
      .limit(1)
      .snapshots();

  final Stream<QuerySnapshot<Map<String, dynamic>>> redeemedPointsOverTimeStream =
  FirebaseFirestore.instance
      .collection('historial_puntos')
      .where('tipo', whereIn: ['canjeado', 'canje_producto'])
      .orderBy('fecha', descending: false)
      .snapshots();

  final Stream<QuerySnapshot<Map<String, dynamic>>> canjeadosEsteMesStream =
  FirebaseFirestore.instance
      .collection('historial_puntos')
      .where('tipo', whereIn: ['canjeado', 'canje_producto'])
      .where(
    'fecha',
    isGreaterThanOrEqualTo: DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    ),
  )
      .where(
    'fecha',
    isLessThan: DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      1,
    ),
  )
      .snapshots();

  /// Función para extraer la cantidad o precio según el tipo:
  /// - Si el documento es de tipo "canjeado" (puntos), se verifica el campo "precio".
  /// - Si es de tipo "canje_producto" (producto), se verifica el campo "cantidad".
  /// Si alguno no existe (o es 0), se intenta el otro; si ambos existen y son > 0,
  /// se da preferencia según el tipo o se puede sumar (aquí se opta por la preferencia).
  int extractCantidad(Map<String, dynamic> data) {
    String tipo = data['tipo'] ?? '';
    int valorPrecio = 0;
    int valorCantidad = 0;
    if (data.containsKey('precio') && data['precio'] != null) {
      if (data['precio'] is int) {
        valorPrecio = data['precio'];
      } else if (data['precio'] is double) {
        valorPrecio = (data['precio'] as double).toInt();
      }
    }
    if (data.containsKey('cantidad') && data['cantidad'] != null) {
      if (data['cantidad'] is int) {
        valorCantidad = data['cantidad'];
      } else if (data['cantidad'] is double) {
        valorCantidad = (data['cantidad'] as double).toInt();
      }
    }
    // Según el tipo se da preferencia:
    if (tipo == 'canjeado') {
      return valorPrecio > 0 ? valorPrecio.abs() : valorCantidad.abs();
    } else if (tipo == 'canje_producto') {
      return valorCantidad > 0 ? valorCantidad.abs() : valorPrecio.abs();
    }
    // Fallback: si no se reconoce el tipo, se suma (o se elige el mayor)
    return (valorPrecio + valorCantidad).abs();
  }

  // Último canje para mostrar en el diálogo emergente
  Map<String, dynamic>? lastRedemptionData;

  /// Determina el tipo de registro para mostrar en textos (Notificaciones, Listado, etc.)
  String displayTipo(Map<String, dynamic> data) {
    String tipo = data['tipo'] ?? '';
    if (tipo == 'canjeado') {
      return 'Canjeo de Puntos';
    } else if (tipo == 'canje_producto' || data.containsKey('nombreIncentivo')) {
      return 'Canjeo de Producto';
    } else if (tipo == 'agregado') {
      return 'Agregado';
    }
    return 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: lastRedemptionStream,
      builder: (context, lastRedemptionSnapshot) {
        if (!lastRedemptionSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Último canje (para notificación)
        String lastRedemptionMessage = 'Cargando...';
        if (lastRedemptionSnapshot.hasError) {
          lastRedemptionMessage = "Error al cargar la información.";
        } else if (lastRedemptionSnapshot.data!.docs.isNotEmpty) {
          var data = lastRedemptionSnapshot.data!.docs.first.data();
          lastRedemptionData = data; // Guardamos los datos para el diálogo
          String nombre = data['nombreTrabajador'] ?? 'Desconocido';
          int cantidad = extractCantidad(data);
          String tipoRegistro = displayTipo(data);
          Timestamp? fechaTs = data['fecha'];
          String formattedDate = 'Sin fecha';
          if (fechaTs != null) {
            DateTime fecha = fechaTs.toDate();
            formattedDate =
            "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
          }
          lastRedemptionMessage =
          "$nombre realizó un $tipoRegistro: canjeó $cantidad puntos el $formattedDate.";
        } else {
          lastRedemptionMessage = "No hay canjes recientes.";
          lastRedemptionData = null;
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: redeemedPointsOverTimeStream,
          builder: (context, redeemedPointsSnapshot) {
            if (!redeemedPointsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Datos para la gráfica (se usan los valores absolutos)
            List<FlSpot> redeemedPointsOverTime = [];
            DateTime? firstDate;
            if (redeemedPointsSnapshot.data!.docs.isNotEmpty) {
              var docs = redeemedPointsSnapshot.data!.docs;
              firstDate = docs.first.data()['fecha']?.toDate();
              redeemedPointsOverTime = docs.map((doc) {
                var data = doc.data();
                int cantidad = extractCantidad(data);
                DateTime fecha = data['fecha'].toDate();
                double daysSinceFirst =
                fecha.difference(firstDate!).inDays.toDouble();
                return FlSpot(daysSinceFirst, cantidad.toDouble());
              }).toList();
            }

            // Extraemos los 5 últimos registros (para la mini gráfica)
            List<FlSpot> lastFivePoints = [];
            if (redeemedPointsOverTime.isNotEmpty) {
              final length = redeemedPointsOverTime.length;
              final start = length >= 5 ? length - 5 : 0;
              lastFivePoints = redeemedPointsOverTime.sublist(start, length);
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: canjeadosEsteMesStream,
              builder: (context, canjeadosEsteMesSnapshot) {
                if (!canjeadosEsteMesSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Total canjeado este mes y ranking (suma de los valores de ambos tipos)
                int canjeadosEsteMes = 0;
                String topUserName = "Sin datos";
                int topUserPoints = 0;
                List<MapEntry<String, int>> sortedRanking = [];

                final docs = canjeadosEsteMesSnapshot.data!.docs;
                canjeadosEsteMes = docs.fold(0, (sum, doc) {
                  var data = doc.data();
                  return sum + extractCantidad(data);
                });

                // Ranking por trabajador
                Map<String, int> rankingMap = {};
                for (var doc in docs) {
                  var data = doc.data();
                  String nombre = data['nombreTrabajador'] ?? 'Desconocido';
                  int cantidad = extractCantidad(data);
                  rankingMap[nombre] = (rankingMap[nombre] ?? 0) + cantidad;
                }
                if (rankingMap.isNotEmpty) {
                  sortedRanking = rankingMap.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  topUserName = sortedRanking.first.key;
                  topUserPoints = sortedRanking.first.value;
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      // Notificaciones (último canje)
                      _buildNotificacionesWidget(
                        lastRedemptionMessage,
                        lastRedemptionData,
                      ),
                      const SizedBox(height: 20),
                      // Resumen del Mes (con mini-gráfica de los últimos 5 canjes)
                      _buildResumenMes(
                        canjeadosEsteMes,
                        topUserName,
                        topUserPoints,
                        lastFivePoints,
                        firstDate,
                      ),
                      // Ranking Top 5
                      _buildRankingTop5(sortedRanking),
                      const SizedBox(height: 20),
                      // Lista de datos
                      _buildDataList(redeemedPointsSnapshot.data!.docs, firstDate),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Cabecera con saludo
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
          colorFilter: ColorFilter.mode(
            Colors.black26,
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Row(
          children: [
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
                      color: Colors.amber,
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
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Text(
                    "Hola, Administrador.",
                    style: GoogleFonts.sen(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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

  /// Notificaciones (último canje) – se especifica el tipo de canje en el mensaje
  Widget _buildNotificacionesWidget(
      String lastRedemptionMessage, Map<String, dynamic>? lastRedemptionData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          if (lastRedemptionData != null) {
            _showLastRedemptionDialog(lastRedemptionData);
          } else {
            widget.onNavigateToMuro();
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications,
                color: Colors.amber[700],
                size: 30,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  lastRedemptionMessage,
                  style: GoogleFonts.sen(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diálogo emergente con detalles del último canje
  void _showLastRedemptionDialog(Map<String, dynamic> data) {
    final nombre = data['nombreTrabajador'] ?? 'Desconocido';
    final cantidad = extractCantidad(data);
    final fechaTs = data['fecha'] as Timestamp?;
    String fechaTexto = 'Sin fecha';
    if (fechaTs != null) {
      final fecha = fechaTs.toDate();
      fechaTexto = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    }
    String tipoRegistro = displayTipo(data);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Último Canje"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Trabajador: $nombre"),
              Text("$tipoRegistro: $cantidad puntos"),
              Text("Fecha: $fechaTexto"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  /// Tarjeta de Resumen del Mes (con mini-gráfica de últimos 5 canjes)
  Widget _buildResumenMes(
      int canjeadosEsteMes,
      String topUserName,
      int topUserPoints,
      List<FlSpot> lastFivePoints,
      DateTime? firstDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Resumen del Mes (Canjeos)",
              style: GoogleFonts.sen(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            // Fila con datos principales (total canjeado y top)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResumenItem(
                  icon: Icons.trending_up,
                  label: "Total Canjeado",
                  value: "$canjeadosEsteMes pts",
                ),
                _buildResumenItem(
                  icon: Icons.workspace_premium_rounded,
                  label: "Top",
                  value: "$topUserName ($topUserPoints pts)",
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mini-gráfica de los últimos 5 canjes
            Text(
              "Últimos 5 Canjeos",
              style: GoogleFonts.sen(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildMiniGraficaUltimosCanjes(lastFivePoints, firstDate),
          ],
        ),
      ),
    );
  }

  /// Pequeña gráfica de barras con los últimos 5 canjes
  Widget _buildMiniGraficaUltimosCanjes(
      List<FlSpot> lastFivePoints, DateTime? firstDate) {
    if (lastFivePoints.isEmpty || firstDate == null) {
      return const Text("No hay datos recientes.");
    }
    final barGroups = lastFivePoints.map((spot) {
      return BarChartGroupData(
        x: spot.x.toInt(),
        barRods: [
          BarChartRodData(
            toY: spot.y,
            color: Colors.amber[700],
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    final maxYValue =
    lastFivePoints.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          maxY: maxYValue > 0 ? maxYValue + 5 : 10,
          minY: 0,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  DateTime date =
                  firstDate.add(Duration(days: value.toInt()));
                  String formattedDate = "${date.day}/${date.month}";
                  return Text(
                    formattedDate,
                    style: GoogleFonts.sen(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildResumenItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber[700], size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.sen(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.sen(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Ranking Top 5 (se muestran los 5 trabajadores con mayor cantidad canjeada)
  Widget _buildRankingTop5(List<MapEntry<String, int>> sortedRanking) {
    if (sortedRanking.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text("No hay datos de ranking para este mes."),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ranking Top 5 (Mes)",
              style: GoogleFonts.sen(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: sortedRanking.take(5).map((entry) {
                return ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(
                    entry.key,
                    style: GoogleFonts.sen(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    "${entry.value} pts",
                    style: GoogleFonts.sen(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Listado de datos (se muestra el tipo de canje para cada registro)
  Widget _buildDataList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      DateTime? firstDate) {
    if (docs.isEmpty || firstDate == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No hay datos para mostrar."),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data();
            String nombre = data['nombreTrabajador'] ?? 'Desconocido';
            int cantidad = extractCantidad(data);
            DateTime fecha = data['fecha'].toDate();
            String tipoRegistro = displayTipo(data);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.amber[700]),
                title: Text(
                  "$nombre",
                  style: GoogleFonts.sen(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  "${fecha.day}/${fecha.month}/${fecha.year} - $tipoRegistro: $cantidad pts",
                  style: GoogleFonts.sen(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
