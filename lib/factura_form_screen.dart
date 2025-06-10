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
  bool mostrarNumeroFactura = false;
  List<String> categorias = [];
  String? categoriaSeleccionada;

  File? _imagenFactura;

  Future<void> cargarCategorias() async {
    await Future.delayed(Duration.zero); // asegura que el widget esté montado
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

    subtotalController.addListener(calcularTotal);
    ivaController.addListener(calcularTotal);

    _imagenFactura = widget.imagenFactura;

    calcularTotal();

    cargarCategorias();
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
        'categoria': categoriaSeleccionada ?? 'Sin categoría',
      };

      // Agrega número si existe
      final numero = numeroController.text.trim();
      if (numero.isNotEmpty) {
        datos['numeroFactura'] = numero;
      }

      // 🔹 Agrega el enlace de la DIAN si existe
      if (widget.datos?['urlConsultaDian'] != null) {
        datos['urlConsultaDian'] = widget.datos!['urlConsultaDian'];
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

  void mostrarDialogoNuevaCategoria() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Nueva Categoría"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
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
                        .add({'nombre': nombre});

                    Navigator.pop(context);
                    await cargarCategorias();
                    setState(() => categoriaSeleccionada = nombre);
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          ),
    );
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría *'),
                value: categoriaSeleccionada,
                items:
                    categorias
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() => categoriaSeleccionada = value);
                },
                validator:
                    (value) =>
                        value == null
                            ? 'Por favor seleccione una categoría'
                            : null,
              ),

              TextButton.icon(
                onPressed: mostrarDialogoNuevaCategoria,
                icon: const Icon(Icons.add),
                label: const Text("Crear categoría"),
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
