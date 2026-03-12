import 'package:flutter/material.dart';

class ListaHistorialVentas extends StatelessWidget {
  final List ventas;
  const ListaHistorialVentas({super.key, required this.ventas});

  @override
  Widget build(BuildContext context) {
    if (ventas.isEmpty) return const Center(child: Text('Sin registros'));

    return ListView.builder(
      itemCount: ventas.length,
      itemBuilder: (context, i) {
        final v = ventas[i];
        return ListTile(
          leading: CircleAvatar(child: Text('${v.cantidad}')),
          title: Text(v.productoNombre),
          subtitle: Text('\$${(v.total / v.cantidad).toStringAsFixed(2)} c/u'),
          trailing: Text('+\$${v.total.toStringAsFixed(2)}', 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        );
      },
    );
  }
}