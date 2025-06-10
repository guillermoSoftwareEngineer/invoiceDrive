import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FacturaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? datos;
  final String? contenidoOriginal;
  final File? imagenFactura;

  const FacturaFormScreen({
    super.key,
    this.datos,
    this.contenidoOriginal,
    this.imagenFactura,
  });

  @override
  State<FacturaFormScreen> createState() => _FacturaFormScreenState();
}

class _FacturaFormScreenState extends State<FacturaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController fechaController;
  late TextEditingController numeroController;
  late TextEditingController nitController;
  late TextEditingController subtotalController;
  late TextEditingController ivaController;
  late TextEditingController totalController;

  File? _imagenFactura;

  @override
  void initState() {
    super.initState();

    fechaController = TextEditingController(text: widget.datos?['fecha'] ?? '');
    numeroController = TextEditingController(
      text: widget.datos?['numeroFactura'] ?? '',
    );
    nitController = TextEditingController(text: widget.datos?['nit'] ?? '');
    subtotalController = TextEditingController(
      text: widget.datos?['subtotal'] ?? '',
    );
    ivaController = TextEditingController(text: widget.datos?['iva'] ?? '');
    totalController = TextEditingController();

    subtotalController.addListener(calcularTotal);
    ivaController.addListener(calcularTotal);

    _imagenFactura = widget.imagenFactura;
    calcularTotal(); // inicializa el total si hay datos precargados
  }

  void calcularTotal() {
    final subtotal = double.tryParse(subtotalController.text) ?? 0.0;
    final iva = double.tryParse(ivaController.text) ?? 0.0;
    final total = subtotal + iva;
    totalController.text = total.toStringAsFixed(2);
  }

  Future<String?> subirImagen(File imagen) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('facturas')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(imagen);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Error subiendo imagen: $e");
      return null;
    }
  }

  Future<void> guardarFactura() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No hay sesión activa')));
        return;
      }

      final datos = {
        'fecha': fechaController.text.trim(),
        'nit': nitController.text.trim(),
        'subtotal': subtotalController.text.trim(),
        'iva': ivaController.text.trim(),
        'total': totalController.text.trim(),
        'fechaRegistro': FieldValue.serverTimestamp(),
      };

      final numero = numeroController.text.trim();
      if (numero.isNotEmpty) {
        datos['numeroFactura'] = numero;
      }

      // Subir imagen si existe
      if (_imagenFactura != null) {
        final url = await subirImagen(_imagenFactura!);
        if (url != null) {
          datos['urlImagen'] = url;
        }
      }

      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('facturas')
            .add(datos);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura guardada correctamente')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la factura: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    fechaController.dispose();
    numeroController.dispose();
    nitController.dispose();
    subtotalController.dispose();
    ivaController.dispose();
    totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulario de Factura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: numeroController,
                enabled: widget.datos?['numeroFactura'] == null,
                decoration: const InputDecoration(
                  labelText: 'Número de Factura *',
                  suffixIcon: Icon(Icons.lock_outline),
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Campo obligatorio'
                            : null,
              ),
              TextFormField(
                controller: fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de la Factura',
                ),
              ),
              TextFormField(
                controller: nitController,
                decoration: const InputDecoration(
                  labelText: 'NIT del proveedor *',
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Campo obligatorio'
                            : null,
              ),
              TextFormField(
                controller: subtotalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Subtotal'),
              ),
              TextFormField(
                controller: ivaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'IVA'),
              ),
              TextFormField(
                controller: totalController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Total de la factura',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: guardarFactura,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Factura'),
              ),
              const SizedBox(height: 30),
              if (_imagenFactura != null)
                Column(
                  children: [
                    const Text('Imagen asociada:'),
                    const SizedBox(height: 10),
                    Image.file(_imagenFactura!, height: 200),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
