class Actividad {
  final String id;
  final String descripcion;
  final DateTime fecha;

  Actividad({
    required this.id,
    required this.descripcion,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Actividad.fromMap(Map<String, dynamic> map) {
    return Actividad(
      id: map['id'] ?? '',
      descripcion: map['descripcion'] ?? '',
      fecha: DateTime.parse(map['fecha']),
    );
  }
}