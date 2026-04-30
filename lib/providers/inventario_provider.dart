import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../data/storage_service.dart';

class InventarioProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Venta> _ventas = [];
  List<String> _categorias = ['General']; // <-- Nueva lista de categorías dinámicas[cite: 1]
  double _dineroEnCaja = 0.0;
  String _filtro = '';
  
  // Diccionario para manejar los carritos activos. La llave es el teléfono.
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
  List<String> get categorias => _categorias; // <-- Getter para las categorías[cite: 1]
  double get dineroEnCaja => _dineroEnCaja;
  Map<String, Carrito> get carritosActivos => _carritosActivos;

  double get capitalInvertido => _productos.fold(0, (sum, item) => sum + (item.costo * item.cantidad));
  double get dineroPosible => _productos.fold(0, (sum, item) => sum + (item.precioVenta * item.cantidad));
  double get gananciaPotencial => dineroPosible - capitalInvertido;

  // --- LÓGICA DE FILTRADO Y SEMANAS ---
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

  // --- ACCIONES DE INVENTARIO Y CATEGORÍAS ---
  void filtrar(String texto) {
    _filtro = texto;
    notifyListeners();
  }

  // Método para agregar categorías dinámicamente[cite: 1]
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
      categorias: _categorias, // <-- Ahora persistimos las categorías[cite: 1]
    );
  }

  void agregarSaldoInicial(double saldo) {
    _dineroEnCaja = saldo;
    _notificarYGuardar();
  }

  void agregarProducto(Producto nuevo) {
    _productos.add(nuevo);
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

  void reabastecerProducto(String id, int cantidadEntrante, double costoUnitarioEntrante) {
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
      _notificarYGuardar();
    }
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
    notifyListeners();
  }

  void aplicarDescuentoACarrito(String telefono, double valor, bool esPorcentaje) {
    if (_carritosActivos.containsKey(telefono)) {
      _carritosActivos[telefono]!.descuentoValor = valor;
      _carritosActivos[telefono]!.descuentoEsPorcentaje = esPorcentaje;
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
    notifyListeners();
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
    _categorias = await _storage.cargarCategorias(); // <-- Carga las categorías guardadas[cite: 1]
    notifyListeners();
  }
}