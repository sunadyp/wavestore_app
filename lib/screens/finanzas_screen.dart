import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventario_provider.dart';
import '../widgets/resumen_balance_card.dart';
import '../widgets/tarjeta_venta_historial.dart';

class FinanzasScreen extends StatelessWidget {
  const FinanzasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final ventas = provider.ventas.reversed.toList();

    return Scaffold(
      body: Column(
        children: [
          // 1. Widget extraído para el balance
          ResumenBalanceCard(totalSemana: provider.ventasSemana),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Historial Reciente', 
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
          
          // 2. Lista optimizada
          Expanded(
            child: ventas.isEmpty 
              ? const Center(child: Text('Aún no hay ventas registradas'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: ventas.length,
                  itemBuilder: (context, index) => TarjetaVentaHistorial(venta: ventas[index]),
                ),
          ),
        ],
      ),
    );
  }
}