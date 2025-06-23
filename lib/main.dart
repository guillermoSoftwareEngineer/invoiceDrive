import 'package:flutter/material.dart';
import 'package:invoice_d/screens/home/home_screen.dart'; // Importa la pantalla principal
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


import 'services/auth_service.dart';
import 'screens/register/registro_manual_screen.dart';
import 'services/auth_service.dart';

import 'screens/home/home_screen.dart';
import 'screens/auth/login_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO', null);
  await Firebase.initializeApp();
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
        scaffoldBackgroundColor: const Color(
          0xFF070707,
        ), // Fondo muy oscuro, casi negro
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF070707),
          foregroundColor: Color(0xFFFFFFFF), // Blanco para el texto del AppBar
          elevation: 0, // Eliminar la sombra del AppBar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF6552FE,
            ), // Color del botón "Inicia AQUÍ"
            foregroundColor: const Color(
              0xFFFFFFFF,
            ), // Color del texto del botón
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
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          bodySmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFFFFFFFF)),
          displayLarge: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          displayMedium: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          displaySmall: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          labelMedium: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          labelSmall: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          titleLarge: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          titleMedium: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
          titleSmall: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFFFFFFF),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CO'), Locale('en', 'US')],
      home:
          FirebaseAuth.instance.currentUser != null
              ? const HomeScreen()
              : const WelcomeScreen(),
    );
  }
}

class WelcomeScreen  extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título "Invoice D"
            Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 20.0),
              child: RichText(
                // Aquí quitamos el `const` de TextSpan porque sus hijos `TextStyle` no pueden serlo.
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
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 20.0,
              ),
              // Aquí quitamos el `const` de Column porque sus hijos `RichText` y `Text` no pueden serlo.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto "Invoice Drive Gestiona Tu negocio"
                  RichText(
                    // Aquí quitamos el `const` de TextSpan porque sus hijos `TextStyle` no pueden serlo.
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
                  const SizedBox(height: 10), // Aquí sí es válido `const`
                  const Text(
                    // Aquí sí es válido `const`
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔹 Inicio de sesión
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginEmailScreen(),
                        ),
                      );
                    },
                    child: const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 10),
                  // OutlinedButton(
                  //   onPressed: () async {
                  //     final user = await AuthService().signInWithGoogle();
                  //     if (user != null) {
                  //       Navigator.pushReplacement(
                  //         context,
                  //         MaterialPageRoute(builder: (_) => const HomeScreen()),
                  //       );
                  //     } else {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(
                  //           content: Text(
                  //             'No se pudo completar el inicio con Google',
                  //           ),
                  //         ),
                  //       );
                  //     }
                  //   },
                  //   child: const Text('Iniciar sesión con Google'),
                  // ),

                  const SizedBox(height: 30),

                  // 🔸 Registro
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistroManualScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                    child: const Text('Registrarse'),
                  ),
                  const SizedBox(height: 10),
                  // OutlinedButton(
                  //   onPressed: () async {
                  //     final user = await AuthService().signInWithGoogle();
                  //     if (user != null) {
                  //       Navigator.pushReplacement(
                  //         context,
                  //         MaterialPageRoute(builder: (_) => const HomeScreen()),
                  //       );
                  //     } else {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(
                  //           content: Text(
                  //             'No se pudo completar el inicio con Google',
                  //           ),
                  //         ),
                  //       );
                  //     }
                  //   },
                  //   child: const Text('Registrarse con Google'),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
