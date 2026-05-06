import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../models/movimiento.dart'; 
import '../data/storage_service.dart';

class InventarioProvider extends ChangeNotifier {
  
  List<Producto> _productos = [];
  List<Venta> _ventas = [];
  List<String> _categorias = ['General'];
  List<Movimiento> _movimientos = []; 
  double _dineroEnCaja = 0.0;
  String _filtro = '';
  
  Map<String, Carrito> _carritosActivos = {};
  final StorageService _storage = StorageService();

  InventarioProvider() {
    _cargarDesdeDisco();
  }

  // --- GETTERS ---
  List<Producto> get productos {
    if (_filtro.isEmpty) return _productos;
    return _productos.where((p) => p.nombre.toLowerCase().contains(_filtro.toLowerCase())).toList();
  }
  List<Venta> get ventas => _ventas;
  List<String> get categorias => _categorias;
  List<Movimiento> get movimientos => _movimientos; 
  double get dineroEnCaja => _dineroEnCaja;
  Map<String, Carrito> get carritosActivos => _carritosActivos;

  double get capitalInvertido => _productos.fold(0, (sum, item) => sum + (item.costo * item.cantidad));
  double get dineroPosible => _productos.fold(0, (sum, item) => sum + (item.precioVenta * item.cantidad));
  double get gananciaPotencial => dineroPosible - capitalInvertido;

  // --- NUEVOS GETTERS PARA ESTADÍSTICAS MENSUALES ---
  
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

