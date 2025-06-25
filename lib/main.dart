import 'package:flutter/material.dart';
import 'package:invoice_d/screens/auth/login_email_screen.dart';
import 'package:invoice_d/screens/home/home_screen.dart';
import 'package:invoice_d/screens/register/registro_manual_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invoice_d/screens/widgets/preload_home_screen.dart';

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
        primaryColor: const Color(0xFF6552FE),
        scaffoldBackgroundColor: const Color(
          0xFF070707,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF070707),
          foregroundColor: Color(0xFFFFFFFF),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF6552FE,
            ),
            foregroundColor: const Color(
              0xFFFFFFFF,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        textTheme: const TextTheme(
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('en', 'US'),
      ],
      home: FirebaseAuth.instance.currentUser != null
          ? const PreloadHomeScreen()
          : const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 20.0),
              child: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Invoice ',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'D',
                      style: TextStyle(
                        color: Color(0xFF6552FE),
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/imagenInicio.png',
                  fit: BoxFit.contain,
                  height: MediaQuery.of(context).size.height * 0.4,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Invoice ',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: 'Drive\n',
                          style: TextStyle(
                            color: Color(0xFF6552FE),
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: 'Gestiona Tu ',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: 'negocio',
                          style: TextStyle(
                            color: Color(0xFF6552FE),
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  const Text(
                    'Lleva tu compañía y su organización al siguiente nivel o gestiona tus finanzas personales',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginEmailScreen()),
                      );
                    },
                    child: const Text('Iniciar sesión'),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegistroManualScreen()),
                      );
                    },
                    child: const Text('Registrarse'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
