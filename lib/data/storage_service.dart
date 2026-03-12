import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';
import '../models/venta.dart';

class StorageService {
  // Guardar todo
  Future<void> guardarTodo({
    required List<Producto> productos,
    required List<Venta> ventas,
    required double caja,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inventario_key', json.encode(productos.map((p) => p.toMap()).toList()));
    await prefs.setString('ventas_key', json.encode(ventas.map((v) => v.toMap()).toList()));
    await prefs.setDouble('caja_key', caja);
  }

  // Cargar Productos
  Future<List<Producto>> cargarProductos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('inventario_key');
    if (data == null) return [];
    return (json.decode(data) as List).map((i) => Producto.fromMap(i)).toList();
  }

  // Cargar Ventas
  Future<List<Venta>> cargarVentas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('ventas_key');
    if (data == null) return [];
    return (json.decode(data) as List).map((i) => Venta.fromMap(i)).toList();
  }

  // Cargar Caja
  Future<double> cargarCaja() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('caja_key') ?? 0.0;
  }
}