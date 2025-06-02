import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INVOICE D',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6552FE), // Morado principal
        scaffoldBackgroundColor: const Color(0xFF070707), // Fondo muy oscuro, casi negro
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF070707),
          foregroundColor: Color(0xFFFFFFFF), // Blanco para el texto del AppBar
          elevation: 0, // Eliminar la sombra del AppBar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6552FE), // Color del botón "Inicia AQUÍ"
            foregroundColor: const Color(0xFFFFFFFF), // Color del texto del botón
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Bordes más redondeados
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins', // Aplicar Poppins al botón
              fontWeight: FontWeight.w600, // SemiBold para el texto del botón
              fontSize: 18,
            ),
          ),
        ),
        textTheme: const TextTheme(
          // Define la familia de fuente por defecto para todos los textos
          bodyLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          bodyMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          bodySmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          displayLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          displayMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          displaySmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          headlineLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          headlineMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          headlineSmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          labelLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          labelMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          labelSmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          titleLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          titleMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          titleSmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título "Invoice D"
            // Este Padding y su hijo RichText son completamente constantes.
            Padding( // Línea ~77 (Error const_with_non_const) - Ahora debería ser válido.
              padding: const EdgeInsets.only(top: 20.0, left: 20.0),
              child: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Invoice ',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF), // Blanco
                        fontSize: 64, // Poppins Bold 64
                        fontWeight: FontWeight.w700, // Bold
                      ),
                    ),
                    TextSpan(
                      text: 'D',
                      style: TextStyle(
                        color: Color(0xFF6552FE), // Morado
                        fontSize: 64, // Poppins Bold 64
                        fontWeight: FontWeight.w700, // Bold
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Imagen central - NO PUEDE ser const debido a MediaQuery.of(context)
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/imagenInicio.png', // RUTA DE TU IMAGEN
                  fit: BoxFit.contain,
                  height: MediaQuery.of(context).size.height * 0.4,
                ),
              ),
            ),

            // Contenedor para los textos de "Invoice Drive" y descripción
            // Quitamos 'const' del Padding exterior para resolver el error de la línea 124.
            // El Column interno y sus hijos sí pueden ser constantes, por eso le ponemos 'const'.
            Padding( // Línea ~124 (Error const_with_non_const) - QUITADO 'const'
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              child: Column( // Añadimos 'const' aquí al Column, ya que sus hijos son constantes.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto "Invoice Drive Gestiona Tu negocio"
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Invoice ',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF), // Blanco
                            fontSize: 32, // Poppins SemiBold 32
                            fontWeight: FontWeight.w600, // SemiBold
                          ),
                        ),
                        TextSpan(
                          text: 'Drive\n',
                          style: TextStyle(
                            color: Color(0xFF6552FE), // Morado
                            fontSize: 32, // Poppins SemiBold 32
                            fontWeight: FontWeight.w600, // SemiBold
                          ),
                        ),
                        TextSpan(
                          text: 'Gestiona Tu ',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF), // Blanco
                            fontSize: 32, // Poppins SemiBold 32
                            fontWeight: FontWeight.w600, // SemiBold
                          ),
                        ),
                        TextSpan(
                          text: 'negocio',
                          style: TextStyle(
                            color: Color(0xFF6552FE), // Morado
                            fontSize: 32, // Poppins SemiBold 32
                            fontWeight: FontWeight.w600, // SemiBold
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Lleva tu compañía y su organización al siguiente nivel o gestiona tus finanzas personales',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF), // Blanco
                      fontSize: 14, // Poppins Medium 14
                      fontWeight: FontWeight.w500, // Medium
                    ),
                  ),
                ],
              ),
            ),

            // Botón "Inicia AQUÍ"
            // El Padding y ElevatedButton NO pueden ser const debido a la función onPressed.
            Padding( // Línea ~163 (Error unnecessary_const) - QUITADO 'const' aquí.
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  // Acción del botón
                },
                child: const Text('Inicia Aqui'), // Línea ~165 (Error unnecessary_const) - Mantenemos 'const' aquí.
              ),
            ),
          ],
        ),
      ),
    );
  }
}
