part of '../inventario_provider.dart';

extension EstadisticasExtension on InventarioProvider {
  // --- BUSINESS INSIGHTS ---
  double get ticketPromedio {
    if (_ventas.isEmpty) return 0.0;
    // 🚀 CAMBIO: Ahora suma el ingreso neto
    final totalIngresos = _ventas.fold(0.0, (sum, v) => sum + v.ingresoNeto);
    return totalIngresos / _ventas.length;
  }

  double get capitalInvertido => _productos.fold(0, (sum, item) => sum + (item.costo * item.cantidad));
  double get dineroPosible => _productos.fold(0, (sum, item) => sum + (item.precioVenta * item.cantidad));
  double get gananciaPotencial => dineroPosible - capitalInvertido;

  Map<String, dynamic>? get productoMasVendido {
    if (_ventas.isEmpty) return null;
    
    final conteoVentas = <String, int>{};
    final nombres = <String, String>{};

    for (var venta in _ventas) {
      for (var art in venta.articulos) {
        conteoVentas[art.productoId] = (conteoVentas[art.productoId] ?? 0) + art.cantidad;
        nombres[art.productoId] = art.productoNombre;
      }
    }

    if (conteoVentas.isEmpty) return null;
    final idMasVendido = conteoVentas.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    return {
      'nombre': nombres[idMasVendido],
      'cantidad': conteoVentas[idMasVendido],
    };
  }

  Map<String, dynamic>? get productoMayorIngreso {
    if (_ventas.isEmpty) return null;
    
    final ingresosPorProducto = <String, double>{};
    final nombres = <String, String>{};

    for (var venta in _ventas) {
      for (var art in venta.articulos) {
        ingresosPorProducto[art.productoId] = (ingresosPorProducto[art.productoId] ?? 0.0) + art.subtotal;
        nombres[art.productoId] = art.productoNombre;
      }
    }

    if (ingresosPorProducto.isEmpty) return null;
    final idMayorIngreso = ingresosPorProducto.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    return {
      'nombre': nombres[idMayorIngreso],
      'ingreso': ingresosPorProducto[idMayorIngreso],
    };
  }

  List<Producto> get productosPorAgotarse {
    final casiAgotados = _productos.where((p) => p.cantidad > 0 && p.cantidad <= 3).toList();
    casiAgotados.sort((a, b) => a.cantidad.compareTo(b.cantidad));
    return casiAgotados.take(4).toList(); 
  }

  double get promedioMensual {
    final stats = obtenerEstadisticasMensuales();
    if (stats.isEmpty) return 0.0;
    double totalGanancia = stats.fold(0.0, (sum, item) => sum + item['ganancia']);
    return totalGanancia / stats.length;
  }

  double get gananciaMesActual {
    final ahora = DateTime.now();
    final mesActual = "${ahora.year}-${ahora.month.toString().padLeft(2, '0')}";
    final stats = obtenerEstadisticasMensuales();
    
    final actual = stats.where((s) => s['mes_anio'] == mesActual).toList();
    if (actual.isEmpty) return 0.0;
    return actual.first['ganancia'];
  }

  List<Venta> obtenerVentasPorRango(DateTime inicio, DateTime fin) {
    final inicioDia = DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0);
    final finDelDia = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);
    return _ventas.where((v) => v.fecha.isAfter(inicioDia) && v.fecha.isBefore(finDelDia)).toList();
  }

  List<Map<String, dynamic>> obtenerSemanasMesActual() {
    List<Map<String, dynamic>> semanas = [];
    DateTime ahora = DateTime.now();
    DateTime primeroMes = DateTime(ahora.year, ahora.month, 1);
    DateTime lunes = primeroMes.subtract(Duration(days: primeroMes.weekday - 1));

    for (int i = 0; i < 6; i++) {
      DateTime inicioSemana = lunes.add(Duration(days: i * 7));
      DateTime finSemana = inicioSemana.add(const Duration(days: 6));
      String id = "${inicioSemana.day}-${inicioSemana.month}-${inicioSemana.year}";
      String label = "${DateFormat('dd MMM').format(inicioSemana)} -${DateFormat('dd MMM').format(finSemana)}";
      semanas.add({'id': id, 'label': label, 'inicio': inicioSemana, 'fin': finSemana});
    }
    return semanas;
  }

  List<Map<String, dynamic>> obtenerEstadisticasMensuales() {
    if (!_estadisticasDesactualizadas) return _cacheEstadisticas;
    Map<String, Map<String, dynamic>> stats = {};

    for (var v in _ventas) {
      String mes = "${v.fecha.year}-${v.fecha.month.toString().padLeft(2, '0')}";
      if (!stats.containsKey(mes)) {
        stats[mes] = {'ingresos': 0.0, 'gastos': 0.0, 'fecha': DateTime(v.fecha.year, v.fecha.month)};
      }
      // 🚀 CAMBIO: Ahora la gráfica lee el ingreso real
      stats[mes]!['ingresos'] += v.ingresoNeto; 
    }

    for (var m in _movimientos) {
      if (!m.esInversion) {
        String mes = "${m.fecha.year}-${m.fecha.month.toString().padLeft(2, '0')}";
        if (!stats.containsKey(mes)) {
          stats[mes] = {'ingresos': 0.0, 'gastos': 0.0, 'fecha': DateTime(m.fecha.year, m.fecha.month)};
        }
        stats[mes]!['gastos'] += m.monto;
      }
    }

    List<Map<String, dynamic>> listaStats = stats.entries.map((e) {
      double ingresos = e.value['ingresos'];
      double gastos = e.value['gastos'];
      double ganancia = ingresos - gastos;
      return {
        'mes_anio': e.key,
        'fecha': e.value['fecha'],
        'ingresos': ingresos,
        'gastos': gastos,
        'ganancia': ganancia,
      };
    }).toList();

    listaStats.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
    
    _cacheEstadisticas = listaStats;
    _estadisticasDesactualizadas = false;
    
    return _cacheEstadisticas;
  }
}