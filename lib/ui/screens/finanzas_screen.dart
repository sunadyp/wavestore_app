import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/resumen_balance_card.dart';
import '../widgets/tarjeta_venta_historial.dart';
import '../widgets/ventas_chart.dart';

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

    final ventasAMostrar = provider.obtenerVentasPorRango(
      semanaActual['inicio'],
      semanaActual['fin'],
    ).reversed.toList();

    // <--- CAMBIO AQUÍ (v.totalFinal) --->
    final double totalSeleccionado = ventasAMostrar.fold(0, (sum, v) => sum + v.totalFinal);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ResumenBalanceCard(totalSemana: totalSeleccionado),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ventasAMostrar.isNotEmpty
                ? VentasChart(ventasSemana: ventasAMostrar)
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
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.pink),
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

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MOVIMIENTOS DEL PERIODO',
                style: TextStyle(
                  fontSize: 11, 
                  color: Colors.grey, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.2
                ),
              ),
            ),
          ),

          Expanded(
            child: ventasAMostrar.isEmpty
                ? _buildEmptyState(semanaActual['label'])
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: ventasAMostrar.length,
                    itemBuilder: (context, index) => TarjetaVentaHistorial(venta: ventasAMostrar[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String labelSemana) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 70, color: Colors.pink.withOpacity(0.1)),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No hay ventas registradas\ndel $labelSemana',
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