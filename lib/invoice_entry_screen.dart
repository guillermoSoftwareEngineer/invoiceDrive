import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'factura_form_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;

class InvoiceEntryScreen extends StatefulWidget {
  const InvoiceEntryScreen({super.key});

  @override
  State<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  String _scannedData = '';
  bool _isScanned = false; // Indica si ya se escaneó algo
  bool _huboError = false; // Indica si hubo un error en el escaneo/procesamiento
  File? _imagenSeleccionada;

  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(ms.BarcodeCapture capture) {
    // Si ya se escaneó y estamos procesando, no hacer nada más
    if (_isScanned) return;

    for (final ms.Barcode barcode in capture.barcodes) {
      final String? value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        // Pausar el escáner para evitar múltiples detecciones rápidas
        _scannerController.stop();

        setState(() {
          _isScanned = true;
          _scannedData = value;
          _huboError = false; // Resetear error si se detecta algo
        });

        final datosExtraidos = analizarDatosDelCodigo(value);

        if (datosExtraidos == null) {
          setState(() => _huboError = true);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se detectó información útil en el código.'),
              backgroundColor: Colors.red,
            ),
          );
          // Permitir reintentar escaneo si no hay datos útiles
          _scannerController.start();
          setState(() {
            _isScanned = false; // Permitir nuevo escaneo
            _scannedData = ''; // Limpiar datos escaneados
          });
          return; // Salir si no hay datos útiles
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FacturaFormScreen(
              datos: datosExtraidos,
              contenidoOriginal: value,
              imagenFactura: _imagenSeleccionada,
            ),
          ),
        );
        break; // Procesar solo el primer código de barras detectado
      }
    }
    if (!mounted) return;
  }

  void _resetScan() {
    setState(() {
      _scannedData = '';
      _isScanned = false;
      _huboError = false;
      _imagenSeleccionada = null;
    });
    _scannerController.start(); // Reiniciar la cámara
  }

  Future<void> _escanearDesdeGaleria() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      _scannerController.stop(); // Pausar la cámara en vivo antes de procesar imagen

      setState(() {
        _imagenSeleccionada = File(imagen.path);
        _isScanned = true; // Indicar que se ha procesado (aunque sea de galería)
        _huboError = false;
        _scannedData = ''; // Limpiar datos previos
      });

      final inputImage = InputImage.fromFile(_imagenSeleccionada!);
      final scanner = BarcodeScanner();
      final List<mlkit.Barcode> barcodes = await scanner.processImage(inputImage);

      if (!mounted) return;
      if (barcodes.isEmpty || barcodes.first.rawValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se detectó ningún código en la imagen.'),
            backgroundColor: Colors.red,
          ),
        );
        _resetScan(); // Reiniciar para permitir nuevo escaneo o selección
        return;
      }

      final codigo = barcodes.first.rawValue!;
      setState(() {
        _scannedData = codigo; // Mostrar el código escaneado de la imagen
      });
      final datos = analizarDatosDelCodigo(codigo);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FacturaFormScreen(
            datos: datos,
            contenidoOriginal: codigo,
            imagenFactura: _imagenSeleccionada,
          ),
        ),
      );
    } else {
      _scannerController.start(); // Si el usuario cancela, reiniciar la cámara
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: const Text(
          'Registro Camara',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Acción para ajustes, si los hubiera
              // print('Ajustes');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fondo con líneas onduladas, similar al mockup 
          Positioned.fill(
            child: CustomPaint(
              painter: WavyBackgroundPainter(),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 20),
              // Área del escáner / cámara 
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: MediaQuery.of(context).size.height * 0.45, // Ajusta la altura según necesidad
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C), // Color de fondo del recuadro
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: Colors.transparent), // Borde sutil
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 50),
                                Text(
                                  'Error en la cámara: ${error.toString()}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Icono de cámara en el centro, como en el mockup, si no hay video o para superponer 
                      // Solo visible si no hay imagen seleccionada y no se está escaneando aún
                      if (!_isScanned && _imagenSeleccionada == null)
                        const Icon(
                          Icons.camera_alt, // O un asset si tienes el icono exacto del mockup
                          color: Color(0xFF6552FE),
                          size: 100,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Botones "Camara" y "AIDC" 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _escanearDesdeGaleria, // Reutilizamos la función de galería
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6552FE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Camara',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Navegar al nuevo formulario AIDC
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FacturaFormScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'MANUAL',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Sección para mostrar datos escaneados o imagen (manteniendo lógica)
              // Esta sección será menos visible debido a la navegación inmediata en escaneo exitoso
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _scannedData.isNotEmpty
                          ? 'Datos escaneados:\n$_scannedData'
                          : 'Esperando escaneo o selección de imagen...',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    if (_imagenSeleccionada != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imagenSeleccionada!,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (_huboError)
                      ElevatedButton.icon(
                        onPressed: _resetScan,
                        icon: const Icon(Icons.restart_alt, color: Colors.white),
                        label: const Text(
                          'Volver a escanear',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Clase para dibujar las líneas onduladas del fondo 
class WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Linea 1 (Azul claro)
    paint.color = const Color(0xFF5D9EEF).withOpacity(0.5);
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
        size.width * 0.2, size.height * 0.75,
        size.width * 0.4, size.height * 0.9,
        size.width * 0.6, size.height * 0.85);
    path.cubicTo(
        size.width * 0.8, size.height * 0.8,
        size.width * 0.9, size.height * 0.95,
        size.width, size.height * 0.9);
    canvas.drawPath(path, paint);

    path.reset();

    // Linea 2 (Verde)
    paint.color = const Color(0xFF6CFB6E).withOpacity(0.5);
    path.moveTo(0, size.height * 0.85);
    path.cubicTo(
        size.width * 0.15, size.height * 0.8,
        size.width * 0.35, size.height * 0.95,
        size.width * 0.55, size.height * 0.9);
    path.cubicTo(
        size.width * 0.75, size.height * 0.85,
        size.width * 0.85, size.height * 1.0,
        size.width, size.height * 0.95);
    canvas.drawPath(path, paint);

    path.reset();

    // Linea 3 (Amarillo)
    paint.color = const Color(0xFFFEE700).withOpacity(0.5);
    path.moveTo(0, size.height * 0.9);
    path.cubicTo(
        size.width * 0.1, size.height * 0.85,
        size.width * 0.3, size.height * 1.05,
        size.width * 0.5, size.height * 1.0);
    path.cubicTo(
        size.width * 0.7, size.height * 0.95,
        size.width * 0.8, size.height * 1.1,
        size.width, size.height * 1.05);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Esta función debe venir de tu lógica (mantuvimos la original del archivo)
Map<String, dynamic>? analizarDatosDelCodigo(String texto) {
  // Analiza y retorna Map con los datos o null
  // Ejemplo mínimo:
  if (texto.contains('FecFac')) {
    return {'fecha': '2025-06-08'};
  }
  return null;
}
