import 'package:flutter/material.dart';
import 'package:invoice_d/home_screen.dart';
// import 'package:invoice_d/services/auth_service.dart'; // Comentado: Firebase Auth
// import 'package:firebase_auth/firebase_auth.dart'; // Comentado: Firebase Auth

class LoginEmailScreen extends StatefulWidget {
  const LoginEmailScreen({super.key});

  @override
  State<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  bool _cargando = false;

  // final AuthService _authService = AuthService(); // Comentado: Firebase Auth

  Future<void> iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    // Comentado: Firebase Auth
    /*
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passwordController.text,
      );

      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Ocurrió un error al iniciar sesión';
      switch (e.code) {
        case 'user-not-found':
          mensaje = 'No existe una cuenta con ese correo';
          break;
        case 'wrong-password':
          mensaje = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          mensaje = 'Correo electrónico inválido';
          break;
        case 'user-disabled':
          mensaje = 'Este usuario ha sido deshabilitado';
          break;
        default:
          mensaje = 'Error: ${e.message}';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      if (!mounted) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: ${e.toString()}')),
      );
    } finally {
      setState(() => _cargando = false);
    }
    */

    // Navegación temporal para permitir el acceso sin autenticación
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );

    setState(() => _cargando = false); // Asegurarse de que el indicador de carga se desactive
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                  if (!emailRegex.hasMatch(v.trim())) return 'Correo inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator:
                    (v) =>
                        v == null || v.length < 6
                            ? 'Mínimo 6 caracteres'
                            : null,
              ),
              const SizedBox(height: 20),
              _cargando
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    onPressed: iniciarSesion,
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar sesión'),
                  ),
              const SizedBox(height: 10), // Add spacing
              // Comentado: Google Sign-In Button
              /*
              ElevatedButton.icon( // Google Sign-In Button
                onPressed: () async {
                  setState(() => _cargando = true);
                  try {
                    final user = await _authService.signInWithGoogle(); // Call on the instance
                    if (user != null) {
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    } else {
                       if (!mounted) return;
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                           content: Text(
                             'No se pudo completar el inicio con Google',
                           ),
                         ),
                       );
                    }
                  } catch (e) {
                    if (!mounted) return; // Add mounted check
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al iniciar con Google: ${e.toString()}')),
                    );
                  } finally {
                    setState(() => _cargando = false);
                  }
                },
                icon: const Icon(Icons.account_circle), // Use a relevant icon
                label: const Text('Iniciar sesión con Google'),
              ),
              */
            ],
          ),
        ),
      ),
    );
  }
}
