// Representa un producto específico dentro de un carrito o venta
class ArticuloVenta {
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final bool origenConcept; // <-- NUEVO: ¿Viene de la Concept Store?

  ArticuloVenta({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    this.origenConcept = false, // <-- Retrocompatibilidad segura
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toMap() => {
    'productoId': productoId,
    'productoNombre': productoNombre,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
    'origenConcept': origenConcept,
  };

  factory ArticuloVenta.fromMap(Map<String, dynamic> map) {
    return ArticuloVenta(
      productoId: map['productoId'] ?? '',
      productoNombre: map['productoNombre'] ?? '',
      cantidad: map['cantidad'] ?? 0,
      precioUnitario: (map['precioUnitario'] ?? 0.0).toDouble(),
      origenConcept: map['origenConcept'] ?? false,
    );
  }
}

// Representa una venta en proceso (El Carrito o Apartado Activo)
class Carrito {
  final String telefonoCliente; 
  List<ArticuloVenta> articulos;
  double descuentoValor;
  bool descuentoEsPorcentaje;
  double cargoExtra; 
  String conceptoCargoExtra;
  bool pagoConTarjeta; // <-- NUEVO: Bandera para la comisión

  Carrito({
    required this.telefonoCliente,
    List<ArticuloVenta>? articulos,
    this.descuentoValor = 0.0,
    this.descuentoEsPorcentaje = false,
    this.cargoExtra = 0.0, 
    this.conceptoCargoExtra = 'Cargo Extra', 
    this.pagoConTarjeta = false, // Por defecto en efectivo
  }) : articulos = articulos ?? [];

  double get subtotal => articulos.fold(0.0, (sum, item) => sum + item.subtotal);
  
  double get descuentoMonto => descuentoEsPorcentaje 
      ? (subtotal * (descuentoValor / 100)) 
      : descuentoValor;

  // Lo que paga el cliente
  double get total {
    double resultado = subtotal - descuentoMonto + cargoExtra;
    return resultado > 0 ? resultado : 0.0;
  }

  // 🚀 NUEVO: Cálculo exacto de tu Excel (3.5% + 16% IVA)
  double get comisionTarjetaMonto {
    if (!pagoConTarjeta) return 0.0;
    final comisionBase = total * 0.035; // 3.5%
    final ivaComision = comisionBase * 0.16; // 16% sobre la comisión
    return comisionBase + ivaComision;
  }

  // Lo que realmente entra a la caja de WaveStore
  double get ingresoNeto => total - comisionTarjetaMonto;

  Map<String, dynamic> toMap() => {
    'telefonoCliente': telefonoCliente,
    'articulos': articulos.map((a) => a.toMap()).toList(),
    'descuentoValor': descuentoValor,
    'descuentoEsPorcentaje': descuentoEsPorcentaje,
    'cargoExtra': cargoExtra, 
    'conceptoCargoExtra': conceptoCargoExtra, 
    'pagoConTarjeta': pagoConTarjeta,
  };

  factory Carrito.fromMap(Map<String, dynamic> map) {
    var listaArticulos = map['articulos'] as List<dynamic>? ?? [];
    return Carrito(
      telefonoCliente: map['telefonoCliente'] ?? '',
      articulos: listaArticulos.map((e) => ArticuloVenta.fromMap(e as Map<String, dynamic>)).toList(),
      descuentoValor: (map['descuentoValor'] ?? 0.0).toDouble(),
      descuentoEsPorcentaje: map['descuentoEsPorcentaje'] ?? false,
      cargoExtra: (map['cargoExtra'] ?? 0.0).toDouble(), 
      conceptoCargoExtra: map['conceptoCargoExtra'] ?? 'Cargo Extra', 
      pagoConTarjeta: map['pagoConTarjeta'] ?? false,
    );
  }
}

// Representa una venta ya finalizada y cobrada
class Venta {
  final String id;
  final String telefonoCliente;
  final List<ArticuloVenta> articulos;
  final double descuentoAplicado; 
  final double cargoExtra; 
  final String conceptoCargoExtra; 
  final double totalFinal; // Lo que pagó el cliente
  final double comisionTarjeta; // <-- NUEVO: Guardamos cuánto nos quitaron
  final bool pagoConTarjeta; // <-- NUEVO: Para mostrar el iconito de tarjeta en el historial
  final DateTime fecha;

  Venta({
    required this.id,
    required this.telefonoCliente,
    required this.articulos,
    required this.descuentoAplicado, 
    this.cargoExtra = 0.0, 
    this.conceptoCargoExtra = 'Cargo Extra', 
    required this.totalFinal,
    this.comisionTarjeta = 0.0,
    this.pagoConTarjeta = false,
    required this.fecha,
  });

  // Utilidad real sumada a caja
  double get ingresoNeto => totalFinal - comisionTarjeta;

  Map<String, dynamic> toMap() => {
    'id': id,
    'telefonoCliente': telefonoCliente,
    'articulos': articulos.map((a) => a.toMap()).toList(),
    'descuentoAplicado': descuentoAplicado, 
    'cargoExtra': cargoExtra, 
    'conceptoCargoExtra': conceptoCargoExtra, 
    'totalFinal': totalFinal,
    'comisionTarjeta': comisionTarjeta,
    'pagoConTarjeta': pagoConTarjeta,
    'fecha': fecha.toIso8601String(),
  };

  factory Venta.fromMap(Map<String, dynamic> map) {
    var listaArticulos = map['articulos'] as List<dynamic>? ?? [];
    return Venta(
      id: map['id'] ?? '',
      telefonoCliente: map['telefonoCliente'] ?? 'Sin cliente',
      articulos: listaArticulos.map((e) => ArticuloVenta.fromMap(e as Map<String, dynamic>)).toList(),
      descuentoAplicado: (map['descuentoAplicado'] ?? 0.0).toDouble(), 
      cargoExtra: (map['cargoExtra'] ?? 0.0).toDouble(), 
      conceptoCargoExtra: map['conceptoCargoExtra'] ?? 'Cargo Extra', 
      totalFinal: (map['totalFinal'] ?? 0.0).toDouble(),
      comisionTarjeta: (map['comisionTarjeta'] ?? 0.0).toDouble(),
      pagoConTarjeta: map['pagoConTarjeta'] ?? false,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
    );
  }
}