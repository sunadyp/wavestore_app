import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResumenPeriodoCard extends StatelessWidget {
  final DateTimeRange rango;
  final double total;
  final bool esManual;
  final VoidCallback onTapCalendario;

  // 🚀 OPTIMIZACIÓN: Formateador estático para ahorrar memoria
  static final DateFormat _dateFormatter = DateFormat('dd/MM');

  const ResumenPeriodoCard({
    super.key, 
    required this.rango, 
    required this.total, 
    required this.esManual,
    required this.onTapCalendario
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                esManual ? 'Filtro Manual' : 'Esta Semana', 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month), 
                onPressed: onTapCalendario,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_dateFormatter.format(rango.start)} - ${_dateFormatter.format(rango.end)}'),
              Text(
                '\$${total.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}