import 'package:flutter/material.dart';
import 'factura_form_screen.dart'; // Asegúrate de importar tu formulario

class VisualRegisterScreen extends StatelessWidget {
  final bool huboError;
  final String? mensajeError;

  const VisualRegisterScreen({
    super.key,
    this.huboError = false,
    this.mensajeError,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: const Text(
          'Registro Visual y Estadísticas',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFF070707),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/statistics_mockup.png', height: 300),
            const SizedBox(height: 20),
            Text(
              huboError
                  ? mensajeError ?? 'No se pudo leer el código'
                  : 'Simulación de Gráficos y Datos de Gastos',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 🔁 Botón condicional solo si hubo error
            if (huboError)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Regresa para escanear nuevamente
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Volver a escanear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // ➕ Botón para agregar factura manualmente
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FacturaFormScreen()),
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

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text('Ver Más Detalles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6552FE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
