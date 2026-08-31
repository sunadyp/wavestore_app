class Movimiento {
  final String id;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final bool esInversion;
  
  final String? productoId;
  final int? cantidadArticulos;
  final bool afectoCaja; // <-- NUEVO: Para saber si alteró el saldo

  Movimiento({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.esInversion,
    this.productoId,
    this.cantidadArticulos,
    this.afectoCaja = true, // Por defecto asumimos que sí
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'descripcion': descripcion,
    'monto': monto,
    'fecha': fecha.toIso8601String(),
    'esInversion': esInversion,
    'productoId': productoId,
    'cantidadArticulos': cantidadArticulos,
    'afectoCaja': afectoCaja,
  };

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'] ?? '',
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] ?? 0.0).toDouble(),
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
      esInversion: map['esInversion'] ?? false,
      productoId: map['productoId'],
      cantidadArticulos: map['cantidadArticulos']?.toInt(),
      afectoCaja: map['afectoCaja'] ?? true, // Leemos el nuevo campo
    );
  }
}