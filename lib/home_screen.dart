import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // ¡NUEVO! Importa image_picker
import 'dart:io'; // ¡NUEVO! Necesario para el tipo File

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Usuario'; // Nombre por defecto
  String? _userProfilePicPath; // ¡MODIFICADO! Ahora es nullable para la ruta de la foto

  @override
  void initState() {
    super.initState();
    _loadUserData(); // ¡MODIFICADO! Cambiado para cargar tanto el nombre como la foto
  }

  // ¡MODIFICADO! Función para cargar ambos datos
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Usuario'; // Carga el nombre guardado
      _userProfilePicPath = prefs.getString('userProfilePicPath'); // Carga la ruta de la foto
    });
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    setState(() {
      _userName = name;
    });
  }

  // ¡NUEVO! Función para guardar la ruta de la imagen
  Future<void> _saveUserProfilePicPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('userProfilePicPath', path);
    } else {
      await prefs.remove('userProfilePicPath'); // Si es null, elimina la entrada
    }
    setState(() {
      _userProfilePicPath = path;
    });
  }

  // ¡NUEVO! Función para seleccionar imagen
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Permite al usuario elegir una imagen de la galería. Puedes cambiar a ImageSource.camera para tomar una foto.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _saveUserProfilePicPath(image.path); // Guarda la ruta de la imagen seleccionada
    }
  }

  Future<void> _showChangeNameDialog() async {
    TextEditingController nameController = TextEditingController(text: _userName);
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // El usuario puede cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C), // Fondo oscuro para el diálogo
          title: const Text('Cambiar Nombre', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: const InputDecoration(
              hintText: 'Introduce tu nombre',
              hintStyle: TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6552FE)), // Borde morado
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6552FE)), // Borde morado al enfocar
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar', style: TextStyle(color: Color(0xFF6552FE), fontFamily: 'Poppins')),
              onPressed: () {
                _saveUserName(nameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        // ¡MODIFICADO! Aseguramos una altura suficiente para la foto y el texto
        toolbarHeight: 100, // Ajusta esta altura si el contenido aún se recorta
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinea el contenido a la izquierda
              children: [
                // ¡MODIFICADO! CircleAvatar con GestureDetector para seleccionar imagen
                GestureDetector(
                  onTap: _pickImage, // Al tocar el círculo, se abre el selector de imagen
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey, // Color de placeholder
                    // Si hay una ruta de imagen y no está vacía, usa FileImage
                    backgroundImage: _userProfilePicPath != null && _userProfilePicPath!.isNotEmpty
                        ? FileImage(File(_userProfilePicPath!)) as ImageProvider<Object>?
                        : null, // Si no, no hay imagen de fondo
                    // Muestra el icono de persona si no hay imagen de perfil
                    child: _userProfilePicPath == null || _userProfilePicPath!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 5), // Añadimos un pequeño espacio entre la foto y el texto
                // Saludo "Hola [Nombre del usuario]"
                GestureDetector(
                  onTap: _showChangeNameDialog,
                  child: Text.rich( // Usamos Text.rich para diferentes estilos
                    TextSpan(
                      text: 'Hola ',
                      style: const TextStyle(
                        color: Colors.white, // "Hola" en blanco
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: _userName,
                          style: const TextStyle(
                            color: Color(0xFF9D50FF), // Nombre de usuario en 9D50FF
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Acción para ajustes
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Presupuesto
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFCD728B),
                    Color(0xFFFDDDAA),
                    Color(0xFF9ECBEA),
                  ],
                  begin: Alignment.topRight, // Inicia desde abajo a la derecha
                  end: Alignment.bottomLeft, // Termina arriba a la izquierda
                ),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu presupuesto',
                    style: TextStyle(
                      color: Color.fromARGB(255, 30, 30, 30), // Color de texto oscuro para contraste
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500, // Añadido FontWeight para que sea más legible
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$87,450.12',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0), // Color de texto oscuro para contraste
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, color: Color.fromARGB(255, 30, 30, 30), size: 16), // Color de icono oscuro
                          Text(
                            'Última Factura',
                            style: TextStyle(
                              color: Color.fromARGB(255, 30, 30, 30), // Color de texto oscuro
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}