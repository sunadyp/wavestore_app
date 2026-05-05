import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/movimiento.dart';

class ListaHistorialMovimientos extends StatelessWidget {
  final List<Movimiento> movimientos;

  const ListaHistorialMovimientos({super.key, required this.movimientos});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: movimientos.length,
      itemBuilder: (context, index) {
        final mov = movimientos[index];
        final bool esGasto = !mov.esInversion;

        return Card(
          elevation: 2,
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy • hh:mm a').format(mov.fecha),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              '${esGasto ? '-' : '+'}\$${mov.monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: esGasto ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}