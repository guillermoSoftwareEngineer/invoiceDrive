import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:convert'; // Import for JSON encoding/decoding
import 'invoice_entry_screen.dart'; // Importamos InvoiceEntryScreen
import 'visual_register_screen.dart';
import 'invoice.dart'; // Assuming you have an Invoice model

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Usuario';
  String? _userProfilePicPath;
  double _currentBudget = 0.0;
  List<Invoice> _invoices = []; // List to store invoices
  Invoice? _lastInvoice; // Store the last added invoice

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadInvoices(); // Load invoices when the screen initializes
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Usuario';
      _userProfilePicPath = prefs.getString('userProfilePicPath');
      _currentBudget = prefs.getDouble('currentBudget') ?? 0.0;
    });
  }

  Future<void> _loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? invoicesString = prefs.getString('invoices');
    if (invoicesString != null) {
      final List<dynamic> invoiceList = jsonDecode(invoicesString);
      setState(() {
        _invoices = invoiceList.map((json) => Invoice.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final String invoicesString = jsonEncode(_invoices.map((invoice) => invoice.toJson()).toList());
    await prefs.setString('invoices', invoicesString);
  }

  Future<void> _addInvoice(Invoice invoice) async {
    setState(() {
      _invoices.add(invoice);
      // Update budget based on invoice type
      if (invoice.type == 'Ingreso') {
        _currentBudget += invoice.amount;
      } else if (invoice.type == 'Egreso') {
        _currentBudget -= invoice.amount;
      }
      _lastInvoice = invoice; // Set the last added invoice
    });
    await _saveInvoices();
    await _saveCurrentBudget(_currentBudget); // Save updated budget
  }


  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    setState(() {
      _userName = name;
    });
  }

  Future<void> _saveCurrentBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('currentBudget', budget);
    setState(() {
      _currentBudget = budget;
    });
  }

  Future<void> _saveUserProfilePicPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('userProfilePicPath', path);
    } else {
      await prefs.remove('userProfilePicPath');
    }
    setState(() {
      _userProfilePicPath = path;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _saveUserProfilePicPath(image.path);
    }
  }

  Future<void> _showChangeNameDialog() async {
    TextEditingController nameController = TextEditingController(
      text: _userName,
    );
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: const Text(
            'Cambiar Nombre',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: const InputDecoration(
              hintText: 'Introduce tu nombre',
              hintStyle: TextStyle(
                color: Colors.white54,
                fontFamily: 'Poppins',
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6552FE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6552FE)),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Color(0xFF6552FE),
                  fontFamily: 'Poppins',
                ),
              ),
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

  Future<void> _showBudgetDialog() async {
    TextEditingController budgetController = TextEditingController(
      text: _currentBudget == 0.0 ? '' : _currentBudget.toStringAsFixed(2),
    );
    bool isFirstTimeEntry = _currentBudget == 0.0;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: Text(
            isFirstTimeEntry
                ? 'Establecer Presupuesto Inicial'
                : 'Modificar Presupuesto',
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          content: TextField(
            controller: budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: const InputDecoration(
              hintText: 'Introduce el monto',
              hintStyle: TextStyle(
                color: Colors.white54,
                fontFamily: 'Poppins',
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6552FE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6552FE)),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (!isFirstTimeEntry)
              TextButton(
                onPressed: () {
                  _showResetBudgetConfirmationDialog();
                },
                child: const Text(
                  'Reiniciar Presupuesto',
                  style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
                ),
              ),
            TextButton(
              child: Text(
                isFirstTimeEntry ? 'Establecer' : 'Guardar',
                style: const TextStyle(
                  color: Color(0xFF6552FE),
                  fontFamily: 'Poppins',
                ),
              ),
              onPressed: () {
                double? newBudget = double.tryParse(budgetController.text);
                if (newBudget != null) {
                  _saveCurrentBudget(newBudget);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, ingresa un número válido.'),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResetBudgetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: const Text(
            'Reiniciar Presupuesto',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          content: const Text(
            '¿Estás seguro de que quieres reiniciar tu presupuesto a \$0.00? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                _saveCurrentBudget(0.0);
                Navigator.of(context).pop();
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
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        toolbarHeight: 100,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        _userProfilePicPath != null &&
                                _userProfilePicPath!.isNotEmpty
                            ? FileImage(File(_userProfilePicPath!))
                                as ImageProvider<Object>?
                            : null,
                    child:
                        _userProfilePicPath == null ||
                                _userProfilePicPath!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _showChangeNameDialog,
                  child: Text.rich(
                    TextSpan(
                      text: 'Hola ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: _userName,
                          style: const TextStyle(
                            color: Color(0xFF9D50FF),
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
              // print('Ajustes');
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
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu presupuesto',
                    style: TextStyle(
                      color: Color.fromARGB(255, 30, 30, 30),
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _showBudgetDialog,
                        child: Text(
                          currencyFormatter.format(_currentBudget),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      _lastInvoice != null
                          ? Row(
                              children: [
                                Icon(
                                  _lastInvoice!.type == 'Ingreso'
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: _lastInvoice!.type == 'Ingreso'
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  currencyFormatter.format(_lastInvoice!.amount),
                                  style: TextStyle(
                                    color: _lastInvoice!.type == 'Ingreso'
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Última Factura',
                              style: TextStyle(
                                color: Color.fromARGB(255, 30, 30, 30),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón "Ingresa Factura"
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async { // Mark as async
                        // Navegar a InvoiceEntryScreen al presionar el botón
                        // Navigate to InvoiceEntryScreen and wait for a result
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InvoiceEntryScreen(),
                          ),
                        );
                        // If a result (Invoice object) is returned, add it
                        if (result != null && result is Invoice) {
                          _addInvoice(result);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6552FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Ingresa Factura',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Botón "Registro Visual"
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VisualRegisterScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Registro Visual',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Facturas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Acción para "Ver Todas" las facturas
                    // print('Ver Todas las Facturas');
                  },
                  child: const Text(
                    'Ver Todas',
                    style: TextStyle(
                      color: Color(0xFF6552FE),
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Dynamically build invoice list items
            _invoices.isEmpty
                ? const Center(
                    child: Text(
                      'No hay facturas registradas.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = _invoices[index];
                      return _buildInvoiceListItem(
                        context,
                        invoice.title, // Use 'title' instead of 'description'
                        invoice.type,
                        currencyFormatter.format(invoice.amount),
                        invoice.status,
                      );
                    },
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF070707),
        selectedItemColor: const Color(0xFF6552FE),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          // print('Tapped on index: $index');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            label: 'Actividad',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  // Widget helper para construir los ítems de factura
  Widget _buildInvoiceListItem(
    BuildContext context,
    String title,
    String subtitle,
    String amount,
    String status,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: subtitle == 'Ingreso' ? Colors.green : Colors.red, // Change color based on type
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/icon.png', // Ruta a tu imagen
                width: 25,
                height: 26,
                fit: BoxFit.contain,
                color: Colors.white, // Make the icon white to stand out on colored background
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 30,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: CustomPaint(painter: _LineChartPainter()),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = Colors.greenAccent
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.25, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.8);
    path.lineTo(size.width * 0.75, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
