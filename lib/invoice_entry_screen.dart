import 'package:flutter/material.dart';

class InvoiceEntryScreen extends StatelessWidget {
  const InvoiceEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: const Text(
          'Ingresa Factura',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFF070707),
        iconTheme: const IconThemeData(color: Colors.white), // Color del icono de retroceso
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí puedes poner tu mockup de cámara
            // Asegúrate de que esta imagen exista en assets/images/
            Image.asset(
              'assets/images/camera_mockup.png', // Usa tu imagen de mockup de cámara
              height: 300,
            ),
            const SizedBox(height: 20),
            const Text(
              'Simulación de Captura de Facturas',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Aquí podrías agregar la lógica real para tomar una foto
                Navigator.pop(context); // Vuelve a la pantalla anterior
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6552FE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}