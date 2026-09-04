import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; 
import '../models/producto.dart';
import '../models/venta.dart';
import '../models/movimiento.dart'; 
import '../models/actividad.dart'; 
import '../data/storage_service.dart';

// 🚀 MAGIA: Le decimos a Dart que los métodos están en estos otros archivos
part 'extensions/estadisticas_extension.dart';
part 'extensions/bitacora_extension.dart';
part 'extensions/productos_extension.dart';
part 'extensions/carritos_extension.dart';

class InventarioProvider extends ChangeNotifier {
  // --- VARIABLES DE ESTADO ---
  List<Producto> _productos = [];
  List<Venta> _ventas = [];
  List<String> _categorias = ['General'];
  List<Movimiento> _movimientos = []; 
  List<Actividad> _actividades = []; 

  double _dineroEnCaja = 0.0;
  String _filtro = '';
  
  Map<String, Carrito> _carritosActivos = {};
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  List<Map<String, dynamic>> _cacheEstadisticas = [];
  bool _estadisticasDesactualizadas = true;

  // --- GETTERS PRINCIPALES ---
  List<Producto> get productos {
    if (_filtro.isEmpty) return _productos;

    // 1. Limpiamos espacios extra y dividimos lo que el usuario escribió en palabras sueltas
    final terminosBusqueda = _filtro.toLowerCase().trim().split(' ');

    return _productos.where((p) {
      final nombreLower = p.nombre.toLowerCase();
      
      // 2. Verificamos que CADA palabra que escribiste coincida con el inicio del nombre 
      // o con el inicio de alguna palabra dentro del nombre (que haya un espacio antes)
      return terminosBusqueda.every((termino) => 
        nombreLower.startsWith(termino) || nombreLower.contains(' $termino')
      );
    }).toList();
  }
  List<Venta> get ventas => _ventas;
  List<String> get categorias => _categorias;
  List<Movimiento> get movimientos => _movimientos; 
  List<Actividad> get actividades => _actividades; 
  double get dineroEnCaja => _dineroEnCaja;
  Map<String, Carrito> get carritosActivos => _carritosActivos;

  // --- CONSTRUCTOR Y CARGA INICIAL ---
  InventarioProvider() {
    _cargarDesdeDisco();
  }

  Future<void> _cargarDesdeDisco() async {
    _productos = await _storage.cargarProductos();
    _ventas = await _storage.cargarVentas();
    _dineroEnCaja = await _storage.cargarCaja();
    _categorias = await _storage.cargarCategorias();
    _movimientos = await _storage.cargarMovimientos();
    _actividades = await _storage.cargarActividades();

    final carritosRaw = await _storage.cargarCarritosActivos();
    _carritosActivos = carritosRaw.map((key, value) => MapEntry(key, Carrito.fromMap(value)));

    _estadisticasDesactualizadas = true;
    notifyListeners();
  }
}