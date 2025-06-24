import 'package:flutter/material.dart';
import 'category_statistics.dart';
import 'monthly_statistics.dart';
import 'evolution_expenses.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EstadisticasScreen extends StatefulWidget {
  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  Widget _vistaActual = SizedBox();
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fechaInicio = DateTime.now().subtract(Duration(days: 30));
    _fechaFin = DateTime.now();
    _vistaActual = EstadisticaPorCategoria(
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
      uid: _uid!,
    );
  }

  void _filtrarFacturas() {
    print("Filtrando desde $_fechaInicio hasta $_fechaFin");
    setState(() {
      // Actualiza la vista actual con las nuevas fechas
      if (_vistaActual is EstadisticaPorCategoria) {
        _vistaActual = EstadisticaPorCategoria(
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaFin!,
          uid: _uid!,
        );
      } else if (_vistaActual is EstadisticaMensual) {
        _vistaActual = EstadisticaMensual(
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaFin!,
          uid: _uid!,
        );
      } else if (_vistaActual is EvolucionGastoScreen) {
        _vistaActual = EvolucionGastoScreen(
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaFin!,
          uid: _uid!,
        );
      }
    });
  }

  Future<void> _mostrarSelectorFechas() async {
    DateTime? fechaInicio = _fechaInicio;
    DateTime? fechaFin = _fechaFin;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Seleccionar rango de fechas'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Desde'),
                    subtitle: Text(
                      fechaInicio != null
                          ? '${fechaInicio?.day}/${fechaInicio?.month}/${fechaInicio?.year}'
                          : 'Seleccionar fecha',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaInicio ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => fechaInicio = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Hasta'),
                    subtitle: Text(
                      fechaFin != null
                          ? '${fechaFin?.day}/${fechaFin?.month}/${fechaFin?.year}'
                          : 'Seleccionar fecha',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaFin ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => fechaFin = picked);
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Aplicar'),
              onPressed: () {
                if (fechaInicio != null && fechaFin != null) {
                  setState(() {
                    _fechaInicio = fechaInicio;
                    _fechaFin = fechaFin;
                  });
                  _filtrarFacturas();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _formatoFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: _mostrarSelectorFechas,
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '${_formatoFecha(_fechaInicio!)} - ${_formatoFecha(_fechaFin!)}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(child: Text('Menú de estadísticas')),
            ListTile(
              title: Text('Gastos por Categoría'),
              onTap: () {
                setState(() {
                  _vistaActual = EstadisticaPorCategoria(
                    fechaInicio: _fechaInicio!,
                    fechaFin: _fechaFin!,
                    uid: _uid!,
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Gastos mensuales'),
              onTap: () {
                setState(() {
                  _vistaActual = EstadisticaMensual(
                    fechaInicio: _fechaInicio!,
                    fechaFin: _fechaFin!,
                    uid: _uid!,
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Evolución de gastos'),
              onTap: () {
                setState(() {
                  _vistaActual = EvolucionGastoScreen(
                    fechaInicio: _fechaInicio!,
                    fechaFin: _fechaFin!,
                    uid: _uid!,
                  );
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _vistaActual,
    );
  }
}
