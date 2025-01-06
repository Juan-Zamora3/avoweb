// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'trabajador_screen.dart'; // Importa TrabajadorScreen
import 'historialcanje_screen.dart'; // Importa HistorialCanjeScreen
import 'ajustes_admin.dart'; // Importa AjustesAdminScreen
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Índice de la pantalla actual

  // Lista de pantallas para la navegación
  final List<Widget> _screens = [
    const DashboardScreen(), // Pantalla principal
    const TrabajadorScreen(), // Pantalla de trabajadores
    const HistorialCanjeScreen(), // Pantalla de historial de canjes
    const AjustesAdminScreen(), // Pantalla de ajustes
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo gris claro para contraste
      body: _screens[_currentIndex], // Cambia entre las pantallas
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Cambia el índice de la pantalla
          });
        },
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
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Streams para obtener datos en tiempo real
  final Stream<QuerySnapshot<Map<String, dynamic>>> lastRedemptionStream =
  FirebaseFirestore.instance
      .collection('historial_puntos')
      .where('tipo', isEqualTo: 'canjeado')
      .orderBy('fecha', descending: true)
      .limit(1)
      .snapshots();

  final Stream<QuerySnapshot<Map<String, dynamic>>> redeemedPointsOverTimeStream =
  FirebaseFirestore.instance
      .collection('historial_puntos')
      .where('tipo', isEqualTo: 'canjeado')
      .orderBy('fecha', descending: false)
      .snapshots();

  final Stream<QuerySnapshot<Map<String, dynamic>>> canjeadosEsteMesStream =
  FirebaseFirestore.instance
      .collection('historial_puntos')
      .where('tipo', isEqualTo: 'canjeado')
      .where('fecha', isGreaterThanOrEqualTo: DateTime(
      DateTime.now().year, DateTime.now().month, 1))
      .where('fecha', isLessThan: DateTime(
      DateTime.now().year, DateTime.now().month + 1, 1))
      .snapshots();

  // Función para extraer 'cantidad' de un documento de Firestore
  int extractCantidad(Map<String, dynamic> data) {
    if (data['cantidad'] is int) {
      return data['cantidad'];
    } else if (data['cantidad'] is double) {
      return (data['cantidad'] as double).toInt();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: lastRedemptionStream,
      builder: (context, lastRedemptionSnapshot) {
        String lastRedemptionMessage = 'Cargando...';
        if (lastRedemptionSnapshot.hasError) {
          lastRedemptionMessage = "Error al cargar la información.";
        } else if (lastRedemptionSnapshot.hasData) {
          var docs = lastRedemptionSnapshot.data!.docs;
          if (docs.isNotEmpty) {
            var data = docs.first.data();
            String nombre = data['nombreTrabajador'] ?? 'Desconocido';
            int cantidad = extractCantidad(data);
            Timestamp? fechaTs = data['fecha'];
            String formattedDate = 'Sin fecha';
            if (fechaTs != null) {
              DateTime fecha = fechaTs.toDate();
              formattedDate =
              "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
            }
            lastRedemptionMessage =
            "$nombre acaba de canjear $cantidad puntos el $formattedDate.";
          } else {
            lastRedemptionMessage = "No hay canjes recientes.";
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: redeemedPointsOverTimeStream,
          builder: (context, redeemedPointsSnapshot) {
            List<FlSpot> redeemedPointsOverTime = [];
            DateTime? firstDate;
            if (redeemedPointsSnapshot.hasError) {
              // Manejo de error si es necesario
            } else if (redeemedPointsSnapshot.hasData) {
              var docs = redeemedPointsSnapshot.data!.docs;
              if (docs.isNotEmpty) {
                firstDate = (docs.first.data())['fecha']?.toDate();
                redeemedPointsOverTime = docs.map((doc) {
                  var data = doc.data();
                  int cantidad = extractCantidad(data);
                  DateTime fecha = data['fecha'].toDate();
                  double daysSinceFirst = fecha.difference(firstDate!).inDays.toDouble();
                  return FlSpot(daysSinceFirst, cantidad.toDouble());
                }).toList();
              }
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: canjeadosEsteMesStream,
              builder: (context, canjeadosEsteMesSnapshot) {
                int canjeadosEsteMes = 0;
                if (canjeadosEsteMesSnapshot.hasError) {
                  canjeadosEsteMes = 0;
                } else if (canjeadosEsteMesSnapshot.hasData) {
                  canjeadosEsteMes = canjeadosEsteMesSnapshot.data!.docs.fold(0, (sum, doc) {
                    var data = doc.data();
                    return sum + extractCantidad(data);
                  });
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildNotificacionesWidget(lastRedemptionMessage),
                      const SizedBox(height: 20),
                      _buildGraficaCanjesMes(redeemedPointsOverTime, firstDate, canjeadosEsteMes),
                      const SizedBox(height: 20),
                      _buildDataList(redeemedPointsOverTime, firstDate),
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

  /// Widget del encabezado con saludo y avatar
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
            Colors.black26, // Ajustado para menor opacidad
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

                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            // Saludo con ícono
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
            // Puedes agregar otros íconos o widgets aquí si es necesario
          ],
        ),
      ),
    );
  }

  /// Widget que muestra los últimos canjes en forma de "notificaciones"
  Widget _buildNotificacionesWidget(String lastRedemptionMessage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white, // Fondo blanco
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Sombra abajo para efecto de elevación
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
    );
  }

  /// Resumen (gráfico) de puntos canjeados en el mes
  Widget _buildGraficaCanjesMes(
      List<FlSpot> redeemedPointsOverTime, DateTime? firstDate, int canjeadosEsteMes) {
    final mesAnio = DateFormat('MMMM yyyy', 'es_ES').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Fondo blanco
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Sombra abajo para efecto de elevación
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Colors.amber[700],
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  "Evolución de Puntos Canjeados",
                  style: GoogleFonts.sen(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "$canjeadosEsteMes puntos canjeados en $mesAnio",
              style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            _buildLineChart(redeemedPointsOverTime, firstDate),
          ],
        ),
      ),
    );
  }

  /// Función para construir el LineChart usando fl_chart
  Widget _buildLineChart(List<FlSpot> redeemedPointsOverTime, DateTime? firstDate) {
    if (redeemedPointsOverTime.isEmpty || firstDate == null) {
      return const Center(child: Text("No hay datos para mostrar."));
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: redeemedPointsOverTime.length > 5
                    ? (redeemedPointsOverTime.last.x - redeemedPointsOverTime.first.x) / 5
                    : 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  // Calcular la fecha correspondiente al valor
                  DateTime date = firstDate.add(
                    Duration(
                      days: value.toInt(),
                    ),
                  );

                  String formattedDate = "${date.day}/${date.month}";

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      formattedDate,
                      style: GoogleFonts.sen(fontSize: 10, color: Colors.grey[700]),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 50, // Intervalo fijo de 50
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.sen(fontSize: 10, color: Colors.grey[700]),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.black, width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: redeemedPointsOverTime,
              isCurved: true,
              color: Colors.amber[700],
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
          ],
          minX: redeemedPointsOverTime.first.x,
          maxX: redeemedPointsOverTime.last.x,
          minY: 0,
          maxY: redeemedPointsOverTime
              .map((e) => e.y)
              .reduce((a, b) => a > b ? a : b) >
              0
              ? ((redeemedPointsOverTime
              .map((e) => e.y)
              .reduce((a, b) => a > b ? a : b) /
              50)
              .ceilToDouble() *
              50)
              : 200, // Asegura que el máximo sea múltiplo de 50
        ),
      ),
    );
  }

  /// Widget para mostrar los datos obtenidos en una lista
  Widget _buildDataList(List<FlSpot> redeemedPointsOverTime, DateTime? firstDate) {
    if (redeemedPointsOverTime.isEmpty || firstDate == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // Sombra abajo para efecto de elevación
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
          color: Colors.white, // Fondo blanco
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Sombra abajo para efecto de elevación
            ),
          ],
        ),
        // Limitar la altura máxima para evitar desbordamiento
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4, // 40% de la altura de la pantalla
        ),
        child: ListView.builder(
          itemCount: redeemedPointsOverTime.length,
          itemBuilder: (context, index) {
            FlSpot spot = redeemedPointsOverTime[index];
            DateTime date = firstDate!.add(Duration(days: spot.x.toInt()));
            return ListTile(
              leading: Icon(Icons.check_circle, color: Colors.amber[700]),
              title: Text(
                "${date.day}/${date.month}/${date.year}",
                style: GoogleFonts.sen(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              trailing: Text(
                "${spot.y.toInt()} puntos",
                style: GoogleFonts.sen(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
