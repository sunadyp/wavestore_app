import 'package:flutter/material.dart';

class ResumenBalanceCard extends StatelessWidget {
  final double totalSemana;

  const ResumenBalanceCard({super.key, required this.totalSemana});

  @override
  Widget build(BuildContext context) {
    // 1. Determinar el color dinámico
    Color colorBalance;
    if (totalSemana > 0) {
      colorBalance = Colors.green;
    } else if (totalSemana < 0) {
      colorBalance = Colors.red;
    } else {
      colorBalance = Colors.grey;
    }

    // 2. Formatear el texto para que el signo '-' quede antes del '$'
    final signo = totalSemana < 0 ? '-' : '';
    final montoFormateado = '$signo\$${totalSemana.abs().toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Balance de esta semana:', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            montoFormateado, 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: colorBalance, // <-- Aplicamos el color aquí
            ),
          ),
        ],
      ),
    );
  }
}