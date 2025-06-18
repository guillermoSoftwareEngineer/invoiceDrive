import 'package:flutter/material.dart';
import 'dart:io';
import 'package:uuid/uuid.dart'; // Import uuid package
import 'invoice.dart'; // Import Invoice model

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
  final TextEditingController _cufeCudeController = TextEditingController();
  final TextEditingController _nitEmisorController = TextEditingController();
  final TextEditingController _nitCompradorController = TextEditingController();
  final TextEditingController _fechaEmisionController = TextEditingController();
  final TextEditingController _valorTotalController = TextEditingController();
  final TextEditingController _impuestosController = TextEditingController();
  final TextEditingController _resumenValidacionController = TextEditingController();

  final uuid = const Uuid(); // Create a Uuid instance

  @override
  void initState() {
    super.initState();
    if (widget.datos != null) {
      // Populate fields if data is provided (e.g., from scan)
      // Map scanned data to new fields as appropriate
      _fechaEmisionController.text = widget.datos!['fecha'] ?? '';
      // Add mapping for other fields if available in widget.datos
    }
  }

  @override
  void dispose() {
    _cufeCudeController.dispose();
    _nitEmisorController.dispose();
    _nitCompradorController.dispose();
    _fechaEmisionController.dispose();
    _valorTotalController.dispose();
    _impuestosController.dispose();
    _resumenValidacionController.dispose();
    super.dispose();
  }

  void _saveFactura() {
    if (_formKey.currentState!.validate()) {
      // Process and save the invoice data

      // Create an Invoice object (Invoice model might need updates)
      final newInvoice = Invoice(
        id: _cufeCudeController.text.isNotEmpty ? _cufeCudeController.text : uuid.v4(), // Use CUFE/CUDE if available, otherwise generate ID
        title: 'Factura CUFE/CUDE: ${_cufeCudeController.text}', // Example title
        amount: double.tryParse(_valorTotalController.text) ?? 0.0,
        date: DateTime.tryParse(_fechaEmisionController.text) ?? DateTime.now(), // Parse date or use current
        type: 'Egreso', // Assuming invoices are typically expenses
        status: 'Pendiente', // Default status
        // Add other fields to Invoice model or store as a map/JSON string
        // For now, storing other data in a map
        additionalData: {
          'nitEmisor': _nitEmisorController.text,
          'nitComprador': _nitCompradorController.text,
          'impuestos': _impuestosController.text,
          'resumenValidacion': _resumenValidacionController.text,
        },
      );

      // Pass the new invoice back to the previous screen
      Navigator.pop(context, newInvoice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: const Text(
          'Detalles de Factura',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: const Color(0xFF070707),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.imagenFactura != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Image.file(
                    widget.imagenFactura!,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              TextFormField(
                controller: _cufeCudeController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  labelText: 'Número de factura (CUFE/CUDE)',
                  labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6552FE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el CUFE/CUDE';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _nitEmisorController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  labelText: 'Nit del emisor',
                  labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6552FE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el Nit del emisor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _nitCompradorController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  labelText: 'Nit del comprador',
                  labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6552FE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el Nit del comprador';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _fechaEmisionController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  labelText: 'Fecha de emisión (AAAA-MM-DD)',
                  labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6552FE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa la fecha de emisión';
                  }
                  // Basic date format validation (AAAA-MM-DD)
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                     return 'Formato de fecha incorrecto (AAAA-MM-DD)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _valorTotalController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor total de la factura',
                  labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6552FE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el valor total';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _impuestosController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  labelText: 'Impuestos (IVA, ICA, etc.)',
                  labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6552FE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa los impuestos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _resumenValidacionController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  labelText: 'Resumen de validación',
                  labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6552FE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el resumen de validación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveFactura,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6552FE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar Factura',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
