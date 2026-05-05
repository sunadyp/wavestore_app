class Movimiento {
  final String id;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final bool esInversion;

  Movimiento({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.esInversion,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'descripcion': descripcion,
    'monto': monto,
    'fecha': fecha.toIso8601String(),
    'esInversion': esInversion,
  };

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'] ?? '',
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] ?? 0.0).toDouble(),
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
      esInversion: map['esInversion'] ?? false,
    );
  }
}