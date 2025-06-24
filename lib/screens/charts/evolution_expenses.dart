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

  Future<void> _seleccionarRangoDeFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: widget.fechaInicio,
        end: widget.fechaFin,
      ),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (rango != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => EvolucionGastoScreen(
                fechaInicio: rango.start,
                fechaFin: rango.end,
                uid: widget.uid,
              ),
        ),
      );
    }
  }

  double _determinarIntervaloEjeVertical() {
    if (_valores.isEmpty) return 100;
    final valorMaximo = _valores.reduce((a, b) => a > b ? a : b);
    if (valorMaximo >= 10000) return 5000;
    if (valorMaximo >= 5000) return 1000;
    if (valorMaximo >= 1000) return 500;
    return 100;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Evolución del gasto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.date_range),
                          onPressed: _seleccionarRangoDeFechas,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${formatoFecha.format(widget.fechaInicio)} – ${formatoFecha.format(widget.fechaFin)}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: [
                        _modo == ModoEvolucion.diario,
                        _modo == ModoEvolucion.semanal,
                      ],
                      onPressed: (index) {
                        setState(() {
                          _modo =
                              index == 0
                                  ? ModoEvolucion.diario
                                  : ModoEvolucion.semanal;
                          _obtenerDatosDesdeFirebase();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      selectedColor: Colors.white,
                      fillColor: Colors.deepPurple,
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Diario'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Semanal'),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: (_fechas.length * 60).toDouble(),
                          child: LineChart(
                            LineChartData(
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= _fechas.length)
                                        return const SizedBox();
                                      final fecha = _fechas[index];
                                      final etiqueta = DateFormat(
                                        'dd MMM',
                                        'es',
                                      ).format(fecha);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          etiqueta,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: _determinarIntervaloEjeVertical(),
                                    getTitlesWidget: (value, meta) {
                                      String texto;
                                      if (value >= 1000) {
                                        texto =
                                            '${(value / 1000).toStringAsFixed(0)}k';
                                      } else {
                                        texto = value.toInt().toString();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: Text(
                                          texto,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine:
                                    (value) => FlLine(
                                      color: Colors.white10,
                                      strokeWidth: 1,
                                    ),
                                getDrawingVerticalLine:
                                    (value) => FlLine(
                                      color: Colors.white10,
                                      strokeWidth: 1,
                                    ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1,
                                ),
                              ),
                              minX: 0,
                              maxX: (_fechas.length - 1).toDouble(),
                              minY: 0,
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.cyanAccent,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                  spots: List.generate(
                                    _fechas.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      _valores[index],
                                    ),
                                  ),
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
