import 'package:flutter/material.dart';

class VisualRegisterScreen extends StatelessWidget {
  const VisualRegisterScreen({super.key});

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
        iconTheme: const IconThemeData(color: Colors.white), // Color del icono de retroceso
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí puedes poner tu mockup de estadísticas
            // Asegúrate de que esta imagen exista en assets/images/
            Image.asset(
              'assets/images/statistics_mockup.png', // Usa tu imagen de mockup de estadísticas
              height: 300,
            ),
            const SizedBox(height: 20),
            const Text(
              'Simulación de Gráficos y Datos de Gastos',
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
                Navigator.pop(context); // Vuelve a la pantalla anterior
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text('Ver Más Detalles'),
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