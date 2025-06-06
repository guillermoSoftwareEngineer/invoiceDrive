import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'factura_form_screen.dart';

class InvoiceEntryScreen extends StatefulWidget {
  const InvoiceEntryScreen({super.key});

  @override
  State<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  String _scannedData = '';
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        setState(() {
          _isScanned = true;
        });

        final datosExtraidos = analizarDatosDelCodigo(value);

        // Mostrar mensaje si no se extrajo nada útil
        if (datosExtraidos == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se detectó información útil en el código.'),
            ),
          );
        }

        // Ir a pantalla de ingreso con o sin datos
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => FacturaFormScreen(
                  datos: datosExtraidos,
                  contenidoOriginal: value,
                ),
          ),
        );

        break;
      }
    }
  }


  void _resetScan() {
    setState(() {
      _scannedData = '';
      _isScanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: const Text(
          'Escáner de Factura',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFF070707),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: MobileScannerController(facing: CameraFacing.back),
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _scannedData.isNotEmpty
                        ? 'Datos escaneados:\n$_scannedData'
                        : 'Escanea un código QR o de barras...',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _resetScan,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Volver a escanear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6552FE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic>? analizarDatosDelCodigo(String value) {
  final Map<String, dynamic> datos = {};

  final lines = value.split(RegExp(r'\r?\n'));
  for (var line in lines) {
    final partes = line.split('=');
    if (partes.length == 2) {
      final key = partes[0].trim();
      final val = partes[1].trim();

      switch (key) {
        case 'FecFac':
          datos['fecha'] = val;
          break;
        case 'ValTolFac':
          datos['total'] = val;
          break;
        case 'NitFac':
          datos['nit'] = val;
          break;
        case 'ValFac':
          datos['subtotal'] = val;
          break;
        case 'ValIva':
          datos['iva'] = val;
          break;
        case 'NumFac':
          datos['numeroFactura'] = val;
          break;
      }
    }
  }

  return datos.isEmpty ? null : datos;
}
