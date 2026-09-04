part of '../inventario_provider.dart';

extension BitacoraExtension on InventarioProvider {
  // ==========================================================
  // --- MOTOR DE AUDITORÍA (BITÁCORA) ---
  // ==========================================================
  void registrarActividad(String descripcion) {
    _actividades.insert(0, Actividad(
      id: _uuid.v4(),
      descripcion: descripcion,
      fecha: DateTime.now(),
    ));

    // Mantenemos solo los últimos 1000 registros para cuidar la RAM
    if (_actividades.length > 1000) {
      _actividades = _actividades.sublist(0, 1000);
    }

    _storage.guardarActividades(_actividades);
    notifyListeners(); 
  }

  void limpiarBitacora() {
    _actividades.clear();
    _storage.guardarActividades(_actividades);
    notifyListeners();
  }

  void filtrar(String texto) {
    _filtro = texto;
    notifyListeners();
  }

  void agregarCategoria(String nombre) {
    if (nombre.isNotEmpty && !_categorias.contains(nombre)) {
      _categorias.add(nombre);
      registrarActividad('Agregó la categoría "$nombre"'); 
      notifyListeners();
      _storage.guardarCategorias(_categorias);
    }
  }

  void agregarSaldoInicial(double saldo) {
    _dineroEnCaja = saldo;
    _estadisticasDesactualizadas = true;
    registrarActividad('Configuró el saldo inicial en \$${saldo.toStringAsFixed(2)}');
    notifyListeners();
    _storage.guardarCaja(_dineroEnCaja);
  }

  void registrarGasto(double monto, String descripcion) {
    _dineroEnCaja -= monto;
    final nombreDesc = descripcion.isEmpty ? 'Gasto general' : descripcion;
    _movimientos.add(Movimiento(
      id: _uuid.v4(),
      descripcion: nombreDesc,
      monto: monto,
      fecha: DateTime.now(),
      esInversion: false,
    ));
    
    registrarActividad('Registró un gasto de \$${monto.toStringAsFixed(2)} por "$nombreDesc"'); 

    _estadisticasDesactualizadas = true;
    notifyListeners();
    _storage.guardarCaja(_dineroEnCaja);
    _storage.guardarMovimientos(_movimientos);
  }

  void registrarInversion(double monto, String descripcion) {
    _dineroEnCaja += monto;
    final nombreDesc = descripcion.isEmpty ? 'Inversión' : descripcion;
    _movimientos.add(Movimiento(
      id: _uuid.v4(),
      descripcion: nombreDesc,
      monto: monto,
      fecha: DateTime.now(),
      esInversion: true,
    ));
    
    registrarActividad('Registró un ingreso/inversión de \$${monto.toStringAsFixed(2)} por "$nombreDesc"'); 

    _estadisticasDesactualizadas = true;
    notifyListeners();
    _storage.guardarCaja(_dineroEnCaja);
    _storage.guardarMovimientos(_movimientos);
  }
}