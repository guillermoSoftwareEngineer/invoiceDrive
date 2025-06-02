// lib/models/invoice.dart
class Invoice {
  final String id;
  final String title; // "Impresora", "Impuesto", etc.
  final double amount;
  final DateTime date;
  final String type; // "Ingreso" o "Egreso"
  final String status; // "Activo", "Obligacion", etc. (aunque lo determinaremos)

  Invoice({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
  });

  // Convertir un objeto Invoice a un Map (para guardar en SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'status': status,
    };
  }

  // Crear un objeto Invoice desde un Map (cargado de SharedPreferences)
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      status: json['status'],
    );
  }
}