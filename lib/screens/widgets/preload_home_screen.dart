import 'package:flutter/material.dart';
import 'package:invoice_d/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PreloadHomeScreen extends StatefulWidget {
  const PreloadHomeScreen({super.key});

  @override
  State<PreloadHomeScreen> createState() => _PreloadHomeScreenState();
}

class _PreloadHomeScreenState extends State<PreloadHomeScreen> {
  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final query = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('facturas')
        .orderBy('fechaRegistro', descending: true);
    final snapshot = await query.get();

    final List<Map<String, dynamic>> tempFlat = [];
    final Map<String, List<Map<String, dynamic>>> tempGrouped = {};
    double tempTotal = 0;
    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final fechaRegistro = (data['fechaRegistro'] as Timestamp).toDate();
      final key = DateFormat('yyyy-MM-dd').format(fechaRegistro);
      tempGrouped.putIfAbsent(key, () => []).add(data);
      tempFlat.add(data);
      if (fechaRegistro.month == now.month && fechaRegistro.year == now.year) {
        tempTotal += double.tryParse(data['total'].toString()) ?? 0.0;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => HomeScreen(
              flatInvoices: tempFlat,
              groupedInvoices: tempGrouped,
              monthlyTotal: tempTotal,
            ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('assets/splash/splash_image.png'),
              width: 150,
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.purple),
          ],
        ),
      ),
    );
  }
}
