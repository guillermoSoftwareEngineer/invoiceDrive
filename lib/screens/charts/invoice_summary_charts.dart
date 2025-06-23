import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceSummaryCharts extends StatefulWidget {
  const InvoiceSummaryCharts({super.key});

  @override
  State<InvoiceSummaryCharts> createState() => _InvoiceSummaryChartsState();
}

class _InvoiceSummaryChartsState extends State<InvoiceSummaryCharts>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('facturas')
        .get();

    final list = snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      if (data['fechaRegistro'] is Timestamp) {
        data['fechaRegistro'] =
            (data['fechaRegistro'] as Timestamp).toDate();
      }
      return data;
    }).toList();

    setState(() {
      _invoices = list;
      _loading = false;
    });
  }

  Map<K, double> _aggregate<K>(K Function(Map<String, dynamic>) keyFn) {
    final acc = <K, double>{};
    for (final inv in _invoices) {
      final key = keyFn(inv);
      final val = double.tryParse(inv['total'].toString()) ?? 0.0;
      acc[key] = (acc[key] ?? 0) + val;
    }
    return acc;
  }

  LineChartData _buildChart(
    Map<dynamic, double> dataMap,
    String Function(dynamic) labelFn,
  ) {
    final entries = dataMap.entries.toList()
      ..sort((a, b) {
        if (a.key is DateTime && b.key is DateTime) {
          return (a.key as DateTime)
              .compareTo(b.key as DateTime);
        }
        return a.key.toString().compareTo(b.key.toString());
      });

    final spots = <FlSpot>[];
    for (var i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value));
    }

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= entries.length) {
                return const SizedBox();
              }
              final label = labelFn(entries[idx].key);
              // Simplemente devolvemos un Text, sin usar SideTitleWidget
              return Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white70));
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: entries.isNotEmpty
                ? entries
                        .map((e) => e.value)
                        .reduce((a, b) => b > a ? b : a) /
                    5
                : 1,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          color: Colors.purpleAccent,
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro Visual')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dayMap = _aggregate<DateTime>((inv) {
      final dt = inv['fechaRegistro'] as DateTime;
      return DateTime(dt.year, dt.month, dt.day);
    });
    final monthMap = _aggregate<DateTime>((inv) {
      final dt = inv['fechaRegistro'] as DateTime;
      return DateTime(dt.year, dt.month);
    });
    final yearMap = _aggregate<int>((inv) {
      final dt = inv['fechaRegistro'] as DateTime;
      return dt.year;
    });
    final allMap = _aggregate<DateTime>(
        (inv) => inv['fechaRegistro'] as DateTime);

    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: const Text('Registro Visual'),
        backgroundColor: const Color(0xFF070707),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorColor: Colors.purpleAccent,
          tabs: const [
            Tab(text: 'DÍA'),
            Tab(text: 'MES'),
            Tab(text: 'AÑO'),
            Tab(text: 'TODAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(_buildChart(
                dayMap, (k) => DateFormat('d/MM').format(k as DateTime))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(_buildChart(monthMap, (k) =>
                DateFormat('MMM yy', 'es_CO').format(k as DateTime))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
                _buildChart(yearMap, (k) => k.toString())),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(_buildChart(
                allMap, (k) => DateFormat('d/MM/yy').format(k as DateTime))),
          ),
        ],
      ),
    );
  }
}
