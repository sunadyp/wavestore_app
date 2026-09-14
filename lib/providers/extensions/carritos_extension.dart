part of '../inventario_provider.dart';

extension CarritosExtension on InventarioProvider {

  String _normalizarIdentificador(String texto) {
    String t = texto.trim().toLowerCase();
    t = t.replaceAll(RegExp(r'[áäâà]'), 'a');
    t = t.replaceAll(RegExp(r'[éëêè]'), 'e');
    t = t.replaceAll(RegExp(r'[íïîì]'), 'i');
    t = t.replaceAll(RegExp(r'[óöôò]'), 'o');
    t = t.replaceAll(RegExp(r'[úüûù]'), 'u');
    return t;
  }

  // 🚀 NUEVO: Función para encontrar tickets viejos (fantasmas)
  String _obtenerKeyReal(String identificador) {
    final idNormalizado = _normalizarIdentificador(identificador);
    if (_carritosActivos.containsKey(idNormalizado)) return idNormalizado;
    if (_carritosActivos.containsKey(identificador)) return identificador; // ¡Atrapa al fantasma!
    return idNormalizado;
  }

  void actualizarLogistica(String identificador, {DateTime? fechaEntrega, String? lugarEntrega}) {
    final keyCart = _obtenerKeyReal(identificador);
    if (_carritosActivos.containsKey(keyCart)) {
      final carrito = _carritosActivos[keyCart]!;
      
      if (fechaEntrega != null) {
        carrito.fechaEntrega = fechaEntrega;
        
        NotificacionesService.cancelarRecordatorio("${keyCart}_dia2".hashCode);
        NotificacionesService.cancelarRecordatorio("${keyCart}_dia3".hashCode);

        final lugarText = lugarEntrega != null && lugarEntrega.isNotEmpty ? ' en $lugarEntrega' : '';
        
        NotificacionesService.programarRecordatorio(
          id: "${keyCart}_pre".hashCode, 
          titulo: '📦 Próxima Entrega',
          cuerpo: 'En 1 hora tienes una entrega con ${carrito.telefonoCliente}$lugarText.',
          fechaProgramada: fechaEntrega.subtract(const Duration(hours: 1)),
        );

        NotificacionesService.programarRecordatorio(
          id: "${keyCart}_post".hashCode, 
          titulo: '✅ ¿Se concretó la entrega?',
          cuerpo: 'Tu cita con ${carrito.telefonoCliente} fue hace 20 minutos. No olvides cobrar el ticket o reagendar.',
          fechaProgramada: fechaEntrega.add(const Duration(minutes: 20)),
        );
      }
      
      if (lugarEntrega != null) carrito.lugarEntrega = lugarEntrega;

      registrarActividad('Actualizó la entrega de "${carrito.telefonoCliente}" para el ${carrito.fechaEntrega?.day}/${carrito.fechaEntrega?.month} en ${carrito.lugarEntrega ?? "lugar por definir"}');

      notifyListeners();
      final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
      _storage.guardarCarritosActivos(mapAGuardar);
    }
  }

  void registrarAnticipo(String identificador, double monto) {
    final keyCart = _obtenerKeyReal(identificador);
    if (_carritosActivos.containsKey(keyCart) && monto > 0) {
      final carrito = _carritosActivos[keyCart]!;
      
      carrito.anticipo += monto;
      _dineroEnCaja += monto;

      registrarActividad('Recibió un anticipo de \$${monto.toStringAsFixed(2)} del apartado de "${carrito.telefonoCliente}"');

      notifyListeners();
      _storage.guardarCaja(_dineroEnCaja);
      final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
      _storage.guardarCarritosActivos(mapAGuardar);
    }
  }

