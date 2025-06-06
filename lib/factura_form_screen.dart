import 'package:flutter/material.dart';

class FacturaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? datos;
  final String? contenidoOriginal;

  const FacturaFormScreen({super.key, this.datos, this.contenidoOriginal});

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

    calcularTotal(); // inicializa el total si hay datos precargados
  }

  void calcularTotal() {
    final subtotal = double.tryParse(subtotalController.text) ?? 0.0;
    final iva = double.tryParse(ivaController.text) ?? 0.0;
    final total = subtotal + iva;
    totalController.text = total.toStringAsFixed(2);
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final datos = {
                      'numeroFactura': numeroController.text,
                      'fecha': fechaController.text,
                      'nit': nitController.text,
                      'subtotal': subtotalController.text,
                      'iva': ivaController.text,
                      'total': totalController.text,
                    };

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Datos validados y listos para guardar'),
                      ),
                    );

                    print(datos);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Factura'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
