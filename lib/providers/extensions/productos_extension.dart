part of '../inventario_provider.dart';

extension ProductosExtension on InventarioProvider {
  Future<void> agregarProducto(Producto nuevo, {bool afectaCaja = true}) async {
    _productos.add(nuevo);
    double gastoPorInventario = nuevo.costo * nuevo.cantidad;
    
    if (afectaCaja) {
      _dineroEnCaja -= gastoPorInventario;
      await _storage.guardarCaja(_dineroEnCaja);
    }
    
    _movimientos.add(Movimiento(
      id: _uuid.v4(),
      descripcion: afectaCaja 
          ? 'Compra inicial: ${nuevo.nombre}' 
          : 'Ingreso a stock (Sin costo a caja): ${nuevo.nombre}',
      monto: gastoPorInventario, 
      fecha: DateTime.now(),
      esInversion: false, 
      productoId: nuevo.id, 
      cantidadArticulos: nuevo.cantidad, 
      afectoCaja: afectaCaja, 
    ));
    await _storage.guardarMovimientos(_movimientos);
    
    await registrarActividad('Creó el producto "${nuevo.nombre}" con ${nuevo.cantidad} unidades en stock');
    _estadisticasDesactualizadas = true;
    
    await _storage.guardarProductos(_productos);
    notifyListeners();
  }