  String? agregarAlCarrito(String telefono, Producto producto, int cantidad, {bool origenConcept = false}) {
    final idNormalizado = _normalizarIdentificador(telefono);
    
    final indexProducto = _productos.indexWhere((p) => p.id == producto.id);
    if (indexProducto == -1) return 'Producto no encontrado';

    final prodActual = _productos[indexProducto];
    final stockDisponible = origenConcept ? prodActual.cantidadConcept : prodActual.cantidad;
    if (stockDisponible < cantidad) return 'Stock insuficiente';

    if (_carritosActivos.containsKey(idNormalizado) && _carritosActivos[idNormalizado]!.articulos.isNotEmpty) {
      final origenActual = _carritosActivos[idNormalizado]!.articulos.first.origenConcept;
      if (origenActual != origenConcept) {
        return 'No puedes mezclar productos del Principal y Concept Store en un mismo ticket.';
      }
    }

    if (!_carritosActivos.containsKey(idNormalizado)) {
      // 🚀 AQUÍ CONVERTIMOS EL NOMBRE A MAYÚSCULAS
      _carritosActivos[idNormalizado] = Carrito(telefonoCliente: telefono.trim().toUpperCase());

      NotificacionesService.programarRecordatorio(
        id: "${idNormalizado}_dia2".hashCode,
        titulo: '⚠️ Apartado sin fecha',
        cuerpo: 'Tienes un apartado de "${telefono.trim().toUpperCase()}" sin fecha desde hace 2 días. ¿Sigue en pie?',
        fechaProgramada: DateTime.now().add(const Duration(days: 2)),
      );

      NotificacionesService.programarRecordatorio(
        id: "${idNormalizado}_dia3".hashCode,
        titulo: '🚨 Apartado olvidado',
        cuerpo: 'El apartado de "${telefono.trim().toUpperCase()}" lleva 3 días sin fecha de entrega asignada.',
        fechaProgramada: DateTime.now().add(const Duration(days: 3)),
      );
    }

    final carrito = _carritosActivos[idNormalizado]!;
    final indexArticulo = carrito.articulos.indexWhere((a) => a.productoId == producto.id && a.origenConcept == origenConcept);
    
    if (indexArticulo != -1) {
      final articuloExistente = carrito.articulos[indexArticulo];
      carrito.articulos[indexArticulo] = ArticuloVenta(
        productoId: articuloExistente.productoId,
        productoNombre: articuloExistente.productoNombre,
        cantidad: articuloExistente.cantidad + cantidad,
        precioUnitario: articuloExistente.precioUnitario,
        origenConcept: origenConcept, 
      );
    } else {
      carrito.articulos.add(ArticuloVenta(
        productoId: producto.id,
        productoNombre: producto.nombre,
        cantidad: cantidad,
        precioUnitario: producto.precioVenta,
        origenConcept: origenConcept, 
      ));
    }

    if (origenConcept) {
      _productos[indexProducto] = prodActual.copyWith(cantidadConcept: prodActual.cantidadConcept - cantidad);
    } else {
      _productos[indexProducto] = prodActual.copyWith(cantidad: prodActual.cantidad - cantidad);
    }
    
    final origenTexto = origenConcept ? 'Concept Store' : 'Principal';
    registrarActividad('Apartó ${cantidad}x "${producto.nombre}" ($origenTexto) en el carrito de "${carrito.telefonoCliente}"'); 

    notifyListeners();
    
    _storage.guardarProductos(_productos);
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);

