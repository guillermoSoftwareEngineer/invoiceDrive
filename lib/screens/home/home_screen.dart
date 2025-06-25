import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:invoice_d/screens/auth/login_email_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../invoice/invoice_form_screen.dart';
import '../../models/invoice.dart';
import '../invoice/invoice_entry_screen.dart';
import '../charts/statistics.dart';
import '../invoice/invoice_detail_screen.dart';
import '../charts/statistics.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> flatInvoices;
  final Map<String, List<Map<String, dynamic>>> groupedInvoices;
  final double monthlyTotal;

  const HomeScreen({
    super.key,
    required this.flatInvoices,
    required this.groupedInvoices,
    required this.monthlyTotal,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  DateTime? fechaInicio;
  DateTime? fechaFin;
  bool filtroPorFechaActivo = false;

  List<Map<String, dynamic>> flatInvoices = [];
  Map<String, List<Map<String, dynamic>>> groupedInvoices = {};
  double monthlyTotal = 0;
  String currentSortField = 'fechaRegistro';
  bool ascending = false;
  bool groupByDate = true;

  @override
  void initState() {
    super.initState();
    flatInvoices = widget.flatInvoices;
    groupedInvoices = widget.groupedInvoices;
    monthlyTotal = widget.monthlyTotal;
  }

  Future<
    ({
      List<Map<String, dynamic>> flatInvoices,
      Map<String, List<Map<String, dynamic>>> groupedInvoices,
      double monthlyTotal,
    })
  >
  fetchInvoices({
    required String sortField,
    required bool ascending,
    required bool groupByDate,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return (
        flatInvoices: <Map<String, dynamic>>[],
        groupedInvoices: <String, List<Map<String, dynamic>>>{},
        monthlyTotal: 0.0,
      );
    }

    final query = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('facturas');

    final snapshot =
        (sortField == 'fecha' || sortField == 'total')
            ? await query.get()
            : await query.orderBy(sortField, descending: !ascending).get();

    final facturas = snapshot.docs.map((d) => d.data()).toList();

    if (sortField == 'fecha') {
      facturas.sort((a, b) {
        final fa = a['fecha'] is Timestamp ? a['fecha'].toDate() : a['fecha'];
        final fb = b['fecha'] is Timestamp ? b['fecha'].toDate() : b['fecha'];

        if (fa is DateTime && fb is DateTime) {
          return ascending ? fa.compareTo(fb) : fb.compareTo(fa);
        }
        return 0;
      });

      return (
        flatInvoices: facturas,
        groupedInvoices: <String, List<Map<String, dynamic>>>{},
        monthlyTotal: _calcularTotalDelMes(facturas),
      );
    }

    if (sortField == 'total') {
      facturas.sort((a, b) {
        final aTotal = double.tryParse(a['total'].toString()) ?? 0.0;
        final bTotal = double.tryParse(b['total'].toString()) ?? 0.0;
        return ascending ? aTotal.compareTo(bTotal) : bTotal.compareTo(aTotal);
      });

      return (
        flatInvoices: facturas,
        groupedInvoices: <String, List<Map<String, dynamic>>>{},
        monthlyTotal: _calcularTotalDelMes(facturas),
      );
    }


    final tempGrouped = <String, List<Map<String, dynamic>>>{};
    final tempFlat = <Map<String, dynamic>>[];
    double tempTotal = 0;
    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final fechaRegistro = (data['fechaRegistro'] as Timestamp).toDate();

      if (groupByDate) {
        final key = DateFormat('yyyy-MM-dd').format(fechaRegistro);
        tempGrouped.putIfAbsent(key, () => []).add(data);
      } else {
        tempFlat.add(data);
      }

      if (fechaRegistro.month == now.month && fechaRegistro.year == now.year) {
        tempTotal += double.tryParse(data['total'].toString()) ?? 0.0;
      }
    }

    return (
      flatInvoices: tempFlat,
      groupedInvoices: tempGrouped,
      monthlyTotal: tempTotal,
    );
  }

  void _filtrarFacturasPorRango() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || fechaInicio == null || fechaFin == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('facturas')
            .where(
              'fecha',
              isGreaterThanOrEqualTo: DateTime(
                fechaInicio!.year,
                fechaInicio!.month,
                fechaInicio!.day,
              ),
            )
            .where(
              'fecha',
              isLessThanOrEqualTo: DateTime(
                fechaFin!.year,
                fechaFin!.month,
                fechaFin!.day,
                23,
                59,
                59,
              ),
            )
            .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron facturas en el rango de fechas.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final List<Map<String, dynamic>> filtradas =
        snapshot.docs.map((doc) => doc.data()).toList();

    setState(() {
      flatInvoices = filtradas;
      groupedInvoices = {};
      groupByDate = false;
      filtroPorFechaActivo = true;
      monthlyTotal = _calcularTotalDelMes(filtradas);
    });
  }

  double _calcularTotalDelMes(List<Map<String, dynamic>> facturas) {
    final now = DateTime.now();
    double total = 0;
    for (var f in facturas) {
      final fecha = (f['fecha'] as Timestamp).toDate();
      if (fecha.month == now.month && fecha.year == now.year) {
        total += double.tryParse(f['total'].toString()) ?? 0.0;
      }
    }
    return total;
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('¿Cerrar sesión?'),
            content: const Text(
              '¿Estás seguro de que deseas cerrar tu sesión actual?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginEmailScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Sí, cerrar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreMes = DateFormat.MMMM('es_CO').format(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        toolbarHeight: 90,
        title: const Text(
          'Inicio',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        actions: [
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: const Color(0xFF6552FE),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos del mes de '
                      '${nombreMes[0].toUpperCase()}${nombreMes.substring(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currencyFormatter.format(monthlyTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvoiceEntryScreen(),
                        ),
                      );
                    },
                    child: Icon(Icons.add),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EstadisticasScreen()),
                      );
                    },
                    child: Icon(Icons.bar_chart),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Facturas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => mostrarModalOrdenamiento(context),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.date_range,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () async {
                    final resultado = await mostrarSelectorFechas(
                      context,
                      fechaInicio,
                      fechaFin,
                    );
                    if (resultado != null) {
                      final (inicio, fin) = resultado;
                      if (inicio == null || fin == null) return;

                      setState(() {
                        fechaInicio = inicio;
                        fechaFin = fin;
                      });

                      _filtrarFacturasPorRango();
                    }
                  },
                ),
              ],
            ),
            if (fechaInicio != null && fechaFin != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      setState(() {
                        filtroPorFechaActivo = false;
                        fechaInicio = null;
                        fechaFin = null;
                      });

                      final result = await fetchInvoices(
                        sortField: currentSortField,
                        ascending: ascending,
                        groupByDate: groupByDate,
                      );

                      setState(() {
                        flatInvoices = result.flatInvoices;
                        groupedInvoices = result.groupedInvoices;
                        monthlyTotal = result.monthlyTotal;
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.white),
                    label: const Text(
                      'Quitar filtro de fecha',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            groupByDate
                ? Column(
                  children:
                      groupedInvoices.entries.map((entry) {
                        final fecha = entry.key;
                        final facturas = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              DateFormat(
                                'd MMMM yyyy',
                                'es_CO',
                              ).format(DateTime.parse(fecha)),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...facturas
                                .map(
                                  (factura) =>
                                      _buildInvoiceCard(context, factura),
                                )
                                .toList(),
                          ],
                        );
                      }).toList(),
                )
                : Column(
                  children:
                      flatInvoices.map((factura) {
                        return _buildInvoiceCard(context, factura);
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }

  void _applyFilter(String value) async {
    setState(() {
      if (value == 'asc') {
        ascending = true;
      } else if (value == 'desc') {
        ascending = false;
      } else {
        currentSortField = value;
        groupByDate = (value != 'fecha' && value != 'total');
      }
    });

    if (filtroPorFechaActivo) {
      _ordenarFacturasLocalmente();
    } else {
      final result = await fetchInvoices(
        sortField: currentSortField,
        ascending: ascending,
        groupByDate: groupByDate,
      );
      setState(() {
        flatInvoices = result.flatInvoices;
        groupedInvoices = result.groupedInvoices;
        monthlyTotal = result.monthlyTotal;
      });
    }
  }

  void _ordenarFacturasLocalmente() {
    setState(() {
      flatInvoices.sort((a, b) {
        if (currentSortField == 'fecha' ||
            currentSortField == 'fechaRegistro') {
          final aValor = a[currentSortField];
          final bValor = b[currentSortField];

          DateTime? aFecha;
          DateTime? bFecha;

          if (aValor is Timestamp) {
            aFecha = aValor.toDate();
          } else if (aValor is DateTime) {
            aFecha = aValor;
          }

          if (bValor is Timestamp) {
            bFecha = bValor.toDate();
          } else if (bValor is DateTime) {
            bFecha = bValor;
          }

          if (aFecha == null || bFecha == null) return 0;

          return ascending
              ? aFecha.compareTo(bFecha)
              : bFecha.compareTo(aFecha);
        }

        if (currentSortField == 'total') {
          final aTotal = double.tryParse(a['total'].toString()) ?? 0.0;
          final bTotal = double.tryParse(b['total'].toString()) ?? 0.0;
          return ascending
              ? aTotal.compareTo(bTotal)
              : bTotal.compareTo(aTotal);
        }

        return 0;
      });
    });
  }


  void _applyFiltroConEstado(String campo, bool asc) async {
    setState(() {
      currentSortField = campo;
      ascending = asc;
      groupByDate = (campo == 'fechaRegistro');
    });


    if (filtroPorFechaActivo) {
      _ordenarFacturasLocalmente();
    } else {
      final result = await fetchInvoices(
        sortField: campo,
        ascending: asc,
        groupByDate: groupByDate,
      );
      setState(() {
        flatInvoices = result.flatInvoices;
        groupedInvoices = result.groupedInvoices;
        monthlyTotal = result.monthlyTotal;
      });
    }
  }
  Future<void> mostrarModalOrdenamiento(BuildContext context) async {
    String? campo = currentSortField;
    bool asc = ascending;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ordenar facturas'),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Fecha de generación'),
                    value: 'fechaRegistro',
                    groupValue: campo,
                    onChanged:
                        filtroPorFechaActivo
                            ? null
                            : (value) => setState(() => campo = value!),
                    subtitle:
                        filtroPorFechaActivo
                            ? const Text(
                              'Deshabilitado por filtrado de fechas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                            : null,
                  ),
                  RadioListTile<String>(
                    title: const Text('Fecha de la factura'),
                    value: 'fecha',
                    groupValue: campo,
                    onChanged: (value) => setState(() => campo = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Valor de la factura'),
                    value: 'total',
                    groupValue: campo,
                    onChanged: (value) => setState(() => campo = value!),
                  ),
                  const Divider(),
                  CheckboxListTile(
                    title: const Text('Ascendente'),
                    value: asc,
                    onChanged: (v) => setState(() => asc = v!),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _applyFiltroConEstado(campo!, asc);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }
}

Widget _buildInvoiceCard(BuildContext context, Map<String, dynamic> factura) {
  final currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  final String? url = factura['urlConsultaDian'];

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(factura: factura),
        ),
      );
    },
    child: Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    factura['razonSocial'] ?? 'Factura sin razón social',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    factura['categoria'] ?? 'Sin categoría',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (factura['fecha'] != null)
                    Text(
                      'Fecha: ${DateFormat('dd MMMM yyyy', 'es_CO').format((factura['fecha'] as Timestamp).toDate())}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ),
            Text(
              currencyFormatter.format(
                double.tryParse(factura['total'].toString()) ?? 0.0,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openUrlExternally(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
    debugPrint('No se pudo abrir la URL: $url');
  }
}

DateTime _safeParseDate(String? value, DateFormat formato) {
  try {
    return formato.parse(value ?? '');
  } catch (_) {
    return DateTime(2000);
  }
}

Future<(DateTime?, DateTime?)?> mostrarSelectorFechas(
  BuildContext context,
  DateTime? inicio,
  DateTime? fin,
) {
  return showDialog<(DateTime?, DateTime?)>(
    context: context,
    builder: (context) {
      DateTime? fechaInicio = inicio;
      DateTime? fechaFin = fin;

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
                      firstDate: DateTime(2020),
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
                      firstDate: DateTime(2020),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, (fechaInicio, fechaFin)),
            child: const Text('Aplicar'),
          ),
        ],
      );
    },
  );
}
