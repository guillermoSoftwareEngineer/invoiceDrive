import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'invoice_entry_screen.dart';
import 'visual_register_screen.dart';
import 'main.dart';

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

    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('facturas')
            .orderBy('fechaRegistro', descending: true)
            .get();

    Map<String, List<Map<String, dynamic>>> tempGrouped = {};
    double tempMonthlyTotal = 0;
    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final fecha = (data['fechaRegistro'] as Timestamp).toDate();
      final formattedDate = DateFormat('yyyy-MM-dd').format(fecha);

      // Agrupar por fecha
      tempGrouped.putIfAbsent(formattedDate, () => []);
      tempGrouped[formattedDate]!.add(data);

      // Sumar si pertenece al mes actual
      if (fecha.month == now.month && fecha.year == now.year) {
        final total = double.tryParse(data['total'].toString()) ?? 0.0;
        tempMonthlyTotal += total;
      }
    }

    setState(() {
      groupedInvoices = tempGrouped;
      monthlyTotal = tempMonthlyTotal;
    });
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
            const SizedBox(height: 20),
            const Text(
              'Facturas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            ...groupedInvoices.entries.map((entry) {
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
                  ...facturas.map((factura) {
                    return Card(
                      color: const Color(0xFF1C1C1C),
                      child: ListTile(
                        title: Text(
                          factura['numeroFactura'] ?? 'Factura sin número',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        subtitle: Text(
                          factura['categoria'] ?? 'Sin categoría',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        trailing: Text(
                          currencyFormatter.format(
                            double.tryParse(factura['total'].toString()) ?? 0.0,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