    return null; 
  }

  void eliminarArticuloDeCarrito(String identificador, ArticuloVenta articulo) {
    final keyCart = _obtenerKeyReal(identificador);
    if (!_carritosActivos.containsKey(keyCart)) return;

    final carrito = _carritosActivos[keyCart]!;
    carrito.articulos.removeWhere((a) => a.productoId == articulo.productoId && a.origenConcept == articulo.origenConcept);

    final indexProd = _productos.indexWhere((p) => p.id == articulo.productoId);
    if (indexProd != -1) {
      final prod = _productos[indexProd];
      if (articulo.origenConcept) {
        _productos[indexProd] = prod.copyWith(cantidadConcept: prod.cantidadConcept + articulo.cantidad);
      } else {
        _productos[indexProd] = prod.copyWith(cantidad: prod.cantidad + articulo.cantidad);
      }
    }

    if (carrito.articulos.isEmpty) {
      if (carrito.anticipo > 0) {
        _dineroEnCaja -= carrito.anticipo;
        _storage.guardarCaja(_dineroEnCaja);
      }
      
      NotificacionesService.cancelarRecordatorio("${keyCart}_pre".hashCode);
      NotificacionesService.cancelarRecordatorio("${keyCart}_post".hashCode);
      NotificacionesService.cancelarRecordatorio("${keyCart}_dia2".hashCode);
      NotificacionesService.cancelarRecordatorio("${keyCart}_dia3".hashCode);

      _carritosActivos.remove(keyCart);
      registrarActividad('Se eliminó el último artículo del apartado de "${carrito.telefonoCliente}" y el carrito fue cancelado');
    } else {
      registrarActividad('Eliminó ${articulo.cantidad}x "${articulo.productoNombre}" del apartado de "${carrito.telefonoCliente}"');
    }

    notifyListeners();
    _storage.guardarProductos(_productos);
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);
  }

  void aplicarDescuentoACarrito(String identificador, double valor, bool esPorcentaje) {
    final keyCart = _obtenerKeyReal(identificador);
    if (_carritosActivos.containsKey(keyCart)) {
      final carrito = _carritosActivos[keyCart]!;
      final descuentoAnterior = carrito.descuentoEsPorcentaje 
          ? '${carrito.descuentoValor}%' 
          : '\$${carrito.descuentoValor.toStringAsFixed(2)}';
      
      final descuentoNuevo = esPorcentaje 
          ? '$valor%' 
          : '\$${valor.toStringAsFixed(2)}';

      carrito.descuentoValor = valor;
      carrito.descuentoEsPorcentaje = esPorcentaje;
      
      if (valor == 0) {
        registrarActividad('Eliminó el descuento del apartado de "${carrito.telefonoCliente}"');
      } else {
        registrarActividad('Cambió descuento en apartado de "${carrito.telefonoCliente}": $descuentoAnterior -> $descuentoNuevo');
      }

      notifyListeners();
      final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
      _storage.guardarCarritosActivos(mapAGuardar);
    }
  }

  void aplicarCargoExtraACarrito(String identificador, double cargo, String concepto) {
    final keyCart = _obtenerKeyReal(identificador);
    if (_carritosActivos.containsKey(keyCart)) {
      final carrito = _carritosActivos[keyCart]!;
      carrito.cargoExtra = cargo;
      final desc = concepto.isEmpty ? 'Cargo Extra' : concepto;
      carrito.conceptoCargoExtra = desc;
      
      registrarActividad('Aplicó un cargo de \$${cargo.toStringAsFixed(2)} por "$desc" al carrito de "${carrito.telefonoCliente}"'); 

      notifyListeners();
      final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
      _storage.guardarCarritosActivos(mapAGuardar);
    }
  }

  void cobrarCarrito(String identificador, {bool pagoConTarjeta = false}) {
    final keyCart = _obtenerKeyReal(identificador);
    if (!_carritosActivos.containsKey(keyCart)) return;

    final carrito = _carritosActivos[keyCart]!;
    carrito.pagoConTarjeta = pagoConTarjeta; 

    final nuevaVenta = Venta(
      id: _uuid.v4(),
      telefonoCliente: carrito.telefonoCliente,
      articulos: List.from(carrito.articulos),
      descuentoAplicado: carrito.descuentoMonto,
      cargoExtra: carrito.cargoExtra, 
      conceptoCargoExtra: carrito.conceptoCargoExtra,
      totalFinal: carrito.total, 
      comisionTarjeta: carrito.comisionTarjetaMonto, 
      pagoConTarjeta: pagoConTarjeta,
      fecha: DateTime.now(),
      lugarEntrega: carrito.lugarEntrega,
    );

    _ventas.add(nuevaVenta);
    
    final montoRestanteCaja = nuevaVenta.ingresoNeto - carrito.anticipo;
    _dineroEnCaja += montoRestanteCaja; 
    
    NotificacionesService.cancelarRecordatorio("${keyCart}_pre".hashCode);
    NotificacionesService.cancelarRecordatorio("${keyCart}_post".hashCode);
    NotificacionesService.cancelarRecordatorio("${keyCart}_dia2".hashCode);
    NotificacionesService.cancelarRecordatorio("${keyCart}_dia3".hashCode);

    _carritosActivos.remove(keyCart);
    
    final textoPago = pagoConTarjeta 
        ? '(Tarjeta - Comisión: \$${nuevaVenta.comisionTarjeta.toStringAsFixed(2)})' 
        : '(Efectivo)';
    registrarActividad('Cobró el carrito de "${carrito.telefonoCliente}" por un total de \$${nuevaVenta.ingresoNeto.toStringAsFixed(2)} $textoPago');

    _estadisticasDesactualizadas = true;
    notifyListeners();
    
    _storage.guardarVentas(_ventas);
    _storage.guardarCaja(_dineroEnCaja);
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);
  }

  void cancelarCarrito(String identificador) {
    final keyCart = _obtenerKeyReal(identificador);
    if (!_carritosActivos.containsKey(keyCart)) return;
    final carrito = _carritosActivos[keyCart]!;
    
    for (var articulo in carrito.articulos) {
      final index = _productos.indexWhere((p) => p.id == articulo.productoId);
      if (index != -1) {
        final prod = _productos[index];
        if (articulo.origenConcept) {
          _productos[index] = prod.copyWith(cantidadConcept: prod.cantidadConcept + articulo.cantidad);
        } else {
          _productos[index] = prod.copyWith(cantidad: prod.cantidad + articulo.cantidad);
        }
      }
    }
    
    if (carrito.anticipo > 0) {
      _dineroEnCaja -= carrito.anticipo;
      _storage.guardarCaja(_dineroEnCaja);
    }

    NotificacionesService.cancelarRecordatorio("${keyCart}_pre".hashCode);
    NotificacionesService.cancelarRecordatorio("${keyCart}_post".hashCode);
    NotificacionesService.cancelarRecordatorio("${keyCart}_dia2".hashCode);
    NotificacionesService.cancelarRecordatorio("${keyCart}_dia3".hashCode);

    registrarActividad('Canceló el apartado de "${carrito.telefonoCliente}" y devolvió los productos a sus inventarios'); 
    _carritosActivos.remove(keyCart);

    notifyListeners();
    
    _storage.guardarProductos(_productos);
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);
  }

  void revertirVenta(String idVenta) {
    final indexVenta = _ventas.indexWhere((v) => v.id == idVenta);
    if (indexVenta == -1) return;

    final ventaARevertir = _ventas[indexVenta];
    for (var articulo in ventaARevertir.articulos) {
       final indexProd = _productos.indexWhere((p) => p.id == articulo.productoId);
       if(indexProd != -1) {
          final prod = _productos[indexProd];
          if (articulo.origenConcept) {
             _productos[indexProd] = prod.copyWith(cantidadConcept: prod.cantidadConcept + articulo.cantidad);
          } else {
             _productos[indexProd] = prod.copyWith(cantidad: prod.cantidad + articulo.cantidad);
          }
       }
    }

    _dineroEnCaja -= ventaARevertir.ingresoNeto; 
    _ventas.removeAt(indexVenta);
    
    registrarActividad('Revirtió la venta hecha a "${ventaARevertir.telefonoCliente}" de \$${ventaARevertir.totalFinal.toStringAsFixed(2)}'); 

    _estadisticasDesactualizadas = true;
    notifyListeners();

    _storage.guardarProductos(_productos);
    _storage.guardarVentas(_ventas);
    _storage.guardarCaja(_dineroEnCaja);
  }
}