import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoice_d/screens/widgets/loading_screen.dart';
import 'package:invoice_d/screens/widgets/preload_home_screen.dart';

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

  Future<void> iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    final BuildContext ctx = context;

    Navigator.of(ctx).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LoadingScreen(mensaje: 'Iniciando sesión...'),
      ),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(ctx).pop();

      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario != null) {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const PreloadHomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(ctx).pop();

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

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
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
                validator: (v) =>
                    v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 20),
              _cargando
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: iniciarSesion,
                      icon: const Icon(Icons.login),
                      label: const Text('Iniciar sesión'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
