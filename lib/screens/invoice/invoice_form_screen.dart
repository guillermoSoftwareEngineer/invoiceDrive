import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:invoice_d/screens/widgets/loading_screen.dart';
import '../home/home_screen.dart';

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
  late TextEditingController razonSocialController;
  late TextEditingController descripcionController;
  late TextEditingController otrosImpuestosController;

  bool mostrarNumeroFactura = false;
  List<String> categorias = [];
  String? categoriaSeleccionada;
  File? _imagenFactura;

  Future<void> cargarCategorias() async {
    await Future.delayed(Duration.zero);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('categorias')
            .get();

    if (!mounted) return;

    setState(() {
      categorias = snapshot.docs.map((e) => e['nombre'].toString()).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    final datos = widget.datos ?? {};
    mostrarNumeroFactura =
        datos.containsKey('numeroFactura') || datos.containsKey('NumFac');

    razonSocialController = TextEditingController(
      text: datos['razonSocial'] ?? '',
    );
    descripcionController = TextEditingController(
      text: datos['descripcion'] ?? '',
    );
    fechaController = TextEditingController(
      text: datos['fecha'] ?? datos['FecFac'] ?? '',
    );
    numeroController = TextEditingController(
      text: datos['numeroFactura'] ?? datos['NumFac'] ?? '',
    );
    nitController = TextEditingController(
      text: datos['nit'] ?? datos['NitFac'] ?? '',
    );
    subtotalController = TextEditingController(
      text: datos['subtotal'] ?? datos['ValFac'] ?? '',
    );
    ivaController = TextEditingController(
      text: datos['iva'] ?? datos['ValIva'] ?? '',
    );
    totalController = TextEditingController(
      text: datos['total'] ?? datos['ValTolFac'] ?? '',
    );
    otrosImpuestosController = TextEditingController(
      text: datos['ValOtrIm'] ?? '',
    );


    subtotalController.addListener(_calcularTotal);
    ivaController.addListener(_calcularTotal);

    _imagenFactura = widget.imagenFactura;

    _calcularTotal();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('categorias')
        .get();

    if (!mounted) return;
    setState(() {
      categorias = snapshot.docs.map((e) => e['nombre'].toString()).toList();
    });
  }

  void _calcularTotal() {
    setState(() {
      double subtotal = double.tryParse(subtotalController.text) ?? 0;
      double iva = double.tryParse(ivaController.text) ?? 0;
      double otros = double.tryParse(otrosImpuestosController.text) ?? 0;

      double total = subtotal + iva + otros;
      totalController.text = total.toStringAsFixed(2);
    });
  }


  Future<String?> _subirImagen(File imagen) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('facturas')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(imagen);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return null;
    }
  }

  Future<void> guardarFactura() async {
    if (!_formKey.currentState!.validate()) return;
    final ctx = context;

    Navigator.of(ctx).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LoadingScreen(mensaje: 'Guardando factura...'),
      ),
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Navigator.of(ctx).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No hay sesión activa')),
      );
      return;
    }

      final DateTime? fechaFactura =
          fechaController.text.trim().isNotEmpty
              ? DateFormat('yyyy-MM-dd').parse(fechaController.text.trim())
              : null;

      final datos = {
        'fecha': fechaFactura,
        'nit': nitController.text.trim(),
        'subtotal': subtotalController.text.trim(),
        'iva': ivaController.text.trim(),
        'valorOtrosImpuestos': otrosImpuestosController.text,
        'total': totalController.text.trim(),
        'fechaRegistro': FieldValue.serverTimestamp(),
        'categoria': categoriaSeleccionada ?? 'Sin categoría',
        'razonSocial': razonSocialController.text.trim(),
      };

      final numero = numeroController.text.trim();
      if (numero.isNotEmpty) {
        datos['numeroFactura'] = numero;
      }

      final descripcion = descripcionController.text.trim();
      if (descripcion.isNotEmpty) {
        datos['descripcion'] = descripcion;
      }

      if (widget.datos?['urlConsultaDian'] != null) {
        datos['urlConsultaDian'] = widget.datos!['urlConsultaDian'];
      }

      if (_imagenFactura != null) {
        final url = await _subirImagen(_imagenFactura!);
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

      Navigator.of(ctx).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Factura guardada correctamente')),
      );

      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      Navigator.of(ctx).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error al guardar la factura: $e')),
      );
    }
  }

  void _mostrarDialogoNuevaCategoria() {
    final controller = TextEditingController();
    final ctx = context;

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = controller.text.trim();
              if (nombre.isEmpty) return;

                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(uid)
                        .collection('categorias')
                        .add({
                          'razonSocial': razonSocialController.text.trim(),
                          'descripcion': descripcionController.text.trim(),
                          'nombre': nombre,
                        });

                Navigator.pop(ctx);
                await _cargarCategorias();
                if (!mounted) return;
                setState(() => categoriaSeleccionada = nombre);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
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
              if (mostrarNumeroFactura)
                TextFormField(
                  controller: numeroController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Número de Factura',
                    suffixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              TextFormField(
                controller: fechaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Fecha de la Factura',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final DateTime? fechaSeleccionada = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    locale: const Locale('es', 'CO'),
                    helpText: 'Selecciona la fecha de la factura',
                  );
                  if (fechaSeleccionada != null) {
                    fechaController.text =
                        DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
                  }
                },
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
                controller: razonSocialController,
                decoration: const InputDecoration(
                  labelText: 'Nombre o razón social *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría *'),
                value: categoriaSeleccionada,
                items: categorias
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (v) => setState(() => categoriaSeleccionada = v),
                validator: (v) =>
                    v == null ? 'Por favor seleccione una categoría' : null,
              ),
              TextButton.icon(
                onPressed: _mostrarDialogoNuevaCategoria,
                icon: const Icon(Icons.add),
                label: const Text('Crear categoría'),
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
                controller: otrosImpuestosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor otros impuestos',
                ),
                onChanged: (_) => _calcularTotal(),
              ),
              TextFormField(
                controller: totalController,
                readOnly: true,
                decoration:
                    const InputDecoration(labelText: 'Total de la factura'),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: guardarFactura,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Factura'),
              ),
              const SizedBox(height: 30),
              if (_imagenFactura != null) ...[
                const Text('Imagen asociada:'),
                const SizedBox(height: 10),
                Image.file(_imagenFactura!, height: 200),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
