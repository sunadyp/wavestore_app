import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/movimiento.dart';
import '../../providers/inventario_provider.dart';

class ListaHistorialMovimientos extends StatelessWidget {
  final List<Movimiento> movimientos;

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
        final bool afectoCaja = mov.afectoCaja; // Validamos si tocó el dinero

        return Card(
          key: ValueKey('card_${mov.id}'),
          elevation: 1.5, 
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Dismissible(
            key: ValueKey('dismiss_${mov.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.undo, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Revertir Movimiento?'),
                  content: Text(
                    'Se deshará la acción:\n"${mov.descripcion}".\n\n'
                    '¿Estás seguro de continuar?'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sí, deshacer'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              context.read<InventarioProvider>().revertirMovimiento(mov.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Movimiento revertido correctamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                // Si no afectó caja, le damos un color neutro (gris)
                backgroundColor: afectoCaja 
                    ? (esGasto ? Colors.red.shade50 : Colors.blue.shade50)
                    : Colors.grey.shade200,
                child: Icon(
                  afectoCaja 
                      ? (esGasto ? Icons.money_off_rounded : Icons.trending_up_rounded)
                      : Icons.inventory_2_outlined, // Ícono de inventario para que no parezca transacción
                  color: afectoCaja 
                      ? (esGasto ? Colors.red : Colors.blue)
                      : Colors.grey.shade600,
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
                // Lógica principal: Si no afectó caja, muestra $0.00
                afectoCaja 
                    ? '${esGasto ? '-' : '+'}\$${mov.monto.toStringAsFixed(2)}'
                    : '\$0.00',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  // Color gris si fue neutro
                  color: afectoCaja 
                      ? (esGasto ? Colors.red : Colors.green)
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}