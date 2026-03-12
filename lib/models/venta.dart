class Venta {
  final String id;
  final String productoNombre;
  final int cantidad;
  final double total;
  final DateTime fecha;

  Venta({required this.id, required this.productoNombre, required this.cantidad, required this.total, required this.fecha});

  Map<String, dynamic> toMap() => {
    'id': id, 'productoNombre': productoNombre, 'cantidad': cantidad, 'total': total, 'fecha': fecha.toIso8601String(),
  };

  factory Venta.fromMap(Map<String, dynamic> map) => Venta(
    id: map['id'], productoNombre: map['productoNombre'], cantidad: map['cantidad'],
    total: map['total'], fecha: DateTime.parse(map['fecha']),
  );
}