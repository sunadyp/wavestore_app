import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../models/movimiento.dart'; 
import '../data/storage_service.dart';
import 'dart:math';

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
    _cargarDesdeDisco().then((_) {
      // DESCOMENTA LA SIGUIENTE LÍNEA UNA SOLA VEZ:
       sembrarDatosMaquillaje();
    });
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
      String label = "${DateFormat('dd MMM').format(inicioSemana)} -${DateFormat('dd MMM').format(finSemana)}";
      semanas.add({'id': id, 'label': label, 'inicio': inicioSemana, 'fin': finSemana});
    }
    return semanas;
  }

  List<Map<String, dynamic>> obtenerEstadisticasMensuales() {
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
      double gastoPorInventario = nuevo.costo * nuevo.cantidad;
      _dineroEnCaja -= gastoPorInventario;
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
        double gastoPorReabastecer = costoUnitarioEntrante * cantidadEntrante;
        _dineroEnCaja -= gastoPorReabastecer;
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

  void aplicarDescuentoACarrito(String identificador, double valor, bool esPorcentaje) {
    if (_carritosActivos.containsKey(identificador)) {
      _carritosActivos[identificador]!.descuentoValor = valor;
      _carritosActivos[identificador]!.descuentoEsPorcentaje = esPorcentaje;
      
      _guardarCarritos();
      notifyListeners();
    }
  }

  // <-- ACTUALIZADO: Ahora recibe el string con el concepto
  void aplicarCargoExtraACarrito(String identificador, double cargo, String concepto) {
    if (_carritosActivos.containsKey(identificador)) {
      _carritosActivos[identificador]!.cargoExtra = cargo;
      _carritosActivos[identificador]!.conceptoCargoExtra = concepto.isEmpty ? 'Cargo Extra' : concepto; // Por si lo dejan vacío
      
      _guardarCarritos();
      notifyListeners();
    }
  }

  void cobrarCarrito(String identificador) {
    if (!_carritosActivos.containsKey(identificador)) return;

    final carrito = _carritosActivos[identificador]!;
    final nuevaVenta = Venta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      telefonoCliente: carrito.telefonoCliente,
      articulos: List.from(carrito.articulos),
      descuentoAplicado: carrito.descuentoMonto,
      cargoExtra: carrito.cargoExtra, 
      conceptoCargoExtra: carrito.conceptoCargoExtra, // <-- SE GUARDA EL NOMBRE
      totalFinal: carrito.total,
      fecha: DateTime.now(),
    );

    _ventas.add(nuevaVenta);
    _dineroEnCaja += nuevaVenta.totalFinal;
    _carritosActivos.remove(identificador);
    
    _guardarCarritos();
    _notificarYGuardar();
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

  // =========================================================================
  // --- MÉTODOS DE PRUEBA Y SIMULACIÓN (SEMBRAR DATOS MASIVOS) ---
  // =========================================================================
  void sembrarDatosMaquillaje() {
    final random = Random();
    
    final fechaInicio = DateTime(2026, 1, 1);
    final fechaFin = DateTime(2026, 8, 7, 23, 59, 59);
    final diasTotales = fechaFin.difference(fechaInicio).inDays;

    _categorias = ['Rostro', 'Ojos', 'Labios', 'Skincare', 'Herramientas'];

    _productos = [
      Producto(id: 'p1', nombre: 'Sheglam Color Bloom Liquid Blush', categoria: 'Rostro', costo: 85.0, precioVenta: 180.0, cantidad: 25),
      Producto(id: 'p2', nombre: 'Elf Power Grip Primer', categoria: 'Rostro', costo: 160.0, precioVenta: 290.0, cantidad: 12),
      Producto(id: 'p3', nombre: 'Beauty Creations Flora Palette', categoria: 'Ojos', costo: 190.0, precioVenta: 350.0, cantidad: 8),
      Producto(id: 'p4', nombre: 'Sheglam Insta-Ready Face Powder', categoria: 'Rostro', costo: 110.0, precioVenta: 220.0, cantidad: 15),
      Producto(id: 'p5', nombre: 'Bissu Tintaline Negro', categoria: 'Ojos', costo: 45.0, precioVenta: 90.0, cantidad: 30),
      Producto(id: 'p6', nombre: 'Elf Halo Glow Liquid Filter', categoria: 'Rostro', costo: 280.0, precioVenta: 450.0, cantidad: 10),
      Producto(id: 'p7', nombre: 'Beauty Creations Plump & Pout Gloss', categoria: 'Labios', costo: 75.0, precioVenta: 150.0, cantidad: 20),
      Producto(id: 'p8', nombre: 'Set Brochas Neon Beauty Creations', categoria: 'Herramientas', costo: 250.0, precioVenta: 480.0, cantidad: 5),
      Producto(id: 'p9', nombre: 'Esponja Blender Sheglam', categoria: 'Herramientas', costo: 35.0, precioVenta: 80.0, cantidad: 40),
      Producto(id: 'p10', nombre: 'Good Molecules Niacinamide Toner', categoria: 'Skincare', costo: 180.0, precioVenta: 360.0, cantidad: 18),
    ];

    _ventas = [];
    double ingresosTotalesVentas = 0;
    List<String> telefonosClientes = ['@paola_makeup', '8331112233', 'Maria Gonzalez', '8334445566', '@beauty_fan']; 

    for (int i = 0; i < 220; i++) {
      final diasRandom = random.nextInt(diasTotales > 0 ? diasTotales : 1);
      final horaRandom = random.nextInt(10) + 9; 
      final minRandom = random.nextInt(60);
      
      DateTime fechaVenta = fechaInicio.add(Duration(days: diasRandom));
      fechaVenta = DateTime(fechaVenta.year, fechaVenta.month, fechaVenta.day, horaRandom, minRandom);
      
      if (fechaVenta.isAfter(fechaFin)) fechaVenta = fechaFin;

      int numArticulos = random.nextInt(3) + 1;
      List<ArticuloVenta> articulosVenta = [];
      double subtotalVenta = 0;
      
      List<Producto> poolProductos = List.from(_productos)..shuffle(random);
      
      for (int j = 0; j < numArticulos; j++) {
        Producto p = poolProductos[j];
        int cantComprada = random.nextInt(2) + 1;
        
        articulosVenta.add(ArticuloVenta(
          productoId: p.id,
          productoNombre: p.nombre,
          cantidad: cantComprada,
          precioUnitario: p.precioVenta,
        ));
        subtotalVenta += (cantComprada * p.precioVenta);
      }

      double descuento = random.nextDouble() > 0.90 ? (random.nextBool() ? 20.0 : 50.0) : 0.0;
      double cargoExtra = random.nextDouble() > 0.80 ? 60.0 : 0.0; 
      
      // <-- NUEVO: Generando nombres aleatorios para el cargo extra en la siembra
      String conceptoCargoExtra = cargoExtra > 0 ? (random.nextBool() ? 'Costo de envío' : 'Envoltura de regalo') : 'Cargo Extra';

      double totalFinal = (subtotalVenta - descuento) + cargoExtra;
      if (totalFinal < 0) totalFinal = 0;
      
      ingresosTotalesVentas += totalFinal;

      _ventas.add(Venta(
        id: 'v_prod_$i',
        telefonoCliente: telefonosClientes[random.nextInt(telefonosClientes.length)],
        articulos: articulosVenta,
        descuentoAplicado: descuento,
        cargoExtra: cargoExtra, 
        conceptoCargoExtra: conceptoCargoExtra, // <-- SE REGISTRA
        totalFinal: totalFinal,
        fecha: fechaVenta,
      ));
    }

    _ventas.sort((a, b) => a.fecha.compareTo(b.fecha));

    _movimientos = [];
    double egresosTotalesGastos = 0;

    _movimientos.add(Movimiento(
      id: 'm_inicial',
      descripcion: 'Capital Inicial de Caja (Enero)',
      monto: 15000.0,
      fecha: DateTime(2026, 1, 1, 10, 0),
      esInversion: true,
    ));

    List<String> tiposDeGastos = [
      'Restock mayorista Beauty Creations',
      'Insumos de empaque, bolsas y stickers',
      'Importación de cosméticos Elf y Sheglam',
      'Publicidad en Meta Ads (Instagram/FB)',
      'Cosméticos Bissú al mayoreo'
    ];

    for (int mes = 1; mes <= 8; mes++) {
      int gastosPorMes = (mes == 8) ? 1 : 2; 
      
      for (int g = 0; g < gastosPorMes; g++) {
        double montoGasto = 500.0 + random.nextInt(2500);
        egresosTotalesGastos += montoGasto;
        
        _movimientos.add(Movimiento(
          id: 'm_gasto_${mes}_$g',
          descripcion: tiposDeGastos[random.nextInt(tiposDeGastos.length)],
          monto: montoGasto,
          fecha: DateTime(2026, mes, random.nextInt(6) + 1, 12, 0),
          esInversion: false,
        ));
      }
    }

    _dineroEnCaja = 15000.0 + ingresosTotalesVentas - egresosTotalesGastos;
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