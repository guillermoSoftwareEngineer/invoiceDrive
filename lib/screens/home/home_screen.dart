import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../invoice/invoice_entry_screen.dart';
import '../charts/invoice_summary_charts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  List<Map<String, dynamic>> flatInvoices = [];
  Map<String, List<Map<String, dynamic>>> groupedInvoices = {};
  double monthlyTotal = 0;
  String currentSortField = 'fechaRegistro';
  bool ascending = false;
  bool groupByDate = true;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final query = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('facturas');

    if (currentSortField == 'fecha') {
      final formato = DateFormat('yyyy-MM-dd');
      final snapshot = await query.get();
      final facturas = snapshot.docs.map((d) => d.data()).toList();
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
      final facturas = snapshot.docs.map((d) => d.data()).toList();
      facturas.sort((a, b) {
        final aTotal = double.tryParse(a['total'].toString()) ?? 0.0;
        final bTotal = double.tryParse(b['total'].toString()) ?? 0.0;
        return ascending
            ? aTotal.compareTo(bTotal)
            : bTotal.compareTo(aTotal);
      });
      setState(() {
        flatInvoices = facturas;
        groupedInvoices = {};
        monthlyTotal = _calcularTotalDelMes(facturas);
      });
    } else {
      final snapshot = await query
          .orderBy(currentSortField, descending: !ascending)
          .get();
      final tempGrouped = <String, List<Map<String, dynamic>>>{};
      final tempFlat = <Map<String, dynamic>>[];
      double tempTotal = 0;
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final fechaRegistro =
            (data['fechaRegistro'] as Timestamp).toDate();
        if (groupByDate) {
          final key =
              DateFormat('yyyy-MM-dd').format(fechaRegistro);
          tempGrouped.putIfAbsent(key, () => []).add(data);
        } else {
          tempFlat.add(data);
        }
        if (fechaRegistro.month == now.month &&
            fechaRegistro.year == now.year) {
          tempTotal +=
              double.tryParse(data['total'].toString()) ?? 0.0;
        }
      }

      setState(() {
        flatInvoices = tempFlat;
        groupedInvoices = tempGrouped;
        monthlyTotal = tempTotal;
      });
    }
  }

  DateTime _safeParseDate(String? value, DateFormat formato) {
    try {
      return formato.parse(value ?? '');
    } catch (_) {
      return DateTime(2000);
    }
  }

  double _calcularTotalDelMes(List<Map<String, dynamic>> facturas) {
    final now = DateTime.now();
    double total = 0;
    for (var f in facturas) {
      final fecha = DateTime.tryParse(f['fecha'] ?? '');
      if (fecha != null &&
          fecha.month == now.month &&
          fecha.year == now.year) {
        total += double.tryParse(f['total'].toString()) ?? 0.0;
      }
    }
    return total;
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
            '¿Estás seguro de que deseas cerrar tu sesión actual?'),
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
                MaterialPageRoute(builder: (_) => const MyApp()),
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
    final nombreMes =
        DateFormat.MMMM('es_CO').format(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        toolbarHeight: 90,
        title: const Text(
          'Inicio',
          style:
              TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        actions: [
          IconButton(
            onPressed: _confirmSignOut,
            icon:
                const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20.0),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                      currencyFormatter
                          .format(monthlyTotal),
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
                  MaterialPageRoute(
                      builder: (_) =>
                          const InvoiceEntryScreen()),
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
                      builder: (_) =>
                          const InvoiceSummaryCharts()),
                );
              },
              child: const Text('Ver estadísticas'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
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
                  onSelected: (v) =>
                      _applyFilter(v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'fechaRegistro',
                        child:
                            Text('Fecha de generación')),
                    PopupMenuItem(
                        value: 'fecha',
                        child:
                            Text('Fecha de la factura')),
                    PopupMenuItem(
                        value: 'total',
                        child: Text(
                            'Valor de la factura')),
                    PopupMenuDivider(),
                    PopupMenuItem(
                        value: 'asc',
                        child: Text('Ascendente')),
                    PopupMenuItem(
                        value: 'desc',
                        child:
                            Text('Descendente')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (groupByDate)
              ...groupedInvoices.entries
                  .expand((entry) {
                final fecha = entry.key;
                final facturas = entry.value;
                return [
                  const SizedBox(height: 10),
                  Text(
                    DateFormat('d MMMM yyyy',
                            'es_CO')
                        .format(
                            DateTime.parse(fecha)),
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 6),
                  ...facturas
                      .map(_buildInvoiceCard),
                ];
              }).toList()
            else
              ...flatInvoices
                  .map(_buildInvoiceCard),
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
        groupByDate = (value != 'fecha' &&
            value != 'total');
      }
    });
    fetchInvoices();
  }

  Widget _buildInvoiceCard(
      Map<String, dynamic> factura) {
    final formatter = NumberFormat.currency(
        locale: 'es_CO',
        symbol: '\$',
        decimalDigits: 0);
    final url =
        factura['urlConsultaDian'] as String?;
    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.symmetric(
          vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 8),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    factura['numeroFactura'] ??
                        'Factura sin número',
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins'),
                  ),
                  Text(
                    factura['categoria'] ??
                        'Sin categoría',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Poppins'),
                  ),
                  if (factura['fecha'] != null)
                    Text(
                      'Fecha: ${factura['fecha']}',
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'Poppins'),
                    ),
                  if (url != null && url.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 4.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Colors.white,
                          backgroundColor:
                              const Color(0xFF128C41),
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    8),
                          ),
                        ),
                        onPressed: () =>
                            _openUrlExternally(
                                url),
                        child: const Text(
                          'Ver en la DIAN',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily:
                                  'Poppins'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              formatter.format(
                  double.tryParse(factura['total']
                          .toString()) ??
                      0.0),
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrlExternally(
      String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri,
        mode: LaunchMode.platformDefault)) {
      debugPrint('No se pudo abrir la URL: $url');
    }
  }
}
