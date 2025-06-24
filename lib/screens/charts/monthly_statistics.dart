import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstadisticaMensual extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String uid;

  const EstadisticaMensual({
    required this.uid,
    required this.fechaInicio,
    required this.fechaFin,
    super.key,
  });

  @override
  State<EstadisticaMensual> createState() => _EstadisticaMensualState();
}

class _EstadisticaMensualState extends State<EstadisticaMensual> {
  List<double> _valores = [];
  List<DateTime> _fechas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerDatosDesdeFirebase();
  }

  Future<void> _obtenerDatosDesdeFirebase() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.uid)
            .collection('facturas')
            .where('fecha', isGreaterThanOrEqualTo: widget.fechaInicio)
            .where('fecha', isLessThanOrEqualTo: widget.fechaFin)
            .get();

    final Map<DateTime, double> agrupadoPorMes = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp timestamp = data['fecha'];
      final dynamic rawTotal = data['total'];
      final double total =
          rawTotal is num
              ? rawTotal.toDouble()
              : double.tryParse(rawTotal.toString()) ?? 0.0;
      final DateTime fecha = timestamp.toDate();
      final DateTime claveMes = DateTime(fecha.year, fecha.month);

      agrupadoPorMes.update(
        claveMes,
        (valor) => valor + total,
        ifAbsent: () => total,
      );
    }

    final fechasOrdenadas = agrupadoPorMes.keys.toList()..sort();
    setState(() {
      _fechas = fechasOrdenadas;
      _valores = fechasOrdenadas.map((f) => agrupadoPorMes[f]!).toList();
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/M/yyyy');
    final fechaInicio = widget.fechaInicio;
    final fechaFin = widget.fechaFin;
    final formatoMes = DateFormat('MMM yyyy', 'es');
    final formatoNumero = NumberFormat.decimalPattern('es');

    final total = _valores.fold(0.0, (a, b) => a + b);
    final promedio = _valores.isEmpty ? 0 : total / _valores.length;
    final maxIndex =
        _valores.isEmpty
            ? -1
            : _valores.indexWhere(
              (v) => v == _valores.reduce((a, b) => a > b ? a : b),
            );
    final minIndex =
        _valores.isEmpty
            ? -1
            : _valores.indexWhere(
              (v) => v == _valores.reduce((a, b) => a < b ? a : b),
            );

    return Scaffold(
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Gasto mensual',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gasto total por mes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: GraficoGastoMensual(
                        datos: _valores,
                        fechas: _fechas,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_valores.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Total: \$${formatoNumero.format(total)}'),
                          const SizedBox(height: 8),
                          if (maxIndex >= 0)
                            Text(
                              'Mes más alto: ${formatoMes.format(_fechas[maxIndex])} (\$${formatoNumero.format(_valores[maxIndex])})',
                            ),
                          if (maxIndex >= 0) const SizedBox(height: 8),
                          if (minIndex >= 0)
                            Text(
                              'Mes más bajo: ${formatoMes.format(_fechas[minIndex])} (\$${formatoNumero.format(_valores[minIndex])})',
                            ),
                          if (minIndex >= 0) const SizedBox(height: 8),
                          Text(
                            'Promedio mensual: \$${formatoNumero.format(promedio)}',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
    );
  }
}

class GraficoGastoMensual extends StatelessWidget {
  final List<double> datos;
  final List<DateTime> fechas;

  const GraficoGastoMensual({
    super.key,
    required this.datos,
    required this.fechas,
  });

  @override
  Widget build(BuildContext context) {
    final formatoMes = DateFormat('MMM yyyy', 'es');
    final formatoNumero = NumberFormat.decimalPattern('es');

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: _calcularIntervalo(datos),
              getTitlesWidget:
                  (value, meta) => Text(
                    formatoNumero.format(value),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= fechas.length)
                  return const SizedBox();
                return Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    formatoMes.format(fechas[index]),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: _calcularIntervalo(datos),
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(fechas.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: datos[index],
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  double _calcularIntervalo(List<double> valores) {
    if (valores.isEmpty) return 1;
    final max = valores.reduce((a, b) => a > b ? a : b);
    return max / 5;
  }
}