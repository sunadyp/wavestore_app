// Representa un producto específico dentro de un carrito o venta
class ArticuloVenta {
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;

  ArticuloVenta({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toMap() => {
    'productoId': productoId,
    'productoNombre': productoNombre,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
  };

  factory ArticuloVenta.fromMap(Map<String, dynamic> map) {
    return ArticuloVenta(
      productoId: map['productoId'] ?? '',
      productoNombre: map['productoNombre'] ?? '',
      cantidad: map['cantidad'] ?? 0,
      precioUnitario: (map['precioUnitario'] ?? 0.0).toDouble(),
    );
  }
}

// Representa una venta en proceso (El Carrito)
class Carrito {
  final String telefonoCliente;
  List<ArticuloVenta> articulos;
  double descuentoValor;
  bool descuentoEsPorcentaje;

  Carrito({
    required this.telefonoCliente,
    List<ArticuloVenta>? articulos,
    this.descuentoValor = 0.0,
    this.descuentoEsPorcentaje = false,
  }) : articulos = articulos ?? [];

  double get subtotal => articulos.fold(0.0, (sum, item) => sum + item.subtotal);
  
  // Calcula el monto dinámicamente
  double get descuentoMonto => descuentoEsPorcentaje 
      ? (subtotal * (descuentoValor / 100)) 
      : descuentoValor;

  double get total => subtotal - descuentoMonto > 0 ? subtotal - descuentoMonto : 0.0;

  // NUEVO: Serialización a Map
  Map<String, dynamic> toMap() => {
    'telefonoCliente': telefonoCliente,
    'articulos': articulos.map((a) => a.toMap()).toList(),
    'descuentoValor': descuentoValor,
    'descuentoEsPorcentaje': descuentoEsPorcentaje,
  };

  // NUEVO: Deserialización desde Map
  factory Carrito.fromMap(Map<String, dynamic> map) {
    var listaArticulos = map['articulos'] as List<dynamic>? ?? [];
    return Carrito(
      telefonoCliente: map['telefonoCliente'] ?? '',
      articulos: listaArticulos.map((e) => ArticuloVenta.fromMap(e as Map<String, dynamic>)).toList(),
      descuentoValor: (map['descuentoValor'] ?? 0.0).toDouble(),
      descuentoEsPorcentaje: map['descuentoEsPorcentaje'] ?? false,
    );
  }
}

// Representa una venta ya finalizada y cobrada
class Venta {
  final String id;
  final String telefonoCliente;
  final List<ArticuloVenta> articulos;
  final double descuentoAplicado;
  final double totalFinal;
  final DateTime fecha;

  Venta({
    required this.id,
    required this.telefonoCliente,
    required this.articulos,
    required this.descuentoAplicado,
    required this.totalFinal,
    required this.fecha,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'telefonoCliente': telefonoCliente,
    'articulos': articulos.map((a) => a.toMap()).toList(),
    'descuentoAplicado': descuentoAplicado,
    'totalFinal': totalFinal,
    'fecha': fecha.toIso8601String(),
  };

  factory Venta.fromMap(Map<String, dynamic> map) {
    var listaArticulos = map['articulos'] as List<dynamic>? ?? [];
    return Venta(
      id: map['id'] ?? '',
      telefonoCliente: map['telefonoCliente'] ?? 'Sin teléfono',
      articulos: listaArticulos.map((e) => ArticuloVenta.fromMap(e as Map<String, dynamic>)).toList(),
      descuentoAplicado: (map['descuentoAplicado'] ?? 0.0).toDouble(),
      totalFinal: (map['totalFinal'] ?? 0.0).toDouble(),
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
    );
  }
}