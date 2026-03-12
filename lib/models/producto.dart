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

  // Convierte el objeto a un mapa (diccionario) para guardarlo como JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'costo': costo,
      'precioVenta': precioVenta,
      'cantidad': cantidad,
    };
  }

  // Crea un objeto Producto leyendo un mapa (diccionario) recuperado del JSON
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      costo: map['costo'],
      precioVenta: map['precioVenta'],
      cantidad: map['cantidad'],
    );
  }
}