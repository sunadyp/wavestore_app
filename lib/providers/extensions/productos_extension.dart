part of '../inventario_provider.dart';

extension ProductosExtension on InventarioProvider {
  void agregarProducto(Producto nuevo, {bool afectaCaja = true}) {
    _productos.add(nuevo);
    
    double gastoPorInventario = nuevo.costo * nuevo.cantidad;
    
    if (afectaCaja) {
      _dineroEnCaja -= gastoPorInventario;
      _storage.guardarCaja(_dineroEnCaja);
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
    _storage.guardarMovimientos(_movimientos);
    
    registrarActividad('Creó el producto "${nuevo.nombre}" con ${nuevo.cantidad} unidades en stock');
    _estadisticasDesactualizadas = true;
    notifyListeners();
    _storage.guardarProductos(_productos);
  }

  void editarProducto(String id, Producto editado) {
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
        registrarActividad('Editó "${pAntiguo.nombre}" | $detalleCambios');
      }

      _productos[index] = editado;
      notifyListeners();
      _storage.guardarProductos(_productos);
    }
  }

  void eliminarProducto(String id) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final nombre = _productos[index].nombre;
      _productos.removeAt(index);
      
      registrarActividad('Eliminó el producto "$nombre" del inventario'); 
      
      notifyListeners();
      _storage.guardarProductos(_productos);
    }
  }

  void reabastecerProducto(String id, int cantidadEntrante, double costoUnitarioEntrante, {bool afectaCaja = true}) {
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
        _storage.guardarCaja(_dineroEnCaja);
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
      
      _storage.guardarMovimientos(_movimientos);
      
      registrarActividad(
        'Reabasteció "${prod.nombre}" (+$cantidadEntrante al Principal). '
        'Stock Principal: ${prod.cantidad} -> $nuevoStockTotal. '
        'Costo prom: \$${prod.costo.toStringAsFixed(2)} -> \$${nuevoCostoPromedio.toStringAsFixed(2)}'
      );

      _estadisticasDesactualizadas = true;
      notifyListeners();
      _storage.guardarProductos(_productos);
    }
  }

  void transferirStock(String id, int cantidad, bool haciaConcept) {
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

      registrarActividad('Transfirió $cantidad unidades de "${prod.nombre}" de $origen');

      _estadisticasDesactualizadas = true;
      notifyListeners();
      _storage.guardarProductos(_productos);
      _storage.guardarMovimientos(_movimientos);
    }
  }

  void revertirMovimiento(String idMovimiento) {
    final indexMov = _movimientos.indexWhere((m) => m.id == idMovimiento);
    if (indexMov == -1) return;

    final mov = _movimientos[indexMov];

    // 1. Revertir el dinero (si aplicó a la caja)
    if (mov.afectoCaja) {
      if (mov.esInversion) {
        _dineroEnCaja -= mov.monto; 
      } else {
        _dineroEnCaja += mov.monto; 
      }
    }

    // 2. Revertir el stock (si el movimiento afectó un producto)
    if (mov.productoId != null && mov.cantidadArticulos != null) {
      final indexProd = _productos.indexWhere((p) => p.id == mov.productoId);
      
      if (indexProd != -1) {
        final prod = _productos[indexProd];
        
        // Verificamos si es una Merma/Salida para SUMAR en lugar de RESTAR
        final bool esSalidaDeStock = mov.descripcion.startsWith('Salida de stock');
        
        if (esSalidaDeStock) {
          // 🚀 SI ERA UNA MERMA: Devolvemos el stock al inventario original
          final bool eraDeConcept = mov.descripcion.contains('(Concept Store)');
          
          if (eraDeConcept) {
             _productos[indexProd] = prod.copyWith(
               cantidadConcept: prod.cantidadConcept + mov.cantidadArticulos!
             );
          } else {
             _productos[indexProd] = prod.copyWith(
               cantidad: prod.cantidad + mov.cantidadArticulos!
             );
          }
        } else {
          // 🚀 SI ERA UNA COMPRA O INGRESO: Le quitamos el stock (Lógica original)
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
        
        _storage.guardarProductos(_productos);
      }
    }

    _movimientos.removeAt(indexMov);
    
    final textoCaja = mov.afectoCaja 
        ? 'y se ajustó la caja por \$${mov.monto.toStringAsFixed(2)}' 
        : 'sin alterar el saldo de la caja';
        
    registrarActividad('Revirtió el movimiento: "${mov.descripcion}" $textoCaja');

    _estadisticasDesactualizadas = true;
    notifyListeners();
    
    _storage.guardarCaja(_dineroEnCaja);
    _storage.guardarMovimientos(_movimientos);
  }

  void registrarSalida(String id, int cantidad, String motivo, {bool deConceptStore = false}) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final prod = _productos[index];
      
      // 1. Restamos del inventario correspondiente
      if (deConceptStore) {
        _productos[index] = prod.copyWith(cantidadConcept: prod.cantidadConcept - cantidad);
      } else {
        _productos[index] = prod.copyWith(cantidad: prod.cantidad - cantidad);
      }

      final origen = deConceptStore ? 'Concept Store' : 'Principal';

      // 2. Registramos el movimiento en $0.00 para no afectar la caja ni inflar ventas
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

      // 3. Bitácora
      registrarActividad('Registró salida de ${cantidad}x "${prod.nombre}" ($origen). Motivo: $motivo');

      _estadisticasDesactualizadas = true;
      notifyListeners();
      _storage.guardarProductos(_productos);
      _storage.guardarMovimientos(_movimientos);
    }
  }
}