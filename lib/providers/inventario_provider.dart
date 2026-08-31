import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; 
import '../models/producto.dart';
import '../models/venta.dart';
import '../models/movimiento.dart'; 
import '../models/actividad.dart'; // <-- NUEVO IMPORT
import '../data/storage_service.dart';

class InventarioProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Venta> _ventas = [];
  List<String> _categorias = ['General'];
  List<Movimiento> _movimientos = []; 
  List<Actividad> _actividades = []; // <-- NUEVA LISTA DE BITÁCORA

  double _dineroEnCaja = 0.0;
  String _filtro = '';
  
  Map<String, Carrito> _carritosActivos = {};
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  List<Map<String, dynamic>> _cacheEstadisticas = [];
  bool _estadisticasDesactualizadas = true;

  InventarioProvider() {
    _cargarDesdeDisco();
  }

  // --- GETTERS PRINCIPALES ---
  List<Producto> get productos {
    if (_filtro.isEmpty) return _productos;
    return _productos.where((p) => p.nombre.toLowerCase().contains(_filtro.toLowerCase())).toList();
  }
  List<Venta> get ventas => _ventas;
  List<String> get categorias => _categorias;
  List<Movimiento> get movimientos => _movimientos; 
  List<Actividad> get actividades => _actividades; // <-- NUEVO GETTER

  double get dineroEnCaja => _dineroEnCaja;
  Map<String, Carrito> get carritosActivos => _carritosActivos;

  double get capitalInvertido => _productos.fold(0, (sum, item) => sum + (item.costo * item.cantidad));
  double get dineroPosible => _productos.fold(0, (sum, item) => sum + (item.precioVenta * item.cantidad));
  double get gananciaPotencial => dineroPosible - capitalInvertido;

  // --- BUSINESS INSIGHTS ---
  double get ticketPromedio {
    if (_ventas.isEmpty) return 0.0;
    final totalIngresos = _ventas.fold(0.0, (sum, v) => sum + v.totalFinal);
    return totalIngresos / _ventas.length;
  }

  Map<String, dynamic>? get productoMasVendido {
    if (_ventas.isEmpty) return null;
    
    final conteoVentas = <String, int>{};
    final nombres = <String, String>{};

    for (var venta in _ventas) {
      for (var art in venta.articulos) {
        conteoVentas[art.productoId] = (conteoVentas[art.productoId] ?? 0) + art.cantidad;
        nombres[art.productoId] = art.productoNombre;
      }
    }

    if (conteoVentas.isEmpty) return null;
    final idMasVendido = conteoVentas.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    return {
      'nombre': nombres[idMasVendido],
      'cantidad': conteoVentas[idMasVendido],
    };
  }

  Map<String, dynamic>? get productoMayorIngreso {
    if (_ventas.isEmpty) return null;
    
    final ingresosPorProducto = <String, double>{};
    final nombres = <String, String>{};

    for (var venta in _ventas) {
      for (var art in venta.articulos) {
        ingresosPorProducto[art.productoId] = (ingresosPorProducto[art.productoId] ?? 0.0) + art.subtotal;
        nombres[art.productoId] = art.productoNombre;
      }
    }

    if (ingresosPorProducto.isEmpty) return null;
    final idMayorIngreso = ingresosPorProducto.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    return {
      'nombre': nombres[idMayorIngreso],
      'ingreso': ingresosPorProducto[idMayorIngreso],
    };
  }

  List<Producto> get productosPorAgotarse {
    final casiAgotados = _productos.where((p) => p.cantidad > 0 && p.cantidad <= 3).toList();
    casiAgotados.sort((a, b) => a.cantidad.compareTo(b.cantidad));
    return casiAgotados.take(4).toList(); 
  }

  double get promedioMensual {
    final stats = obtenerEstadisticasMensuales();
    if (stats.isEmpty) return 0.0;
    double totalGanancia = stats.fold(0.0, (sum, item) => sum + item['ganancia']);
    return totalGanancia / stats.length;
  }

  double get gananciaMesActual {
    final ahora = DateTime.now();
    final mesActual = "${ahora.year}-${ahora.month.toString().padLeft(2, '0')}";
    final stats = obtenerEstadisticasMensuales();
    
    final actual = stats.where((s) => s['mes_anio'] == mesActual).toList();
    if (actual.isEmpty) return 0.0;
    return actual.first['ganancia'];
  }

  List<Venta> obtenerVentasPorRango(DateTime inicio, DateTime fin) {
    final inicioDia = DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0);
    final finDelDia = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);
    return _ventas.where((v) => v.fecha.isAfter(inicioDia) && v.fecha.isBefore(finDelDia)).toList();
  }

  List<Map<String, dynamic>> obtenerSemanasMesActual() {
    List<Map<String, dynamic>> semanas = [];
    DateTime ahora = DateTime.now();
    DateTime primeroMes = DateTime(ahora.year, ahora.month, 1);
    DateTime lunes = primeroMes.subtract(Duration(days: primeroMes.weekday - 1));

    for (int i = 0; i < 6; i++) {
      DateTime inicioSemana = lunes.add(Duration(days: i * 7));
      DateTime finSemana = inicioSemana.add(const Duration(days: 6));
      String id = "${inicioSemana.day}-${inicioSemana.month}-${inicioSemana.year}";
      String label = "${DateFormat('dd MMM').format(inicioSemana)} -${DateFormat('dd MMM').format(finSemana)}";
      semanas.add({'id': id, 'label': label, 'inicio': inicioSemana, 'fin': finSemana});
    }
    return semanas;
  }

  List<Map<String, dynamic>> obtenerEstadisticasMensuales() {
    if (!_estadisticasDesactualizadas) return _cacheEstadisticas;

    Map<String, Map<String, dynamic>> stats = {};

    for (var v in _ventas) {
      String mes = "${v.fecha.year}-${v.fecha.month.toString().padLeft(2, '0')}";
      if (!stats.containsKey(mes)) {
        stats[mes] = {'ingresos': 0.0, 'gastos': 0.0, 'fecha': DateTime(v.fecha.year, v.fecha.month)};
      }
      stats[mes]!['ingresos'] += v.totalFinal;
    }

    for (var m in _movimientos) {
      if (!m.esInversion) {
        String mes = "${m.fecha.year}-${m.fecha.month.toString().padLeft(2, '0')}";
        if (!stats.containsKey(mes)) {
          stats[mes] = {'ingresos': 0.0, 'gastos': 0.0, 'fecha': DateTime(m.fecha.year, m.fecha.month)};
        }
        stats[mes]!['gastos'] += m.monto;
      }
    }

    List<Map<String, dynamic>> listaStats = stats.entries.map((e) {
      double ingresos = e.value['ingresos'];
      double gastos = e.value['gastos'];
      double ganancia = ingresos - gastos;
      return {
        'mes_anio': e.key,
        'fecha': e.value['fecha'],
        'ingresos': ingresos,
        'gastos': gastos,
        'ganancia': ganancia,
      };
    }).toList();

    listaStats.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
    
    _cacheEstadisticas = listaStats;
    _estadisticasDesactualizadas = false;
    
    return _cacheEstadisticas;
  }

  // ==========================================================
  // --- MOTOR DE AUDITORÍA (BITÁCORA) OPTIMIZADO ---
  // ==========================================================
  void _registrarActividad(String descripcion) {
    _actividades.insert(0, Actividad(
      id: _uuid.v4(),
      descripcion: descripcion,
      fecha: DateTime.now(),
    ));

    // 🚀 OPTIMIZACIÓN DE MEMORIA RAM: 
    // Mantenemos solo los últimos 1000 registros. 
    // Evita que el archivo JSON crezca infinitamente y congele la app al iniciar.
    if (_actividades.length > 1000) {
      _actividades = _actividades.sublist(0, 1000);
    }

    _storage.guardarActividades(_actividades);
    notifyListeners(); // Notificamos para que la UI se actualice si está abierta
  }

  // --- ACCIONES DE INVENTARIO Y CATEGORÍAS ---
  void limpiarBitacora() {
    _actividades.clear();
    _storage.guardarActividades(_actividades);
    notifyListeners();
  }

  void filtrar(String texto) {
    _filtro = texto;
    notifyListeners();
  }

  void agregarCategoria(String nombre) {
    if (nombre.isNotEmpty && !_categorias.contains(nombre)) {
      _categorias.add(nombre);
      _registrarActividad('Agregó la categoría "$nombre"'); // <-- BITÁCORA
      notifyListeners();
      _storage.guardarCategorias(_categorias);
    }
  }

  void agregarSaldoInicial(double saldo) {
    _dineroEnCaja = saldo;
    _estadisticasDesactualizadas = true;
    _registrarActividad('Configuró el saldo inicial en \$${saldo.toStringAsFixed(2)}'); // <-- BITÁCORA
    notifyListeners();
    _storage.guardarCaja(_dineroEnCaja);
  }

  void agregarProducto(Producto nuevo, {bool afectaCaja = true}) {
    _productos.add(nuevo);
    
    double gastoPorInventario = nuevo.costo * nuevo.cantidad;
    
    // Solo restamos de la caja si así lo pediste
    if (afectaCaja) {
      _dineroEnCaja -= gastoPorInventario;
      _storage.guardarCaja(_dineroEnCaja);
    }
    
    // SIEMPRE registramos el movimiento para tener de dónde "Deshacer"
    _movimientos.add(Movimiento(
      id: _uuid.v4(),
      // Le ponemos una etiqueta clara si no afectó caja
      descripcion: afectaCaja 
          ? 'Compra inicial: ${nuevo.nombre}' 
          : 'Ingreso a stock (Sin costo a caja): ${nuevo.nombre}',
      monto: gastoPorInventario, // Guardamos el valor real para que la matemática inversa funcione
      fecha: DateTime.now(),
      esInversion: false, 
      productoId: nuevo.id, 
      cantidadArticulos: nuevo.cantidad, 
      afectoCaja: afectaCaja, // <-- Guardamos la bandera
    ));
    _storage.guardarMovimientos(_movimientos);
    
    _registrarActividad('Creó el producto "${nuevo.nombre}" con ${nuevo.cantidad} unidades en stock');
    _estadisticasDesactualizadas = true;
    notifyListeners();
    _storage.guardarProductos(_productos);
  }

  void editarProducto(String id, Producto editado) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final pAntiguo = _productos[index];
      
      // Construimos el desglose exacto de los cambios
      List<String> cambios = [];
      
      if (pAntiguo.nombre != editado.nombre) {
        cambios.add('Nombre: "${pAntiguo.nombre}" -> "${editado.nombre}"');
      }
      if (pAntiguo.categoria != editado.categoria) {
        cambios.add('Categoría: "${pAntiguo.categoria}" -> "${editado.categoria}"');
      }
      if (pAntiguo.costo != editado.costo) {
        cambios.add('Costo: \$${pAntiguo.costo.toStringAsFixed(2)} -> \$${editado.costo.toStringAsFixed(2)}');
      }
      if (pAntiguo.precioVenta != editado.precioVenta) {
        cambios.add('Precio: \$${pAntiguo.precioVenta.toStringAsFixed(2)} -> \$${editado.precioVenta.toStringAsFixed(2)}');
      }
      if (pAntiguo.cantidad != editado.cantidad) {
        cambios.add('Stock ajustado: ${pAntiguo.cantidad} -> ${editado.cantidad}');
      }

      // Solo registramos si realmente hubo algún cambio
      if (cambios.isNotEmpty) {
        final detalleCambios = cambios.join(', ');
        _registrarActividad('Editó "${pAntiguo.nombre}" | $detalleCambios');
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
      
      _registrarActividad('Eliminó el producto "$nombre" del inventario'); // <-- BITÁCORA
      
      notifyListeners();
      _storage.guardarProductos(_productos);
    }
  }

  void reabastecerProducto(String id, int cantidadEntrante, double costoUnitarioEntrante, {bool afectaCaja = true}) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final prod = _productos[index];
      final int nuevoStockTotal = prod.cantidad + cantidadEntrante;
      
      // Calculamos el nuevo costo promedio
      final double nuevoCostoPromedio = nuevoStockTotal > 0 
          ? ((prod.cantidad * prod.costo) + (cantidadEntrante * costoUnitarioEntrante)) / nuevoStockTotal 
          : costoUnitarioEntrante;

      _productos[index] = prod.copyWith(
        cantidad: nuevoStockTotal,
        costo: nuevoCostoPromedio,
      );
      
      double gastoPorReabastecer = costoUnitarioEntrante * cantidadEntrante;

      // 1. Solo restamos de la caja si se indicó que afecta caja
      if (afectaCaja) {
        _dineroEnCaja -= gastoPorReabastecer;
        _storage.guardarCaja(_dineroEnCaja);
      }
      
      // 2. SIEMPRE registramos el movimiento en el historial
      _movimientos.add(Movimiento(
        id: _uuid.v4(),
        descripcion: afectaCaja 
            ? 'Reabastecimiento: ${prod.nombre} ($cantidadEntrante uds)'
            : 'Reabastecimiento (Sin costo a caja): ${prod.nombre} ($cantidadEntrante uds)',
        monto: gastoPorReabastecer, // Guardamos el valor para la matemática inversa
        fecha: DateTime.now(),
        esInversion: false, 
        productoId: prod.id, // Huella del producto
        cantidadArticulos: cantidadEntrante, // Huella de la cantidad
        afectoCaja: afectaCaja, // Huella de la caja
      ));
      
      _storage.guardarMovimientos(_movimientos);
      
      // 3. Registro detallado en la bitácora
      _registrarActividad(
        'Reabasteció "${prod.nombre}" (+$cantidadEntrante). '
        'Stock: ${prod.cantidad} -> $nuevoStockTotal. '
        'Costo prom: \$${prod.costo.toStringAsFixed(2)} -> \$${nuevoCostoPromedio.toStringAsFixed(2)}'
      );

      _estadisticasDesactualizadas = true;
      notifyListeners();
      _storage.guardarProductos(_productos);
    }
  }

  void revertirMovimiento(String idMovimiento) {
    final indexMov = _movimientos.indexWhere((m) => m.id == idMovimiento);
    if (indexMov == -1) return;

    final mov = _movimientos[indexMov];

    // 1. REVERTIR EL DINERO EN CAJA (Solo si originalmente afectó la caja)
    if (mov.afectoCaja) {
      if (mov.esInversion) {
        _dineroEnCaja -= mov.monto; // Si fue un ingreso, lo quitamos
      } else {
        _dineroEnCaja += mov.monto; // Si fue un gasto, devolvemos el dinero a la caja
      }
    }

    // 2. REVERTIR EL STOCK Y EL COSTO PROMEDIO (Si fue un movimiento de inventario)
    if (mov.productoId != null && mov.cantidadArticulos != null) {
      final indexProd = _productos.indexWhere((p) => p.id == mov.productoId);
      
      if (indexProd != -1) {
        final prod = _productos[indexProd];
        final stockOriginal = prod.cantidad - mov.cantidadArticulos!;
        
        double costoOriginal = 0.0;
        
        // Deshacemos la matemática del costo promedio
        if (stockOriginal > 0) {
          costoOriginal = ((prod.costo * prod.cantidad) - mov.monto) / stockOriginal;
          if (costoOriginal < 0) costoOriginal = 0.0; // Protección contra valores negativos
        }

        _productos[indexProd] = prod.copyWith(
          cantidad: stockOriginal < 0 ? 0 : stockOriginal,
          costo: costoOriginal,
        );
        _storage.guardarProductos(_productos);
      }
    }

    // 3. ELIMINAR EL MOVIMIENTO Y REGISTRAR EN BITÁCORA
    _movimientos.removeAt(indexMov);
    
    final textoCaja = mov.afectoCaja 
        ? 'y se ajustó la caja por \$${mov.monto.toStringAsFixed(2)}' 
        : 'sin alterar el saldo de la caja';
        
    _registrarActividad('Revirtió el movimiento: "${mov.descripcion}" $textoCaja');

    _estadisticasDesactualizadas = true;
    notifyListeners();
    
    _storage.guardarCaja(_dineroEnCaja);
    _storage.guardarMovimientos(_movimientos);
  }

  void registrarGasto(double monto, String descripcion) {
    _dineroEnCaja -= monto;
    final nombreDesc = descripcion.isEmpty ? 'Gasto general' : descripcion;
    _movimientos.add(Movimiento(
      id: _uuid.v4(),
      descripcion: nombreDesc,
      monto: monto,
      fecha: DateTime.now(),
      esInversion: false,
    ));
    
    _registrarActividad('Registró un gasto de \$${monto.toStringAsFixed(2)} por "$nombreDesc"'); // <-- BITÁCORA

    _estadisticasDesactualizadas = true;
    notifyListeners();
    _storage.guardarCaja(_dineroEnCaja);
    _storage.guardarMovimientos(_movimientos);
  }

  void registrarInversion(double monto, String descripcion) {
    _dineroEnCaja += monto;
    final nombreDesc = descripcion.isEmpty ? 'Inversión' : descripcion;
    _movimientos.add(Movimiento(
      id: _uuid.v4(),
      descripcion: nombreDesc,
      monto: monto,
      fecha: DateTime.now(),
      esInversion: true,
    ));
    
    _registrarActividad('Registró un ingreso/inversión de \$${monto.toStringAsFixed(2)} por "$nombreDesc"'); // <-- BITÁCORA

    _estadisticasDesactualizadas = true;
    notifyListeners();
    _storage.guardarCaja(_dineroEnCaja);
    _storage.guardarMovimientos(_movimientos);
  }

  // --- LÓGICA DE CARRITOS Y VENTAS ---
  void agregarAlCarrito(String telefono, Producto producto, int cantidad) {
    final indexProducto = _productos.indexWhere((p) => p.id == producto.id);
    if (indexProducto == -1 || _productos[indexProducto].cantidad < cantidad) return;

    if (!_carritosActivos.containsKey(telefono)) {
      _carritosActivos[telefono] = Carrito(telefonoCliente: telefono);
    }

    final carrito = _carritosActivos[telefono]!;
    final indexArticulo = carrito.articulos.indexWhere((a) => a.productoId == producto.id);
    
    if (indexArticulo != -1) {
      final articuloExistente = carrito.articulos[indexArticulo];
      carrito.articulos[indexArticulo] = ArticuloVenta(
        productoId: articuloExistente.productoId,
        productoNombre: articuloExistente.productoNombre,
        cantidad: articuloExistente.cantidad + cantidad,
        precioUnitario: articuloExistente.precioUnitario,
      );
    } else {
      carrito.articulos.add(ArticuloVenta(
        productoId: producto.id,
        productoNombre: producto.nombre,
        cantidad: cantidad,
        precioUnitario: producto.precioVenta,
      ));
    }

    _productos[indexProducto] = producto.copyWith(cantidad: producto.cantidad - cantidad);
    
    _registrarActividad('Apartó ${cantidad}x "${producto.nombre}" en el carrito de "$telefono"'); // <-- BITÁCORA

    notifyListeners();
    
    _storage.guardarProductos(_productos);
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);
  }

  void eliminarArticuloDeCarrito(String identificador, ArticuloVenta articulo) {
    if (!_carritosActivos.containsKey(identificador)) return;

    final carrito = _carritosActivos[identificador]!;

    // 1. Quitamos el artículo específico del carrito
    carrito.articulos.removeWhere((a) => a.productoId == articulo.productoId);

    // 2. Regresamos el stock al inventario general
    final indexProd = _productos.indexWhere((p) => p.id == articulo.productoId);
    if (indexProd != -1) {
      _productos[indexProd] = _productos[indexProd].copyWith(
        cantidad: _productos[indexProd].cantidad + articulo.cantidad
      );
    }

    // 3. Registramos la acción
    if (carrito.articulos.isEmpty) {
      // Si el carrito se quedó sin productos, lo eliminamos por completo para no dejar basura
      _carritosActivos.remove(identificador);
      _registrarActividad('Se eliminó el último artículo del apartado de "$identificador" y el carrito fue cancelado');
    } else {
      _registrarActividad('Eliminó ${articulo.cantidad}x "${articulo.productoNombre}" del apartado de "$identificador"');
    }

    // 4. Notificamos a la UI y guardamos en disco
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
        _registrarActividad('Eliminó el descuento del apartado de "$identificador"');
      } else {
        _registrarActividad('Cambió descuento en apartado de "$identificador": $descuentoAnterior -> $descuentoNuevo');
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
      
      _registrarActividad('Aplicó un cargo de \$${cargo.toStringAsFixed(2)} por "$desc" al carrito de "$identificador"'); // <-- BITÁCORA

      notifyListeners();
      final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
      _storage.guardarCarritosActivos(mapAGuardar);
    }
  }

  void cobrarCarrito(String identificador) {
    if (!_carritosActivos.containsKey(identificador)) return;

    final carrito = _carritosActivos[identificador]!;
    final nuevaVenta = Venta(
      id: _uuid.v4(),
      telefonoCliente: carrito.telefonoCliente,
      articulos: List.from(carrito.articulos),
      descuentoAplicado: carrito.descuentoMonto,
      cargoExtra: carrito.cargoExtra, 
      conceptoCargoExtra: carrito.conceptoCargoExtra,
      totalFinal: carrito.total,
      fecha: DateTime.now(),
    );

    _ventas.add(nuevaVenta);
    _dineroEnCaja += nuevaVenta.totalFinal;
    _carritosActivos.remove(identificador);
    
    _registrarActividad('Cobró el carrito de "$identificador" por un total de \$${nuevaVenta.totalFinal.toStringAsFixed(2)}'); // <-- BITÁCORA

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
        _productos[index] = _productos[index].copyWith(
          cantidad: _productos[index].cantidad + articulo.cantidad
        );
      }
    }
    _carritosActivos.remove(identificador);
    
    _registrarActividad('Canceló el apartado de "$identificador" y devolvió los productos al inventario'); // <-- BITÁCORA

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
          _productos[indexProd] = _productos[indexProd].copyWith(
            cantidad: _productos[indexProd].cantidad + articulo.cantidad
          );
       }
    }

    _dineroEnCaja -= ventaARevertir.totalFinal;
    _ventas.removeAt(indexVenta);
    
    _registrarActividad('Revirtió la venta hecha a "${ventaARevertir.telefonoCliente}" de \$${ventaARevertir.totalFinal.toStringAsFixed(2)}'); // <-- BITÁCORA

    _estadisticasDesactualizadas = true;
    notifyListeners();

    _storage.guardarProductos(_productos);
    _storage.guardarVentas(_ventas);
    _storage.guardarCaja(_dineroEnCaja);
  }

  Future<void> _cargarDesdeDisco() async {
    _productos = await _storage.cargarProductos();
    _ventas = await _storage.cargarVentas();
    _dineroEnCaja = await _storage.cargarCaja();
    _categorias = await _storage.cargarCategorias();
    _movimientos = await _storage.cargarMovimientos();
    
    // <-- CARGAMOS LA BITÁCORA
    _actividades = await _storage.cargarActividades();

    final carritosRaw = await _storage.cargarCarritosActivos();
    _carritosActivos = carritosRaw.map((key, value) => MapEntry(key, Carrito.fromMap(value)));

    _estadisticasDesactualizadas = true;
    notifyListeners();
  }
}