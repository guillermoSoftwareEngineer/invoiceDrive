import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final DateTime fechaCreacion;
  final DateTime? fechaFactura;
  final double valor;
  final String descripcion;

  Invoice({
    required this.id,
    required this.fechaCreacion,
    this.fechaFactura,
    required this.valor,
    required this.descripcion,
  });

  // Para guardar como JSON o enviar a Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaFactura': fechaFactura?.toIso8601String(),
      'valor': valor,
      'descripcion': descripcion,
    };
  }

  // Desde Firestore (asumiendo que se usa Timestamp)
  factory Invoice.fromFirestore(String id, Map<String, dynamic> json) {
    return Invoice(
      id: id,
      fechaCreacion: (json['fechaCreacion'] as Timestamp).toDate(),
      fechaFactura:
          json['fechaFactura'] != null
              ? (json['fechaFactura'] as Timestamp).toDate()
              : null,
      valor: double.tryParse(json['valor'].toString()) ?? 0.0,
      descripcion: json['descripcion'] ?? '',
    );
  }

  // Desde JSON (para SharedPreferences si lo usas también)
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaFactura:
          json['fechaFactura'] != null
              ? DateTime.parse(json['fechaFactura'])
              : null,
      valor: json['valor'],
      descripcion: json['descripcion'],
    );
  }
}
