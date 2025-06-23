import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../invoice/invoice_form_screen.dart';
import '../../models/invoice.dart';
import '../invoice/invoice_entry_screen.dart';
import '../../main.dart';
import '../invoice/invoice_detail_screen.dart';
import '../charts/invoice_summary_charts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  DateTime? fechaInicio;
  DateTime? fechaFin;

  List<Map<String, dynamic>> flatInvoices = [];

  String currentSortField = 'fechaRegistro';
  bool ascending = false;
  bool groupByDate = true;

  Map<String, List<Map<String, dynamic>>> groupedInvoices = {};
  double monthlyTotal = 0;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  void fetchInvoices() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('facturas');

    if (currentSortField == 'fecha') {
      final formato = DateFormat('yyyy-MM-dd');
      final snapshot = await query.get();
      List<Map<String, dynamic>> facturas =
          snapshot.docs.map((doc) => doc.data()).toList();

      facturas.sort((a, b) {
        final fa = _safeParseDate(a['fecha'], formato);
        final fb = _safeParseDate(b['fecha'], formato);
        return ascending ? fa.compareTo(fb) : fb.compareTo(fa);
      });

      setState(() {
        flatInvoices = facturas;
        groupedInvoices = {};
        monthlyTotal = _calcularTotalDelMes(facturas);
      });
    } else if (currentSortField == 'total') {
      final snapshot = await query.get();
      List<Map<String, dynamic>> facturas =
          snapshot.docs.map((doc) => doc.data()).toList();

      facturas.sort((a, b) {
        final aTotal = double.tryParse(a['total'].toString()) ?? 0.0;
        final bTotal = double.tryParse(b['total'].toString()) ?? 0.0;
        return ascending ? aTotal.compareTo(bTotal) : bTotal.compareTo(aTotal);
      });

      setState(() {
        flatInvoices = facturas;
        groupedInvoices = {};
        monthlyTotal = _calcularTotalDelMes(facturas);
      });
    } else {
      final snapshot =
          await query.orderBy(currentSortField, descending: !ascending).get();

      Map<String, List<Map<String, dynamic>>> tempGrouped = {};
      List<Map<String, dynamic>> tempFlatInvoices = [];
      double tempMonthlyTotal = 0;
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final DateTime fechaRegistro =
            (data['fechaRegistro'] as Timestamp).toDate();

        if (groupByDate) {
          final formattedDate = DateFormat('yyyy-MM-dd').format(fechaRegistro);
          tempGrouped.putIfAbsent(formattedDate, () => []);
          tempGrouped[formattedDate]!.add(data);
        } else {
          tempFlatInvoices.add(data);
        }

        if (fechaRegistro.month == now.month &&
            fechaRegistro.year == now.year) {
          final total = double.tryParse(data['total'].toString()) ?? 0.0;
          tempMonthlyTotal += total;
        }
      }

      setState(() {
        groupedInvoices = tempGrouped;
        flatInvoices = tempFlatInvoices;
        monthlyTotal = tempMonthlyTotal;
      });
    }
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

    final formato = DateFormat('yyyy-MM-dd');

    final List<Map<String, dynamic>> filtradas =
        snapshot.docs.map((doc) => doc.data()).where((factura) {
          try {
            final fecha = formato.parse(factura['fecha']);
            return fecha.isAfter(
                  fechaInicio!.subtract(const Duration(days: 1)),
                ) &&
                fecha.isBefore(fechaFin!.add(const Duration(days: 1)));
          } catch (_) {
            return false;
          }
        }).toList();

    setState(() {
      flatInvoices = filtradas;
      groupedInvoices = {};
      monthlyTotal = _calcularTotalDelMes(filtradas);
    });
  }

  double _calcularTotalDelMes(List<Map<String, dynamic>> facturas) {
    final now = DateTime.now();
    double total = 0;
    for (var factura in facturas) {
      final fecha = DateTime.tryParse(factura['fecha'] ?? '');
      if (fecha != null && fecha.month == now.month && fecha.year == now.year) {
        total += double.tryParse(factura['total'].toString()) ?? 0.0;
      }
    }
    return total;
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Cerrar sesión?'),
            content: const Text(
              '¿Estás seguro de que deseas cerrar tu sesión actual?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MyApp()),
                      (route) => false,
                    );
                  }
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
            tooltip: 'Cerrar sesión',
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
                      'Gastos del mes de ${nombreMes[0].toUpperCase()}${nombreMes.substring(1)}',
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InvoiceEntryScreen()),
                );
              },
              child: const Text('Agregar Factura'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InvoiceSummaryCharts(),
                  ),
                );
              },
              child: const Text('Ver estadísticas'),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Facturas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 28,
                  ),
                  onSelected: (value) {
                    _applyFilter(value);
                  },
                  itemBuilder:
                      (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'fechaRegistro',
                          child: Text('Fecha de generación'),
                        ),
                        const PopupMenuItem(
                          value: 'fecha',
                          child: Text('Fecha de la factura'),
                        ),
                        const PopupMenuItem(
                          value: 'total',
                          child: Text('Valor de la factura'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'asc',
                          child: Text('Ascendente'),
                        ),
                        const PopupMenuItem(
                          value: 'desc',
                          child: Text('Descendente'),
                        ),
                      ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.date_range,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () async {
                    final now = DateTime.now();

                    final inicio = await showDatePicker(
                      context: context,
                      initialDate: fechaInicio ?? now,
                      firstDate: DateTime(2020),
                      lastDate: now,
                      helpText: 'Selecciona la fecha inicial',
                      locale: const Locale('es', 'CO'),
                    );

                    if (inicio == null) return;

                    final fin = await showDatePicker(
                      context: context,
                      initialDate: fechaFin ?? now,
                      firstDate: inicio,
                      lastDate: now,
                      helpText: 'Selecciona la fecha final',
                      locale: const Locale('es', 'CO'),
                    );

                    if (fin == null) return;

                    setState(() {
                      fechaInicio = inicio;
                      fechaFin = fin;
                    });

                    _filtrarFacturasPorRango();
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
                    onPressed: () {
                      setState(() {
                        fechaInicio = null;
                        fechaFin = null;
                      });
                      fetchInvoices(); // vuelve a traer todas las facturas
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

  void _applyFilter(String value) {
    setState(() {
      if (value == 'asc') {
        ascending = true;
      } else if (value == 'desc') {
        ascending = false;
      } else {
        currentSortField = value;
        groupByDate = (value != 'fecha' && value != 'total') ? true : false;
      }
    });

    fetchInvoices();
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
