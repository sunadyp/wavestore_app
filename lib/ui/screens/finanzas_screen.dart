import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/venta.dart';
import '../widgets/resumen_balance_card.dart';
import '../widgets/tarjeta_venta_historial.dart';
import '../widgets/ventas_chart.dart'; // Importación de la gráfica

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  // Guardamos solo el ID (String) para evitar errores de comparación de objetos
  String? _semanaSeleccionadaId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    
    // Obtenemos todas las semanas del mes (vacías o no)
    final semanasDisponibles = provider.obtenerSemanasMesActual();

    // 1. Selección inicial inteligente (Semana Actual)
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

    // 2. Buscamos los datos completos de la semana seleccionada usando el ID
    final semanaActual = semanasDisponibles.firstWhere(
      (s) => s['id'] == _semanaSeleccionadaId,
      orElse: () => semanasDisponibles.first,
    );

    // 3. Filtramos las ventas para la lista y la gráfica
    final ventasAMostrar = provider.obtenerVentasPorRango(
      semanaActual['inicio'],
      semanaActual['fin'],
    ).reversed.toList();

    // 4. Calculamos el total de la semana para la tarjeta superior
    final double totalSeleccionado = ventasAMostrar.fold(0, (sum, v) => sum + v.total);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Muestra el total dinámico según la semana elegida
          ResumenBalanceCard(totalSemana: totalSeleccionado),

          // --- SECCIÓN DE LA GRÁFICA ---
          // Si hay ventas, mostramos la gráfica; si no, un mensaje informativo
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
            
          // --- SELECTOR DE SEMANA ---
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
                  // Invertimos las semanas para que la más reciente salga arriba en el menú
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

          // --- LISTA DE TRANSACCIONES ---
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