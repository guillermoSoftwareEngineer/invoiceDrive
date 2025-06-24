import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ModoEvolucion { diario, semanal }

class EvolucionGastoScreen extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String uid;

  const EvolucionGastoScreen({
    super.key,
    required this.fechaInicio,
    required this.fechaFin,
    required this.uid,
  });

  @override
  State<EvolucionGastoScreen> createState() => _EvolucionGastoScreenState();
}

class _EvolucionGastoScreenState extends State<EvolucionGastoScreen> {
  ModoEvolucion _modo = ModoEvolucion.diario;
  List<DateTime> _fechas = [];
  List<double> _valores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerDatosDesdeFirebase();
  }

  Future<void> _obtenerDatosDesdeFirebase() async {
    setState(() => _cargando = true);
    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.uid)
            .collection('facturas')
            .where('fecha', isGreaterThanOrEqualTo: widget.fechaInicio)
            .where('fecha', isLessThanOrEqualTo: widget.fechaFin)
            .get();

    final Map<DateTime, double> agrupado = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp timestamp = data['fecha'];
      final dynamic rawTotal = data['total'];
      final double total =
          rawTotal is num
              ? rawTotal.toDouble()
              : double.tryParse(rawTotal.toString()) ?? 0.0;
      final DateTime fecha = timestamp.toDate();

      DateTime clave;
      if (_modo == ModoEvolucion.semanal) {
        final int semana = fecha.weekday;
        clave = fecha.subtract(Duration(days: semana - 1));
      } else {
        clave = DateTime(fecha.year, fecha.month, fecha.day);
      }

      agrupado.update(clave, (valor) => valor + total, ifAbsent: () => total);
    }

    final fechasOrdenadas = agrupado.keys.toList()..sort();
    setState(() {
      _fechas = fechasOrdenadas;
      _valores = fechasOrdenadas.map((f) => agrupado[f]!).toList();
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        child:
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evolución del gasto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(widget.fechaInicio)} – ${DateFormat('dd/MM/yyyy').format(widget.fechaFin)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Diario'),
                          selected: _modo == ModoEvolucion.diario,
                          onSelected: (valor) {
                            if (valor) {
                              setState(() => _modo = ModoEvolucion.diario);
                              _obtenerDatosDesdeFirebase();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Semanal'),
                          selected: _modo == ModoEvolucion.semanal,
                          onSelected: (valor) {
                            if (valor) {
                              setState(() => _modo = ModoEvolucion.semanal);
                              _obtenerDatosDesdeFirebase();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: SingleChildScrollView(
                        key: ValueKey(_valores.length + _modo.index),
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: (_valores.length * 40).toDouble().clamp(
                            300,
                            double.infinity,
                          ),
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (
                                    List<LineBarSpot> touchedSpots,
                                  ) {
                                    return touchedSpots.map((spot) {
                                      final fecha = _fechas[spot.x.toInt()];
                                      final formato = DateFormat('dd/MM');
                                      return LineTooltipItem(
                                        '${formato.format(fecha)}\n${spot.y.toStringAsFixed(2)}',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          backgroundColor: Colors.black87,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= _fechas.length) {
                                        return const SizedBox(); // <-- necesita estar dentro de llaves {}
                                      }
                                      final fecha = _fechas[index];
                                      final formato = DateFormat('dd/MM');
                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 4,
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Text(
                                            formato.format(fecha),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      );

                                    }

                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value == 0) return const Text('0');
                                      return Text(
                                        '${(value / 1000).toStringAsFixed(1)}K',
                                        style: const TextStyle(fontSize: 10),
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
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              minX: 0,
                              maxX: (_fechas.length - 1).toDouble(),
                              minY: 0,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    _valores.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      _valores[index],
                                    ),
                                  ),
                                  isCurved: true,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