  Future<void> editarProducto(String id, Producto editado) async {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final pAntiguo = _productos[index];
      List<String> cambios = [];
      
      if (pAntiguo.nombre != editado.nombre) cambios.add('Nombre: "${pAntiguo.nombre}" -> "${editado.nombre}"');
      if (pAntiguo.categoria != editado.categoria) cambios.add('Categoría: "${pAntiguo.categoria}" -> "${editado.categoria}"');
      if (pAntiguo.costo != editado.costo) cambios.add('Costo: \$${pAntiguo.costo.toStringAsFixed(2)} -> \$${editado.costo.toStringAsFixed(2)}');
      if (pAntiguo.precioVenta != editado.precioVenta) cambios.add('Precio: \$${pAntiguo.precioVenta.toStringAsFixed(2)} -> \$${editado.precioVenta.toStringAsFixed(2)}');
      if (pAntiguo.cantidad != editado.cantidad) cambios.add('Stock ajustado: ${pAntiguo.cantidad} -> ${editado.cantidad}');
      if (pAntiguo.cantidadConcept != editado.cantidadConcept) cambios.add('Stock Concept ajustado: ${pAntiguo.cantidadConcept} -> ${editado.cantidadConcept}');

      if (cambios.isNotEmpty) {
        final detalleCambios = cambios.join(', ');
        await registrarActividad('Editó "${pAntiguo.nombre}" | $detalleCambios');
      }

      _productos[index] = editado;
      await _storage.guardarProductos(_productos);
      notifyListeners();
    }
  }

  Future<void> eliminarProducto(String id) async {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final nombre = _productos[index].nombre;
      _productos.removeAt(index);
      
      await registrarActividad('Eliminó el producto "$nombre" del inventario'); 
      await _storage.guardarProductos(_productos);
      notifyListeners();
    }
  }

  Future<void> reabastecerProducto(String id, int cantidadEntrante, double costoUnitarioEntrante, {bool afectaCaja = true}) async {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final prod = _productos[index];
      final int nuevoStockTotal = prod.cantidad + cantidadEntrante;
      
      final double nuevoCostoPromedio = nuevoStockTotal > 0 
          ? ((prod.cantidad * prod.costo) + (cantidadEntrante * costoUnitarioEntrante)) / nuevoStockTotal 
          : costoUnitarioEntrante;

      _productos[index] = prod.copyWith(
        cantidad: nuevoStockTotal,
        costo: nuevoCostoPromedio,
      );
      
      double gastoPorReabastecer = costoUnitarioEntrante * cantidadEntrante;

      if (afectaCaja) {
        _dineroEnCaja -= gastoPorReabastecer;
        await _storage.guardarCaja(_dineroEnCaja);
      }
      
      _movimientos.add(Movimiento(
        id: _uuid.v4(),
        descripcion: afectaCaja 
            ? 'Reabastecimiento: ${prod.nombre} ($cantidadEntrante uds)'
            : 'Reabastecimiento (Sin costo a caja): ${prod.nombre} ($cantidadEntrante uds)',
        monto: gastoPorReabastecer, 
        fecha: DateTime.now(),
        esInversion: false, 
        productoId: prod.id, 
        cantidadArticulos: cantidadEntrante, 
        afectoCaja: afectaCaja, 
      ));
      
      await _storage.guardarMovimientos(_movimientos);
      
      await registrarActividad(
        'Reabasteció "${prod.nombre}" (+$cantidadEntrante al Principal). '
        'Stock Principal: ${prod.cantidad} -> $nuevoStockTotal. '
        'Costo prom: \$${prod.costo.toStringAsFixed(2)} -> \$${nuevoCostoPromedio.toStringAsFixed(2)}'
      );

      _estadisticasDesactualizadas = true;
      await _storage.guardarProductos(_productos);
      notifyListeners();
    }
  }

  Future<void> transferirStock(String id, int cantidad, bool haciaConcept) async {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final prod = _productos[index];
      int nuevoPrincipal = prod.cantidad;
      int nuevoConcept = prod.cantidadConcept;

      if (haciaConcept) {
        nuevoPrincipal -= cantidad;
        nuevoConcept += cantidad;
      } else {
        nuevoPrincipal += cantidad;
        nuevoConcept -= cantidad;
      }

      _productos[index] = prod.copyWith(
        cantidad: nuevoPrincipal,
        cantidadConcept: nuevoConcept,
      );

      final origen = haciaConcept ? 'Principal a Concept Store' : 'Concept Store a Principal';
      _movimientos.add(Movimiento(
        id: _uuid.v4(),
        descripcion: 'Transferencia de stock: ${prod.nombre} ($origen)',
        monto: 0.0, 
        fecha: DateTime.now(),
        esInversion: false, 
        productoId: prod.id, 
        cantidadArticulos: cantidad, 
        afectoCaja: false, 
      ));

      await registrarActividad('Transfirió $cantidad unidades de "${prod.nombre}" de $origen');

      _estadisticasDesactualizadas = true;
      await _storage.guardarProductos(_productos);
      await _storage.guardarMovimientos(_movimientos);
      notifyListeners();
    }
  }

  Future<void> revertirMovimiento(String idMovimiento) async {
    final indexMov = _movimientos.indexWhere((m) => m.id == idMovimiento);
    if (indexMov == -1) return;

    final mov = _movimientos[indexMov];

    if (mov.afectoCaja) {
      if (mov.esInversion) {
        _dineroEnCaja -= mov.monto; 
      } else {
        _dineroEnCaja += mov.monto; 
      }
    }

    if (mov.productoId != null && mov.cantidadArticulos != null) {
      final indexProd = _productos.indexWhere((p) => p.id == mov.productoId);
      
      if (indexProd != -1) {
        final prod = _productos[indexProd];
        final bool esSalidaDeStock = mov.descripcion.startsWith('Salida de stock');
        
        if (esSalidaDeStock) {
          final bool eraDeConcept = mov.descripcion.contains('(Concept Store)');
          if (eraDeConcept) {
             _productos[indexProd] = prod.copyWith(cantidadConcept: prod.cantidadConcept + mov.cantidadArticulos!);
          } else {
             _productos[indexProd] = prod.copyWith(cantidad: prod.cantidad + mov.cantidadArticulos!);
          }
        } else {
          final stockOriginal = prod.cantidad - mov.cantidadArticulos!;
          double costoOriginal = 0.0;
          if (stockOriginal > 0) {
            costoOriginal = ((prod.costo * prod.cantidad) - mov.monto) / stockOriginal;
            if (costoOriginal < 0) costoOriginal = 0.0; 
          }
          _productos[indexProd] = prod.copyWith(
            cantidad: stockOriginal < 0 ? 0 : stockOriginal,
            costo: costoOriginal,
          );
        }
        await _storage.guardarProductos(_productos);
      }
    }

    _movimientos.removeAt(indexMov);
    
    final textoCaja = mov.afectoCaja 
        ? 'y se ajustó la caja por \$${mov.monto.toStringAsFixed(2)}' 
        : 'sin alterar el saldo de la caja';
        
    await registrarActividad('Revirtió el movimiento: "${mov.descripcion}" $textoCaja');

    _estadisticasDesactualizadas = true;
    await _storage.guardarCaja(_dineroEnCaja);
    await _storage.guardarMovimientos(_movimientos);
    notifyListeners();
  }

  Future<void> registrarSalida(String id, int cantidad, String motivo, {bool deConceptStore = false}) async {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final prod = _productos[index];
      if (deConceptStore) {
        _productos[index] = prod.copyWith(cantidadConcept: prod.cantidadConcept - cantidad);
      } else {
        _productos[index] = prod.copyWith(cantidad: prod.cantidad - cantidad);
      }

      final origen = deConceptStore ? 'Concept Store' : 'Principal';
      _movimientos.add(Movimiento(
        id: _uuid.v4(),
        descripcion: 'Salida de stock ($origen): ${prod.nombre} - $motivo',
        monto: 0.0, 
        fecha: DateTime.now(),
        esInversion: false, 
        productoId: prod.id, 
        cantidadArticulos: cantidad, 
        afectoCaja: false, 
      ));

      await registrarActividad('Registró salida de ${cantidad}x "${prod.nombre}" ($origen). Motivo: $motivo');

      _estadisticasDesactualizadas = true;
      await _storage.guardarProductos(_productos);
      await _storage.guardarMovimientos(_movimientos);
      notifyListeners();
    }
  }
}