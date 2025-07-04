import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> factura;

  const InvoiceDetailScreen({super.key, required this.factura});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    Widget buildField(String label, dynamic value, {bool isCurrency = false}) {
      if (value == null || value.toString().trim().isEmpty)
        return const SizedBox.shrink();
      return ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          isCurrency
              ? currencyFormatter.format(
                double.tryParse(value.toString()) ?? 0.0,
              )
              : value.toString(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Factura'),
        backgroundColor: const Color(0xFF070707),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildField('Número de Factura', factura['numeroFactura']),
            buildField(
              'Fecha',
              DateFormat(
                'dd MMMM yyyy',
                'es_CO',
              ).format((factura['fecha'] as Timestamp).toDate()),
            ),
            buildField('Razón Social', factura['nombreProveedor']),
            buildField('NIT', factura['nit']),
            buildField('Categoría', factura['categoria']),
            buildField('Subtotal', factura['subtotal'], isCurrency: true),
            buildField('IVA', factura['iva'], isCurrency: true),
            buildField('Otros Impuestos', factura['valorOtrosImpuestos'], isCurrency: true),
            buildField('Descripción', factura['descripcion']),
            
            if (factura['urlConsultaDian'] != null &&
                factura['urlConsultaDian'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF128C41),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Consultar en la DIAN'),
                  onPressed: () {
                        _openUrlExternally(factura['urlConsultaDian']);
                      }
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openUrlExternally(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(
    uri,
    mode: LaunchMode.platformDefault,
  )) {
    debugPrint('No se pudo abrir la URL: $url');
  }
}
