part of '../inventario_provider.dart';

extension BitacoraExtension on InventarioProvider {
  
  Future<void> registrarActividad(String descripcion) async {
    _actividades.insert(0, Actividad(
      id: _uuid.v4(),
      descripcion: descripcion,
      fecha: DateTime.now(),
    ));

    if (_actividades.length > 1000) {
      _actividades = _actividades.sublist(0, 1000);
    }

    await _storage.guardarActividades(_actividades);
    notifyListeners(); 
  }

  Future<void> limpiarBitacora() async {
    _actividades.clear();
    await _storage.guardarActividades(_actividades);
    notifyListeners();
  }

  void filtrar(String texto) {
    _filtro = texto;
    notifyListeners();
  }

  Future<void> agregarCategoria(String nombre) async {
    if (nombre.isNotEmpty && !_categorias.contains(nombre)) {
      _categorias.add(nombre);
      await registrarActividad('Agregó la categoría "$nombre"'); 
      await _storage.guardarCategorias(_categorias);
      notifyListeners();
    }
  }

  Future<void> agregarSaldoInicial(double saldo) async {
    _dineroEnCaja = saldo;
    _estadisticasDesactualizadas = true;
    await registrarActividad('Configuró el saldo inicial en \$${saldo.toStringAsFixed(2)}');
    await _storage.guardarCaja(_dineroEnCaja);
    notifyListeners();
  }

  Future<void> registrarGasto(double monto, String descripcion) async {
    _dineroEnCaja -= monto;
    final nombreDesc = descripcion.isEmpty ? 'Gasto general' : descripcion;
    _movimientos.add(Movimiento(
      id: _uuid.v4(),
      descripcion: nombreDesc,
      monto: monto,
      fecha: DateTime.now(),
      esInversion: false,
    ));
    
    await registrarActividad('Registró un gasto de \$${monto.toStringAsFixed(2)} por "$nombreDesc"'); 
    await _storage.guardarCaja(_dineroEnCaja);
    await _storage.guardarMovimientos(_movimientos);

    _estadisticasDesactualizadas = true;
    notifyListeners();
  }

  Future<void> registrarInversion(double monto, String descripcion) async {
    _dineroEnCaja += monto;
    final nombreDesc = descripcion.isEmpty ? 'Inversión' : descripcion;
    _movimientos.add(Movimiento(
      id: _uuid.v4(),
      descripcion: nombreDesc,
      monto: monto,
      fecha: DateTime.now(),
      esInversion: true,
    ));
    
    await registrarActividad('Registró un ingreso/inversión de \$${monto.toStringAsFixed(2)} por "$nombreDesc"'); 
    await _storage.guardarCaja(_dineroEnCaja);
    await _storage.guardarMovimientos(_movimientos);

    _estadisticasDesactualizadas = true;
    notifyListeners();
  }
}