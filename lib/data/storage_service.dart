import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../models/movimiento.dart';
import '../models/actividad.dart'; // <-- NUEVO IMPORT

String _encodeData(dynamic data) => json.encode(data);
dynamic _decodeData(String data) => json.decode(data);

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

  // --- GUARDADOS ---
  Future<void> guardarProductos(List<Producto> productos) async {
    final prefs = await SharedPreferences.getInstance();
    final mapList = productos.map((p) => p.toMap()).toList();
    final String data = await compute(_encodeData, mapList);
    await prefs.setString('inventario_key', data);
  }

  Future<void> guardarVentas(List<Venta> ventas) async {
    final prefs = await SharedPreferences.getInstance();
    final mapList = ventas.map((v) => v.toMap()).toList();
    final String data = await compute(_encodeData, mapList);
    await prefs.setString('ventas_key', data);
  }

  Future<void> guardarMovimientos(List<Movimiento> movimientos) async {
    final prefs = await SharedPreferences.getInstance();
    final mapList = movimientos.map((m) => m.toMap()).toList();
    final String data = await compute(_encodeData, mapList);
    await prefs.setString('movimientos_key', data);
  }

  // <-- NUEVO: Guardar la bitácora de actividades
  Future<void> guardarActividades(List<Actividad> actividades) async {
    final prefs = await SharedPreferences.getInstance();
    final mapList = actividades.map((a) => a.toMap()).toList();
    final String data = await compute(_encodeData, mapList);
    await prefs.setString('actividades_key', data);
  }

  Future<void> guardarCaja(double caja) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('caja_key', caja);
  }

  Future<void> guardarCategorias(List<String> categorias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categorias_key', categorias);
  }

  Future<void> guardarCarritosActivos(Map<String, dynamic> carritos) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = await compute(_encodeData, carritos);
    await prefs.setString('carritos_key', data);
  }

  Future<void> guardarTodo({
    required List<Producto> productos,
    required List<Venta> ventas,
    required double caja,
    required List<String> categorias,
    required List<Movimiento> movimientos,
    required List<Actividad> actividades, // <-- NUEVO
  }) async {
    await Future.wait([
      guardarProductos(productos),
      guardarVentas(ventas),
      guardarCaja(caja),
      guardarCategorias(categorias),
      guardarMovimientos(movimientos),
      guardarActividades(actividades), // <-- NUEVO
    ]);
  }

  // --- CARGAS ---
  Future<List<Producto>> cargarProductos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('inventario_key');
    if (data == null) return [];
    final decoded = await compute(_decodeData, data) as List;
    return decoded.map((i) => Producto.fromMap(i)).toList();
  }

  Future<List<Venta>> cargarVentas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('ventas_key');
    if (data == null) return [];
    final decoded = await compute(_decodeData, data) as List;
    return decoded.map((i) => Venta.fromMap(i)).toList();
  }

  Future<List<Movimiento>> cargarMovimientos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('movimientos_key');
    if (data == null) return [];
    final decoded = await compute(_decodeData, data) as List;
    return decoded.map((i) => Movimiento.fromMap(i)).toList();
  }

  // <-- NUEVO: Cargar la bitácora de actividades
  Future<List<Actividad>> cargarActividades() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('actividades_key');
    if (data == null) return [];
    final decoded = await compute(_decodeData, data) as List;
    return decoded.map((i) => Actividad.fromMap(i)).toList();
  }

  Future<Map<String, dynamic>> cargarCarritosActivos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('carritos_key');
    if (data == null) return {};
    return await compute(_decodeData, data) as Map<String, dynamic>;
  }

  Future<double> cargarCaja() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('caja_key') ?? 0.0;
  }

  Future<List<String>> cargarCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('categorias_key') ?? ['General'];
  }
}