import 'package:flutter/material.dart';
import 'category_statistics.dart';
import 'monthly_statistics.dart';
import 'evolution_expenses.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TipoEstadistica { categoria, mensual, evolucion }

class EstadisticasScreen extends StatefulWidget {
  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TipoEstadistica _tipo = TipoEstadistica.categoria;
  Widget _vistaActual = const SizedBox();
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
    _fechaFin = DateTime.now();
    _actualizarVista();
  }

  void _actualizarVista() {
    if (_uid == null || _fechaInicio == null || _fechaFin == null) return;

    setState(() {
      switch (_tipo) {
        case TipoEstadistica.categoria:
          _vistaActual = EstadisticaPorCategoria(
            key: UniqueKey(),
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin!,
            uid: _uid!,
          );
          break;
        case TipoEstadistica.mensual:
          _vistaActual = EstadisticaMensual(
            key: UniqueKey(),
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin!,
            uid: _uid!,
          );
          break;
        case TipoEstadistica.evolucion:
          _vistaActual = EvolucionGastoScreen(
            key: UniqueKey(),
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin!,
            uid: _uid!,
          );
          break;
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
          title: const Text('Seleccionar rango de fechas'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Desde'),
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
                    title: const Text('Hasta'),
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _fechaInicio = fechaInicio;
                  _fechaFin = fechaFin;
                });
                Navigator.pop(context);
                _actualizarVista();
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  void _cambiarVista(TipoEstadistica tipo) {
    setState(() {
      _tipo = tipo;
    });
    _actualizarVista();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _mostrarSelectorFechas,
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => _cambiarVista(TipoEstadistica.categoria),
                child: const Text('Categoría'),
              ),
              TextButton(
                onPressed: () => _cambiarVista(TipoEstadistica.mensual),
                child: const Text('Mensual'),
              ),
              TextButton(
                onPressed: () => _cambiarVista(TipoEstadistica.evolucion),
                child: const Text('Evolución'),
              ),
            ],
          ),
          Expanded(child: _vistaActual),
        ],
      ),
    );
  }
}
