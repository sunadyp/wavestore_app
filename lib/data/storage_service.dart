import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';
import '../models/venta.dart';

class StorageService {
  static Future<bool> isPrimeraVez() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('primera_vez') ?? true;
  }

  static Future<void> setPrimeraVezCompletada() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('primera_vez', false);
  }

  static Future<void> guardarSaldoInicial(double saldo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('caja_key', saldo);
  }

  // ACTUALIZADO: Ahora recibe y guarda categorías[cite: 1]
  Future<void> guardarTodo({
    required List<Producto> productos,
    required List<Venta> ventas,
    required double caja,
    required List<String> categorias,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inventario_key', json.encode(productos.map((p) => p.toMap()).toList()));
    await prefs.setString('ventas_key', json.encode(ventas.map((v) => v.toMap()).toList()));
    await prefs.setDouble('caja_key', caja);
    await prefs.setStringList('categorias_key', categorias); // <-- GUARDAR LISTA
  }

  Future<List<Producto>> cargarProductos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('inventario_key');
    if (data == null) return [];
    return (json.decode(data) as List).map((i) => Producto.fromMap(i)).toList();
  }

  Future<List<Venta>> cargarVentas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('ventas_key');
    if (data == null) return [];
    return (json.decode(data) as List).map((i) => Venta.fromMap(i)).toList();
  }

  Future<double> cargarCaja() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('caja_key') ?? 0.0;
  }

  // NUEVO: Cargar categorías guardadas[cite: 1]
  Future<List<String>> cargarCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('categorias_key') ?? ['General'];
  }
}