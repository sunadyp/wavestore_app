import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/movimiento.dart';

class ListaHistorialMovimientos extends StatelessWidget {
  final List<Movimiento> movimientos;

  const ListaHistorialMovimientos({super.key, required this.movimientos});

  @override
  Widget build(BuildContext context) {
    // 1. Manejo eficiente del estado vacío
    if (movimientos.isEmpty) {
      return const Center(
        child: Text(
          'No hay movimientos registrados.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    // 2. OPTIMIZACIÓN: Crear el formateador de fecha una sola vez fuera del builder
    // Esto ahorra memoria y evita tirones al hacer scroll rápido en listas muy largas.
    final dateFormatter = DateFormat('dd/MM/yyyy • hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: movimientos.length,
      itemBuilder: (context, index) {
        // En caso de querer ver los más recientes arriba, 
        // podrías usar: final mov = movimientos[movimientos.length - 1 - index];
        // Por ahora lo mantenemos en tu orden original:
        final mov = movimientos[index];
        final bool esGasto = !mov.esInversion;

        return Card(
          elevation: 1.5, // Sombra ligera para mejor renderizado
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: esGasto ? Colors.red.shade50 : Colors.blue.shade50,
              child: Icon(
                esGasto ? Icons.money_off_rounded : Icons.trending_up_rounded,
                color: esGasto ? Colors.red : Colors.blue,
              ),
            ),
            title: Text(
              mov.descripcion,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              dateFormatter.format(mov.fecha), // Usamos la instancia única
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Text(
              '${esGasto ? '-' : '+'}\$${mov.monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: esGasto ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}