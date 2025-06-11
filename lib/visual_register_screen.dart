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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Los filtros y estadísticas aparecerán en esta pantalla',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
