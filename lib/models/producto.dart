class Producto {
  final String id;
  final String nombre;
  final String categoria; // <-- Nuevo campo
  final double costo;
  final double precioVenta;
  final int cantidad;

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria, // <-- Requerido en el constructor
    required this.costo,
    required this.precioVenta,
    required this.cantidad,
  });

  // <-- Nuevo: Cálculo automático de la utilidad
  double get utilidad => precioVenta - costo;

  // 1. Método para copiar el objeto (útil para actualizar stock)
  Producto copyWith({
    String? id,
    String? nombre,
    String? categoria, // <-- Agregado
    double? costo,
    double? precioVenta,
    int? cantidad,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria, // <-- Agregado
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
      'categoria': categoria, // <-- Agregado
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
      categoria: map['categoria'] ?? 'General', // <-- Agregado con valor por defecto
      costo: (map['costo'] ?? 0.0).toDouble(),
      precioVenta: (map['precioVenta'] ?? 0.0).toDouble(),
      cantidad: map['cantidad'] ?? 0,
    );
  }
}