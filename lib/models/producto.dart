class Producto {
  final String id;
  final String nombre;
  final double costo;
  final double precioVenta;
  final int cantidad;

  Producto({
    required this.id,
    required this.nombre,
    required this.costo,
    required this.precioVenta,
    required this.cantidad,
  });

  // 1. Método para copiar el objeto (útil para actualizar stock)
  Producto copyWith({
    String? id,
    String? nombre,
    double? costo,
    double? precioVenta,
    int? cantidad,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      costo: costo ?? this.costo,
      precioVenta: precioVenta ?? this.precioVenta,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  // Convierte el objeto a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'costo': costo,
      'precioVenta': precioVenta,
      'cantidad': cantidad,
    };
  }

  // 2. Crea un objeto con mayor seguridad de tipos
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      costo: (map['costo'] ?? 0.0).toDouble(),
      precioVenta: (map['precioVenta'] ?? 0.0).toDouble(),
      cantidad: map['cantidad'] ?? 0,
    );
  }
} 