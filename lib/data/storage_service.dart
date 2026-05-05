import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../models/movimiento.dart';

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

// Modifica guardarTodo para incluir movimientos
  Future<void> guardarTodo({
    required List<Producto> productos,
    required List<Venta> ventas,
    required double caja,
    required List<String> categorias,
    required List<Movimiento> movimientos, // <-- NUEVO
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inventario_key', json.encode(productos.map((p) => p.toMap()).toList()));
    await prefs.setString('ventas_key', json.encode(ventas.map((v) => v.toMap()).toList()));
    await prefs.setDouble('caja_key', caja);
    await prefs.setStringList('categorias_key', categorias);
    
    // <-- NUEVO: Guardar los movimientos
    await prefs.setString('movimientos_key', json.encode(movimientos.map((m) => m.toMap()).toList())); 
  }

  // NUEVO METODO: Cargar movimientos
  Future<List<Movimiento>> cargarMovimientos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('movimientos_key');
    if (data == null) return [];
    return (json.decode(data) as List).map((i) => Movimiento.fromMap(i)).toList();
  }

  // NUEVO: Guardar los apartados/cuentas activas
  Future<void> guardarCarritosActivos(Map<String, dynamic> carritos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('carritos_key', json.encode(carritos));
  }

  // NUEVO: Cargar los apartados/cuentas activas
  Future<Map<String, dynamic>> cargarCarritosActivos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('carritos_key');
    if (data == null) return {};
    return json.decode(data) as Map<String, dynamic>;
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

  // NUEVO: Cargar categorías guardadas
  Future<List<String>> cargarCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('categorias_key') ?? ['General'];
  }
}