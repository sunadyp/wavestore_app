part of '../inventario_provider.dart';

extension CarritosExtension on InventarioProvider {
  String? agregarAlCarrito(String telefono, Producto producto, int cantidad, {bool origenConcept = false}) {
    final indexProducto = _productos.indexWhere((p) => p.id == producto.id);
    if (indexProducto == -1) return 'Producto no encontrado';

    final prodActual = _productos[indexProducto];
    final stockDisponible = origenConcept ? prodActual.cantidadConcept : prodActual.cantidad;
    if (stockDisponible < cantidad) return 'Stock insuficiente';

    if (_carritosActivos.containsKey(telefono) && _carritosActivos[telefono]!.articulos.isNotEmpty) {
      final origenActual = _carritosActivos[telefono]!.articulos.first.origenConcept;
      if (origenActual != origenConcept) {
        return 'No puedes mezclar productos del Principal y Concept Store en un mismo ticket.';
      }
    }

    if (!_carritosActivos.containsKey(telefono)) {
      _carritosActivos[telefono] = Carrito(telefonoCliente: telefono);
    }

    final carrito = _carritosActivos[telefono]!;
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
    registrarActividad('Apartó ${cantidad}x "${producto.nombre}" ($origenTexto) en el carrito de "$telefono"'); 

    notifyListeners();
    
    _storage.guardarProductos(_productos);
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);

    return null; 
  }

  void eliminarArticuloDeCarrito(String identificador, ArticuloVenta articulo) {
    if (!_carritosActivos.containsKey(identificador)) return;

    final carrito = _carritosActivos[identificador]!;
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
      _carritosActivos.remove(identificador);
      registrarActividad('Se eliminó el último artículo del apartado de "$identificador" y el carrito fue cancelado');
    } else {
      registrarActividad('Eliminó ${articulo.cantidad}x "${articulo.productoNombre}" del apartado de "$identificador"');
    }

    notifyListeners();
    _storage.guardarProductos(_productos);
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);
  }

  void aplicarDescuentoACarrito(String identificador, double valor, bool esPorcentaje) {
    if (_carritosActivos.containsKey(identificador)) {
      final carrito = _carritosActivos[identificador]!;
      final descuentoAnterior = carrito.descuentoEsPorcentaje 
          ? '${carrito.descuentoValor}%' 
          : '\$${carrito.descuentoValor.toStringAsFixed(2)}';
      
      final descuentoNuevo = esPorcentaje 
          ? '$valor%' 
          : '\$${valor.toStringAsFixed(2)}';

      carrito.descuentoValor = valor;
      carrito.descuentoEsPorcentaje = esPorcentaje;
      
      if (valor == 0) {
        registrarActividad('Eliminó el descuento del apartado de "$identificador"');
      } else {
        registrarActividad('Cambió descuento en apartado de "$identificador": $descuentoAnterior -> $descuentoNuevo');
      }

      notifyListeners();
      final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
      _storage.guardarCarritosActivos(mapAGuardar);
    }
  }

  void aplicarCargoExtraACarrito(String identificador, double cargo, String concepto) {
    if (_carritosActivos.containsKey(identificador)) {
      _carritosActivos[identificador]!.cargoExtra = cargo;
      final desc = concepto.isEmpty ? 'Cargo Extra' : concepto;
      _carritosActivos[identificador]!.conceptoCargoExtra = desc;
      
      registrarActividad('Aplicó un cargo de \$${cargo.toStringAsFixed(2)} por "$desc" al carrito de "$identificador"'); 

      notifyListeners();
      final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
      _storage.guardarCarritosActivos(mapAGuardar);
    }
  }

  void cobrarCarrito(String identificador, {bool pagoConTarjeta = false}) {
    if (!_carritosActivos.containsKey(identificador)) return;

    final carrito = _carritosActivos[identificador]!;
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
    );

    _ventas.add(nuevaVenta);
    
    _dineroEnCaja += nuevaVenta.ingresoNeto; 
    _carritosActivos.remove(identificador);
    
    final textoPago = pagoConTarjeta 
        ? '(Tarjeta - Comisión: \$${nuevaVenta.comisionTarjeta.toStringAsFixed(2)})' 
        : '(Efectivo)';
    registrarActividad('Cobró el carrito de "$identificador" por un total de \$${nuevaVenta.totalFinal.toStringAsFixed(2)} $textoPago');

    _estadisticasDesactualizadas = true;
    notifyListeners();
    
    _storage.guardarVentas(_ventas);
    _storage.guardarCaja(_dineroEnCaja);
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);
  }

  void cancelarCarrito(String identificador) {
    if (!_carritosActivos.containsKey(identificador)) return;
    final carrito = _carritosActivos[identificador]!;
    
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
    _carritosActivos.remove(identificador);
    
    registrarActividad('Canceló el apartado de "$identificador" y devolvió los productos a sus inventarios'); 

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