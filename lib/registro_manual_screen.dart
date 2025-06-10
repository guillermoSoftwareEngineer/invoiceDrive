import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroManualScreen extends StatefulWidget {
  const RegistroManualScreen({super.key});

  @override
  State<RegistroManualScreen> createState() => _RegistroManualScreenState();
}

class _RegistroManualScreenState extends State<RegistroManualScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombresController = TextEditingController();
  final apellidosController = TextEditingController();
  final correoController = TextEditingController();
  final telefonoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();

  bool _cargando = false;

  Future<void> registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      // Intentar crear el usuario
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passwordController.text,
      );

      // Guardar datos en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'uid': cred.user!.uid,
            'nombre': nombresController.text.trim(),
            'apellidos': apellidosController.text.trim(),
            'correo': correoController.text.trim(),
            'telefono': telefonoController.text.trim(),
            'fechaRegistro': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado con éxito')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Ocurrió un error inesperado';

      switch (e.code) {
        case 'email-already-in-use':
          mensaje = 'Este correo ya está registrado';
          break;
        case 'invalid-email':
          mensaje = 'El correo ingresado no es válido';
          break;
        case 'weak-password':
          mensaje = 'La contraseña es demasiado débil (mínimo 6 caracteres)';
          break;
        case 'operation-not-allowed':
          mensaje = 'El método de registro por correo está deshabilitado';
          break;
        default:
          mensaje = 'Error: ${e.message}';
          break;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: ${e.toString()}')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Manual')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombresController,
                decoration: const InputDecoration(labelText: 'Nombres *'),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Campo obligatorio'
                            : null,
              ),
              TextFormField(
                controller: apellidosController,
                decoration: const InputDecoration(labelText: 'Apellidos *'),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Campo obligatorio'
                            : null,
              ),
              TextFormField(
                controller: correoController,
                decoration: const InputDecoration(labelText: 'Correo *'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                  if (!emailRegex.hasMatch(v.trim())) return 'Correo inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña *'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obligatorio';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              TextFormField(
                controller: confirmarPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña *',
                ),
                obscureText: true,
                validator: (v) {
                  if (v != passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _cargando
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    onPressed: registrarUsuario,
                    icon: const Icon(Icons.check),
                    label: const Text('Registrarse'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
