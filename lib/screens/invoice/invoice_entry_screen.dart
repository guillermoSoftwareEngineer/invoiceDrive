// lib/screens/invoice/invoice_entry_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'invoice_form_screen.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:invoice_d/screens/widgets/loading_screen.dart';
import 'invoice_form_screen.dart';
import 'invoice_form_screen.dart';

class InvoiceEntryScreen extends StatefulWidget {
  const InvoiceEntryScreen({super.key});

  @override
  State<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  String _scannedData = '';
  bool _isScanned = false;
  bool _huboError = false;
  File? _imagenSeleccionada;

  final MobileScannerController _scannerController = MobileScannerController();

  Future<void> _seleccionarImagen() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imagenSeleccionada = File(pickedFile.path);
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.black,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.file(File(pickedFile.path)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear código de la imagen'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _escanearDesdeArchivo(File(pickedFile.path));
                    },
                  ),
                ],
              ),
            ),
      );
    }
  }

  Future<File> redimensionarImagen(File original) async {
    final bytes = await original.readAsBytes();
    final image = img.decodeImage(bytes); // usa img
    if (image == null) return original;

    final resized = img.copyResize(image, width: 800);
    final resizedBytes = img.encodeJpg(resized);
    final path = original.path.replaceFirst('.jpg', '_resized.jpg');
    return File(path).writeAsBytes(resizedBytes);
  }

  Future<void> _escanearDesdeArchivo(File archivo) async {
    final ctx = context;
    Navigator.of(ctx).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LoadingScreen(mensaje: 'Analizando imagen...'),
      ),
    );

    final archivoRedimensionado = await redimensionarImagen(archivo);
    final inputImage = mlkit.InputImage.fromFile(archivoRedimensionado);
    final scanner = mlkit.BarcodeScanner(formats: [mlkit.BarcodeFormat.qrCode]);
    final barcodes = await scanner.processImage(inputImage);

    Navigator.of(ctx).pop();

    if (barcodes.isEmpty || barcodes.first.rawValue == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('No se detectó ningún código en la imagen.'),
        ),
      );
      return;
    }

    final codigo = barcodes.first.rawValue!;
    final datos = analizarDatosDelCodigo(codigo);

    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(
        builder:
            (_) => FacturaFormScreen(
              datos: datos,
              contenidoOriginal: codigo,
              imagenFactura: archivo,
            ),
      ),
    );
  }

  void _navegarAlFormulario() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => FacturaFormScreen(
              datos: {},
              contenidoOriginal: '',
              imagenFactura: _imagenSeleccionada,
            ),
      ),
    );
  }

  void _onDetect(ms.BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        setState(() {
          _isScanned = true;
          _scannedData = value;
        });
        final datos = analizarDatosDelCodigo(value);
        if (datos == null) {
          setState(() => _huboError = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se detectó información útil en el código.'),
            ),
          );
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => FacturaFormScreen(
                  datos: datos,
                  contenidoOriginal: value,
                  imagenFactura: _imagenSeleccionada,
                ),
          ),
        );
        break;
      }
    }
  }

  Future<void> _escanearDesdeGaleria() async {
    final ctx = context;
    Navigator.of(ctx).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LoadingScreen(mensaje: 'Analizando imagen...'),
      ),
    );

    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery);
    Navigator.of(ctx).pop();
    if (imagen == null) return;

    final file = File(imagen.path);
    setState(() => _imagenSeleccionada = file);

    final inputImage = mlkit.InputImage.fromFile(file);
    final scanner = mlkit.BarcodeScanner(formats: [mlkit.BarcodeFormat.qrCode]);
    final barcodes = await scanner.processImage(inputImage);

    if (barcodes.isEmpty || barcodes.first.rawValue == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('No se detectó ningún código en la imagen.'),
        ),
      );
      return;
    }

    final codigo = barcodes.first.rawValue!;
    final datos = analizarDatosDelCodigo(codigo);

    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(
        builder:
            (_) => FacturaFormScreen(
              datos: datos,
              contenidoOriginal: codigo,
              imagenFactura: file,
            ),
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _scannedData = '';
      _isScanned = false;
      _huboError = false;
      _imagenSeleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: const Text('Escáner de Factura'),
        backgroundColor: const Color(0xFF070707),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.45, // reemplazo de Expanded flex: 3
              child: ms.MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            ),
            SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.55, // reemplazo de Expanded flex: 2
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _scannedData.isNotEmpty
                          ? 'Datos escaneados:\n$_scannedData'
                          : 'Escanea un código o selecciona una imagen.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_imagenSeleccionada != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imagenSeleccionada!,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (_huboError)
                      ElevatedButton.icon(
                        onPressed: _resetScan,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Volver a escanear'),
                      ),
                    OutlinedButton.icon(
                      onPressed: _escanearDesdeGaleria,
                      icon: const Icon(Icons.photo),
                      label: const Text('Seleccionar imagen desde galería'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FacturaFormScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_document),
                      label: const Text('Agregar factura manualmente'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic>? analizarDatosDelCodigo(String texto) {
  final datos = <String, String>{};
  final regex = RegExp(r'(\w+)=([^\n\r]+)');
  for (final match in regex.allMatches(texto)) {
    final key = match.group(1)?.trim();
    final value = match.group(2)?.trim();
    if (key != null && value != null) datos[key] = value;
  }
  if (datos.isEmpty) return null;
  return {
    'fecha': datos['FecFac'],
    'numeroFactura': datos['NumFac'],
    'nit': datos['NitFac'],
    'subtotal': datos['ValFac'],
    'iva': datos['ValIva'],
    'total': datos['ValTolFac'],
    'urlConsultaDian': datos['QRCode'],
    'ValOtrIm': datos['ValOtrIm'] ?? '0',
  };
}