  // --- LÓGICA DE FILTRADO, SEMANAS Y MESES ---
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
      String label = "${DateFormat('dd MMM').format(inicioSemana)} - ${DateFormat('dd MMM').format(finSemana)}";
      semanas.add({'id': id, 'label': label, 'inicio': inicioSemana, 'fin': finSemana});
    }
    return semanas;
  }

  List<Map<String, dynamic>> obtenerEstadisticasMensuales() {
    Map<String, Map<String, dynamic>> stats = {};

    // Sumar ingresos (Ventas)
    for (var v in _ventas) {
      String mes = "${v.fecha.year}-${v.fecha.month.toString().padLeft(2, '0')}";
      if (!stats.containsKey(mes)) {
        stats[mes] = {'ingresos': 0.0, 'gastos': 0.0, 'fecha': DateTime(v.fecha.year, v.fecha.month)};
      }
      stats[mes]!['ingresos'] += v.totalFinal;
    }

    // Sumar egresos (Gastos)
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
    return listaStats;
  }

  // --- ACCIONES DE INVENTARIO Y CATEGORÍAS ---
  void filtrar(String texto) {
    _filtro = texto;
    notifyListeners();
  }

  void agregarCategoria(String nombre) {
    if (nombre.isNotEmpty && !_categorias.contains(nombre)) {
      _categorias.add(nombre);
      _notificarYGuardar();
    }
  }

  void _notificarYGuardar() {
    notifyListeners();
    _storage.guardarTodo(
      productos: _productos,
      ventas: _ventas,
      caja: _dineroEnCaja,
      categorias: _categorias,
      movimientos: _movimientos, 
    );
  }

  void _guardarCarritos() {
    final mapAGuardar = _carritosActivos.map((key, value) => MapEntry(key, value.toMap()));
    _storage.guardarCarritosActivos(mapAGuardar);
  }

  void agregarSaldoInicial(double saldo) {
    _dineroEnCaja = saldo;
    _notificarYGuardar();
  }

  void agregarProducto(Producto nuevo, {bool afectaCaja = true}) {
    _productos.add(nuevo);
    
    if (afectaCaja) {
      // Calcular el gasto total de este nuevo inventario
      double gastoPorInventario = nuevo.costo * nuevo.cantidad;
      _dineroEnCaja -= gastoPorInventario;

      // Registrar formalmente el movimiento en el historial
      _movimientos.add(Movimiento(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        descripcion: 'Compra inicial inventario: ${nuevo.nombre}',
        monto: gastoPorInventario,
        fecha: DateTime.now(),
        esInversion: false, 
      ));
    }

    _notificarYGuardar();
  }

  void editarProducto(String id, Producto editado) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      _productos[index] = editado;
      _notificarYGuardar();
    }
  }

  void eliminarProducto(String id) {
    _productos.removeWhere((p) => p.id == id);
    _notificarYGuardar();
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
      
      if (afectaCaja) {
        // Calcular el gasto del reabastecimiento
        double gastoPorReabastecer = costoUnitarioEntrante * cantidadEntrante;
        _dineroEnCaja -= gastoPorReabastecer;

        // Registrar formalmente el movimiento en el historial
        _movimientos.add(Movimiento(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          descripcion: 'Reabastecimiento: ${prod.nombre} ($cantidadEntrante uds)',
          monto: gastoPorReabastecer,
          fecha: DateTime.now(),
          esInversion: false, 
        ));
      }

      _notificarYGuardar();
    }
  }

  void registrarGasto(double monto, String descripcion) {
    _dineroEnCaja -= monto;
    _movimientos.add(Movimiento(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descripcion: descripcion.isEmpty ? 'Gasto general' : descripcion,
      monto: monto,
      fecha: DateTime.now(),
      esInversion: false,
    ));
    _notificarYGuardar();
  }

  void registrarInversion(double monto, String descripcion) {
    _dineroEnCaja += monto;
    _movimientos.add(Movimiento(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descripcion: descripcion.isEmpty ? 'Inversión' : descripcion,
      monto: monto,
      fecha: DateTime.now(),
      esInversion: true,
    ));
    _notificarYGuardar();
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
    
    _guardarCarritos();
    _notificarYGuardar(); 
  }

  void aplicarDescuentoACarrito(String telefono, double valor, bool esPorcentaje) {
    if (_carritosActivos.containsKey(telefono)) {
      _carritosActivos[telefono]!.descuentoValor = valor;
      _carritosActivos[telefono]!.descuentoEsPorcentaje = esPorcentaje;
      
      _guardarCarritos();
      notifyListeners();
    }
  }

  void cobrarCarrito(String telefono) {
    if (!_carritosActivos.containsKey(telefono)) return;

    final carrito = _carritosActivos[telefono]!;
    final nuevaVenta = Venta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      telefonoCliente: carrito.telefonoCliente,
      articulos: List.from(carrito.articulos),
      descuentoAplicado: carrito.descuentoMonto,
      totalFinal: carrito.total,
      fecha: DateTime.now(),
    );

    _ventas.add(nuevaVenta);
    _dineroEnCaja += nuevaVenta.totalFinal;
    _carritosActivos.remove(telefono);
    
    _guardarCarritos();
    _notificarYGuardar();
  }

  void cancelarCarrito(String telefono) {
    if (!_carritosActivos.containsKey(telefono)) return;
    final carrito = _carritosActivos[telefono]!;
    
    for (var articulo in carrito.articulos) {
      final index = _productos.indexWhere((p) => p.id == articulo.productoId);
      if (index != -1) {
        _productos[index] = _productos[index].copyWith(
          cantidad: _productos[index].cantidad + articulo.cantidad
        );
      }
    }
    _carritosActivos.remove(telefono);
    
    _guardarCarritos();
    _notificarYGuardar();
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
    _notificarYGuardar();
  }

  Future<void> _cargarDesdeDisco() async {
    _productos = await _storage.cargarProductos();
    _ventas = await _storage.cargarVentas();
    _dineroEnCaja = await _storage.cargarCaja();
    _categorias = await _storage.cargarCategorias();
    _movimientos = await _storage.cargarMovimientos();

    final carritosRaw = await _storage.cargarCarritosActivos();
    _carritosActivos = carritosRaw.map((key, value) => MapEntry(key, Carrito.fromMap(value)));

    notifyListeners();
  }
}