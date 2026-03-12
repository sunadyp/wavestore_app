import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';
import '../models/venta.dart'; // Solo asegúrate de tener este modelo creado

class InventarioProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Venta> _ventas = []; // <-- Cambio 1: Lista para el historial
  double _dineroEnCaja = 0.0;
  String _filtro = '';

  InventarioProvider() {
    _cargarDatos();
  }

  List<Producto> get productos {
    if (_filtro.isEmpty) return _productos;
    return _productos.where((p) => p.nombre.toLowerCase().contains(_filtro.toLowerCase())).toList();
  }

  List<Venta> get ventas => _ventas;

  double get dineroEnCaja => _dineroEnCaja;
  double get capitalInvertido => _productos.fold(0, (sum, item) => sum + (item.costo * item.cantidad));
  double get dineroPosible => _productos.fold(0, (sum, item) => sum + (item.precioVenta * item.cantidad));
  double get gananciaPotencial => dineroPosible - capitalInvertido;

  // <-- Cambio 2: Getter para que el Dashboard no marque error
  double get ventasSemana {
    final sieteDiasAtras = DateTime.now().subtract(const Duration(days: 7));
    return _ventas
        .where((v) => v.fecha.isAfter(sieteDiasAtras))
        .fold(0.0, (sum, v) => sum + v.total);
  }

  void filtrar(String texto) {
    _filtro = texto;
    notifyListeners();
  }

  void agregarProducto(Producto nuevoProducto) {
    _productos.add(nuevoProducto);
    _guardarDatos();
    notifyListeners(); 
  }

  void editarProducto(String id, Producto productoEditado) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      _productos[index] = productoEditado;
      _guardarDatos();
      notifyListeners();
    }
  }

  void eliminarProducto(String id) {
    _productos.removeWhere((p) => p.id == id);
    _guardarDatos();
    notifyListeners();
  }

  void registrarVenta(String id, int cantidadVendida) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1 && _productos[index].cantidad >= cantidadVendida && cantidadVendida > 0) {
      final prod = _productos[index];
      
      // <-- Cambio 3: Crear el registro de venta para el historial
      final nuevaVenta = Venta(
        id: DateTime.now().toString(),
        productoNombre: prod.nombre,
        cantidad: cantidadVendida,
        total: prod.precioVenta * cantidadVendida,
        fecha: DateTime.now(),
      );

      _productos[index] = Producto(
        id: prod.id, nombre: prod.nombre, costo: prod.costo, 
        precioVenta: prod.precioVenta, cantidad: prod.cantidad - cantidadVendida
      );
      
      _ventas.add(nuevaVenta); // Guardamos en la lista
      _dineroEnCaja += nuevaVenta.total;
      _guardarDatos();
      notifyListeners();
    }
  }

  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_productos.map((p) => p.toMap()).toList());
    await prefs.setString('inventario_wave_store', jsonString);
    // <-- Cambio 4: Guardar también las ventas
    final String ventasString = jsonEncode(_ventas.map((v) => v.toMap()).toList());
    await prefs.setString('ventas_wave_store', ventasString);
    await prefs.setDouble('caja_wave_store', _dineroEnCaja);
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    _dineroEnCaja = prefs.getDouble('caja_wave_store') ?? 0.0;

    final String? jsonString = prefs.getString('inventario_wave_store');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _productos = jsonList.map((item) => Producto.fromMap(item)).toList();
    }

    // <-- Cambio 5: Cargar las ventas al iniciar
    final String? ventasString = prefs.getString('ventas_wave_store');
    if (ventasString != null) {
      final List<dynamic> vList = jsonDecode(ventasString);
      _ventas = vList.map((item) => Venta.fromMap(item)).toList();
    }
    notifyListeners();
  }
}