// Representa un producto específico dentro de un carrito o venta
class ArticuloVenta {
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final bool origenConcept;

  ArticuloVenta({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    this.origenConcept = false,
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

// Representa una venta en proceso (El Carrito o Apartado Activo / Agenda)
class Carrito {
  final String telefonoCliente; 
  List<ArticuloVenta> articulos;
  double descuentoValor;
  bool descuentoEsPorcentaje;
  double cargoExtra; 
  String conceptoCargoExtra;
  bool pagoConTarjeta; 
  
  // 🚀 NUEVOS CAMPOS PARA LA AGENDA DE ENTREGAS
  DateTime? fechaEntrega;
  String? lugarEntrega;
  double anticipo;

  Carrito({
    required this.telefonoCliente,
    List<ArticuloVenta>? articulos,
    this.descuentoValor = 0.0,
    this.descuentoEsPorcentaje = false,
    this.cargoExtra = 0.0, 
    this.conceptoCargoExtra = 'Cargo Extra', 
    this.pagoConTarjeta = false,
    this.fechaEntrega,
    this.lugarEntrega,
    this.anticipo = 0.0,
  }) : articulos = articulos ?? [];

  double get subtotal => articulos.fold(0.0, (sum, item) => sum + item.subtotal);
  
  double get descuentoMonto => descuentoEsPorcentaje 
      ? (subtotal * (descuentoValor / 100)) 
      : descuentoValor;

  // Lo que debe pagar el cliente en total
  double get total {
    double resultado = subtotal - descuentoMonto + cargoExtra;
    return resultado > 0 ? resultado : 0.0;
  }

  // 🚀 NUEVO: Lo que le falta por pagar
  double get saldoPendiente {
    double saldo = total - anticipo;
    return saldo > 0 ? saldo : 0.0;
  }

  // 🚀 NUEVO: Estado del pago para la interfaz gráfica
  String get estadoPago {
    if (anticipo <= 0) return 'Sin pago';
    if (anticipo >= total) return 'Liquidado';
    return 'Abono parcial';
  }

  double get comisionTarjetaMonto {
    if (!pagoConTarjeta) return 0.0;
    final comisionBase = total * 0.035; 
    final ivaComision = comisionBase * 0.16; 
    return comisionBase + ivaComision;
  }

  double get ingresoNeto => total - comisionTarjetaMonto;

  Map<String, dynamic> toMap() => {
    'telefonoCliente': telefonoCliente,
    'articulos': articulos.map((a) => a.toMap()).toList(),
    'descuentoValor': descuentoValor,
    'descuentoEsPorcentaje': descuentoEsPorcentaje,
    'cargoExtra': cargoExtra, 
    'conceptoCargoExtra': conceptoCargoExtra, 
    'pagoConTarjeta': pagoConTarjeta,
    'fechaEntrega': fechaEntrega?.toIso8601String(), // <-- GUARDAR FECHA
    'lugarEntrega': lugarEntrega,                    // <-- GUARDAR LUGAR
    'anticipo': anticipo,                            // <-- GUARDAR ANTICIPO
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
      fechaEntrega: map['fechaEntrega'] != null ? DateTime.parse(map['fechaEntrega']) : null, // <-- RECUPERAR FECHA
      lugarEntrega: map['lugarEntrega'],                                                      // <-- RECUPERAR LUGAR
      anticipo: (map['anticipo'] ?? 0.0).toDouble(),                                          // <-- RECUPERAR ANTICIPO
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
  final double totalFinal; 
  final double comisionTarjeta; 
  final bool pagoConTarjeta; 
  final DateTime fecha;
  final String? lugarEntrega; // 🚀 NUEVO: Útil para historial y reportes

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
    this.lugarEntrega, // <-- NUEVO
  });

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
    'lugarEntrega': lugarEntrega, // <-- GUARDAR
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
      lugarEntrega: map['lugarEntrega'], // <-- RECUPERAR
    );
  }
}