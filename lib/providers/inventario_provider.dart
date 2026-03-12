import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../data/storage_service.dart';

class InventarioProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Venta> _ventas = [];
  double _dineroEnCaja = 0.0;
  String _filtro = '';
  
  // Instancia del servicio de almacenamiento
  final StorageService _storage = StorageService();

  InventarioProvider() {
    _cargarDesdeDisco();
  }

  // GETTERS
  List<Producto> get productos {
    if (_filtro.isEmpty) return _productos;
    return _productos.where((p) => p.nombre.toLowerCase().contains(_filtro.toLowerCase())).toList();
  }
  List<Venta> get ventas => _ventas;
  double get dineroEnCaja => _dineroEnCaja;
  
  // FINANZAS (Lógica de negocio pura)
  double get capitalInvertido => _productos.fold(0, (sum, item) => sum + (item.costo * item.cantidad));
  double get dineroPosible => _productos.fold(0, (sum, item) => sum + (item.precioVenta * item.cantidad));
  double get gananciaPotencial => dineroPosible - capitalInvertido;

  double get ventasSemana {
    final sieteDiasAtras = DateTime.now().subtract(const Duration(days: 7));
    return _ventas
        .where((v) => v.fecha.isAfter(sieteDiasAtras))
        .fold(0.0, (sum, v) => sum + v.total);
  }

  // ACCIONES
  void filtrar(String texto) {
    _filtro = texto;
    notifyListeners();
  }

  void _notificarYGuardar() {
    notifyListeners();
    _storage.guardarTodo(
      productos: _productos,
      ventas: _ventas,
      caja: _dineroEnCaja,
    );
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

  void registrarVenta(String id, int cantidadVendida) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1 && _productos[index].cantidad >= cantidadVendida) {
      final prod = _productos[index];
      
      final nuevaVenta = Venta(
        id: DateTime.now().toString(),
        productoNombre: prod.nombre,
        cantidad: cantidadVendida,
        total: prod.precioVenta * cantidadVendida,
        fecha: DateTime.now(),
      );

      // Usamos copyWith del modelo (que agregamos antes)
      _productos[index] = prod.copyWith(cantidad: prod.cantidad - cantidadVendida);
      
      _ventas.add(nuevaVenta);
      _dineroEnCaja += nuevaVenta.total;
      _notificarYGuardar();
    }
  }

  // CARGA INICIAL
  Future<void> _cargarDesdeDisco() async {
    _productos = await _storage.cargarProductos();
    _ventas = await _storage.cargarVentas();
    _dineroEnCaja = await _storage.cargarCaja();
    notifyListeners();
  }
}