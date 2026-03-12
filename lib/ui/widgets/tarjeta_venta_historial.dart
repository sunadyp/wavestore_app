import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta.dart';

class TarjetaVentaHistorial extends StatelessWidget {
  final Venta venta;

  const TarjetaVentaHistorial({super.key, required this.venta});

  @override
  Widget build(BuildContext context) {
    final precioUnitario = venta.total / venta.cantidad;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          child: Text('${venta.cantidad}', 
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(venta.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${venta.cantidad} un. x \$${precioUnitario.toStringAsFixed(2)}'),
            Text(
              DateFormat('dd/MM/yyyy - hh:mm a').format(venta.fecha),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text('+\$${venta.total.toStringAsFixed(2)}', 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
      ),
    );
  }
}