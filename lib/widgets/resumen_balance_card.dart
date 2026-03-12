import 'package:flutter/material.dart';

class ResumenBalanceCard extends StatelessWidget {
  final double totalSemana;

  const ResumenBalanceCard({super.key, required this.totalSemana});

  @override
  Widget build(BuildContext context) {
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
          const Text('Ventas de esta semana:', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('\$${totalSemana.toStringAsFixed(2)}', 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}