import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class EstadisticaPorCategoria extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String uid;

  const EstadisticaPorCategoria({
    required this.uid,
    required this.fechaInicio,
    required this.fechaFin,
    super.key,
  });

  @override
  State<EstadisticaPorCategoria> createState() =>
      _EstadisticaPorCategoriaState();
}

class _EstadisticaPorCategoriaState extends State<EstadisticaPorCategoria> {
  Map<String, double> _gastosPorCategoria = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.uid)
            .collection('facturas')
            .where(
              'fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fechaInicio),
            )
            .where(
              'fecha',
              isLessThanOrEqualTo: Timestamp.fromDate(widget.fechaFin),
            )
            .get();

    final datos = <String, double>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final categoria = data['categoria'] ?? 'Sin categoría';
      final total = double.tryParse(data['total'].toString()) ?? 0.0;
      datos[categoria] = (datos[categoria] ?? 0) + total;
    }

    setState(() {
      _gastosPorCategoria = datos;
      _cargando = false;
    });
  }

  String _formatoFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  List<Color> _generarColores(int cantidad) {
    final random = Random();
    return List.generate(cantidad, (_) {
      return Color.fromARGB(
        255,
        random.nextInt(200) + 30,
        random.nextInt(200) + 30,
        random.nextInt(200) + 30,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _gastosPorCategoria.keys.toList();
    final valores = _gastosPorCategoria.values.toList();
    final total = valores.fold(0.0, (a, b) => a + b);
    final colores = _generarColores(categorias.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gastos por categoria',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _cargando
                ? Center(child: CircularProgressIndicator())
                : _gastosPorCategoria.isEmpty
                ? Center(child: Text('No hay datos en este rango de fechas'))
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Del ${_formatoFecha(widget.fechaInicio)} al ${_formatoFecha(widget.fechaFin)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: List.generate(categorias.length, (i) {
                              final porcentaje =
                                  total == 0 ? 0 : (valores[i] / total) * 100;
                              return PieChartSectionData(
                                color: colores[i],
                                value: valores[i],
                                title: '${porcentaje.toStringAsFixed(1)}%',
                                radius: 70,
                                titleStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              );
                            }),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: categorias.length,
                        itemBuilder: (context, i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  color: colores[i],
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    categorias[i],
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '\$${valores[i].toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
