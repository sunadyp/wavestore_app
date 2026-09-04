class Producto {
  final String id;
  final String nombre;
  final String categoria; 
  final double costo;
  final double precioVenta;
  final int cantidad; // <-- Stock Principal
  final int cantidadConcept; // <-- NUEVO: Stock en la Concept Store

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria, 
    required this.costo,
    required this.precioVenta,
    required this.cantidad,
    this.cantidadConcept = 0, // <-- Retrocompatibilidad segura
  });

  double get utilidad => precioVenta - costo;

  Producto copyWith({
    String? id,
    String? nombre,
    String? categoria, 
    double? costo,
    double? precioVenta,
    int? cantidad,
    int? cantidadConcept, // <-- Agregado
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria, 
      costo: costo ?? this.costo,
      precioVenta: precioVenta ?? this.precioVenta,
      cantidad: cantidad ?? this.cantidad,
      cantidadConcept: cantidadConcept ?? this.cantidadConcept, // <-- Agregado
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria, 
      'costo': costo,
      'precioVenta': precioVenta,
      'cantidad': cantidad,
      'cantidadConcept': cantidadConcept, // <-- Agregado
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      categoria: map['categoria'] ?? 'General', 
      costo: (map['costo'] ?? 0.0).toDouble(),
      precioVenta: (map['precioVenta'] ?? 0.0).toDouble(),
      cantidad: map['cantidad'] ?? 0,
      cantidadConcept: map['cantidadConcept'] ?? 0, // <-- Retrocompatibilidad segura
    );
  }
}