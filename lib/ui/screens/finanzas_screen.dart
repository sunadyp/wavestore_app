import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/resumen_balance_card.dart';
import '../widgets/tarjeta_venta_historial.dart';
import '../widgets/ventas_chart.dart';
import '../widgets/lista_historial_movimientos.dart'; // <-- NUEVO IMPORT

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  String? _semanaSeleccionadaId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final tema = Theme.of(context).colorScheme;
    
    final semanasDisponibles = provider.obtenerSemanasMesActual();

    if (_semanaSeleccionadaId == null && semanasDisponibles.isNotEmpty) {
      final ahora = DateTime.now();
      
      final semanaActual = semanasDisponibles.firstWhere(
        (s) {
          final inicio = s['inicio'] as DateTime;
          final fin = s['fin'] as DateTime;
          return ahora.isAfter(inicio.subtract(const Duration(seconds: 1))) && 
                 ahora.isBefore(fin.add(const Duration(days: 1)));
        },
        orElse: () => semanasDisponibles.first,
      );

      _semanaSeleccionadaId = semanaActual['id'];
    }

    final semanaActual = semanasDisponibles.firstWhere(
      (s) => s['id'] == _semanaSeleccionadaId,
      orElse: () => semanasDisponibles.first,
    );

    // Filtrar Ventas
    final ventasAMostrar = provider.obtenerVentasPorRango(
      semanaActual['inicio'],
      semanaActual['fin'],
    ).reversed.toList();

    // NUEVO: Filtrar Gastos/Inversiones para que coincidan con la semana seleccionada
    final finDelDia = (semanaActual['fin'] as DateTime).add(const Duration(days: 1));
    final movimientosAMostrar = provider.movimientos.where((m) {
      return m.fecha.isAfter((semanaActual['inicio'] as DateTime).subtract(const Duration(seconds: 1))) &&
             m.fecha.isBefore(finDelDia);
    }).toList().reversed.toList();

    final double totalSeleccionado = ventasAMostrar.fold(0, (sum, v) => sum + v.totalFinal);

    // Envolvemos todo en un DefaultTabController para habilitar las pestañas
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            ResumenBalanceCard(totalSemana: totalSeleccionado),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: (ventasAMostrar.isNotEmpty || movimientosAMostrar.isNotEmpty)
                  ? VentasChart(
                      ventasSemana: ventasAMostrar, 
                      movimientosSemana: movimientosAMostrar, // <-- Pasamos los movimientos
                    )
                  : Container(
                      height: 180,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          "Sin datos para graficar en esta semana",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ),
                    ),
            ),
              
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _semanaSeleccionadaId,
                    icon: Icon(Icons.keyboard_arrow_down, color: tema.primary),
                    items: semanasDisponibles.reversed.map((semana) {
                      return DropdownMenuItem<String>(
                        value: semana['id'],
                        child: Text(
                          semana['label'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: (nuevoId) {
                      setState(() => _semanaSeleccionadaId = nuevoId);
                    },
                  ),
                ),
              ),
            ),

            // NUEVO: Pestañas de navegación
            TabBar(
              labelColor: tema.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: tema.primary,
              tabs: const [
                Tab(text: 'Ventas'),
                Tab(text: 'Inversiones/Gastos'),
              ],
            ),

            // NUEVO: Vistas de las pestañas
            Expanded(
              child: TabBarView(
                children: [
                  // PESTAÑA 1: VENTAS
                  ventasAMostrar.isEmpty
                      ? _buildEmptyState(semanaActual['label'], isVentas: true)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          itemCount: ventasAMostrar.length,
                          itemBuilder: (context, index) => TarjetaVentaHistorial(venta: ventasAMostrar[index]),
                        ),
                  
                  // PESTAÑA 2: MOVIMIENTOS
                  movimientosAMostrar.isEmpty
                      ? _buildEmptyState(semanaActual['label'], isVentas: false)
                      : ListaHistorialMovimientos(movimientos: movimientosAMostrar),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modificado para adaptar el texto e icono según la pestaña
  Widget _buildEmptyState(String labelSemana, {bool isVentas = true}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVentas ? Icons.receipt_long_outlined : Icons.account_balance_wallet_outlined, 
            size: 70, 
            color: Colors.grey.withOpacity(0.2)
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isVentas 
                ? 'No hay ventas registradas\ndel $labelSemana'
                : 'No hay gastos ni inversiones\ndel $labelSemana',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}