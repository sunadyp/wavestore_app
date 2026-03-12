class Venta {
  final String id;
  final String productoNombre;
  final int cantidad;
  final double total;
  final DateTime fecha;

  Venta({
    required this.id, 
    required this.productoNombre, 
    required this.cantidad, 
    required this.total, 
    required this.fecha
  });

  // Convierte el objeto a un mapa para guardarlo
  Map<String, dynamic> toMap() => {
        'id': id,
        'productoNombre': productoNombre,
        'cantidad': cantidad,
        'total': total,
        'fecha': fecha.toIso8601String(),
      };

  // Crea el objeto desde un mapa con seguridad de tipos
  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] ?? '',
      productoNombre: map['productoNombre'] ?? 'Producto eliminado',
      cantidad: map['cantidad'] ?? 0,
      total: (map['total'] ?? 0.0).toDouble(),
      fecha: map['fecha'] != null 
          ? DateTime.parse(map['fecha']) 
          : DateTime.now(),
    );
  }
}