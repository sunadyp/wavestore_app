import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/movimiento.dart';

class ListaHistorialMovimientos extends StatelessWidget {
  final List<Movimiento> movimientos;

  // 🚀 OPTIMIZACIÓN DEFINITIVA: Declaramos el DateFormat como estático y final.
  // Al sacarlo por completo del método build, ahorramos memoria y procesamiento.
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy • hh:mm a');

  const ListaHistorialMovimientos({super.key, required this.movimientos});

  @override
  Widget build(BuildContext context) {
    if (movimientos.isEmpty) {
      return const Center(
        child: Text(
          'No hay movimientos registrados.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: movimientos.length,
      itemBuilder: (context, index) {
        final mov = movimientos[index];
        final bool esGasto = !mov.esInversion;

        return Card(
          key: ValueKey(mov.id), // <-- Estabiliza el renderizado de la lista
          elevation: 1.5, 
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
              _dateFormatter.format(mov.fecha), 
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