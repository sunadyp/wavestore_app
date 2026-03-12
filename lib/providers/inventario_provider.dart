import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../data/storage_service.dart';

class InventarioProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Venta> _ventas = [];
  double _dineroEnCaja = 0.0;
  String _filtro = '';
  
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
  double get dineroEnCaja => _dineroEnCaja;
  
  double get capitalInvertido => _productos.fold(0, (sum, item) => sum + (item.costo * item.cantidad));
  double get dineroPosible => _productos.fold(0, (sum, item) => sum + (item.precioVenta * item.cantidad));
  double get gananciaPotencial => dineroPosible - capitalInvertido;

  // --- LÓGICA DE FILTRADO POR SEMANAS ---

  /// Filtra ventas por un rango exacto
  List<Venta> obtenerVentasPorRango(DateTime inicio, DateTime fin) {
    final inicioDia = DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0);
    final finDelDia = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);
    return _ventas.where((v) => v.fecha.isAfter(inicioDia) && v.fecha.isBefore(finDelDia)).toList();
  }

  /// Genera las semanas del mes actual (Estén vacías o no)
  List<Map<String, dynamic>> obtenerSemanasMesActual() {
    List<Map<String, dynamic>> semanas = [];
    DateTime ahora = DateTime.now();
    
    // 1. Buscamos el primer día del mes
    DateTime primeroMes = DateTime(ahora.year, ahora.month, 1);
    
    // 2. Retrocedemos al Lunes de esa primera semana
    DateTime lunes = primeroMes.subtract(Duration(days: primeroMes.weekday - 1));

    // 3. Generamos 5 semanas (suficiente para cubrir cualquier mes)
    for (int i = 0; i < 6; i++) {
      DateTime inicioSemana = lunes.add(Duration(days: i * 7));
      DateTime finSemana = inicioSemana.add(const Duration(days: 6));
      
      // Creamos un ID único de texto para que el Dropdown no falle
      String id = "${inicioSemana.day}-${inicioSemana.month}-${inicioSemana.year}";
      String label = "${DateFormat('dd MMM').format(inicioSemana)} - ${DateFormat('dd MMM').format(finSemana)}";

      semanas.add({
        'id': id, 
        'label': label,
        'inicio': inicioSemana,
        'fin': finSemana,
      });
    }
    return semanas;
  }

  // --- ACCIONES ---
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

      _productos[index] = prod.copyWith(cantidad: prod.cantidad - cantidadVendida);
      _ventas.add(nuevaVenta);
      _dineroEnCaja += nuevaVenta.total;
      _notificarYGuardar();
    }
  }

  Future<void> _cargarDesdeDisco() async {
    _productos = await _storage.cargarProductos();
    _ventas = await _storage.cargarVentas();
    _dineroEnCaja = await _storage.cargarCaja();
    notifyListeners();
  }
}