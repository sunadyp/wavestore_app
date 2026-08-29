import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta.dart';

class ListaHistorialVentas extends StatelessWidget {
  // Optimizamos el tipado de datos para mejor rendimiento
  final List<Venta> ventas;
  
  const ListaHistorialVentas({super.key, required this.ventas});

  @override
  Widget build(BuildContext context) {
    if (ventas.isEmpty) {
      return const Center(
        child: Text(
          'Sin registros de ventas.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    // ListView.builder ya renderiza de forma "perezosa" (solo lo visible), lo cual es super eficiente
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: ventas.length,
      itemBuilder: (context, i) {
        final venta = ventas[i];
        
        // Contar el total de productos en esta venta
        final totalArticulos = venta.articulos.fold<int>(0, (sum, item) => sum + item.cantidad);
        
        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.pink, // Cambia por colores acordes a tu tema rosa de WaveStore
              child: Icon(Icons.receipt_long, color: Colors.white, size: 20),
            ),
            title: Text(
              'Cliente: ${venta.telefonoCliente}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${DateFormat('dd MMM yyyy • HH:mm').format(venta.fecha)} | $totalArticulos ud.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Text(
              '+\$${venta.totalFinal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                color: Colors.green,
                fontSize: 15,
              ),
            ),
            children: [
              const Divider(height: 1),
              
              // Mapeo eficiente de los artículos vendidos dentro del apartado
              ...venta.articulos.map((art) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${art.cantidad}x ${art.productoNombre}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '\$${art.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              )),
              
              const Divider(height: 1),
              
              // Desglose de ajustes monetarios especiales (Cargos extras con su nombre / Descuentos)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (venta.descuentoAplicado > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Descuento aplicado:', style: TextStyle(fontSize: 12, color: Colors.red)),
                          Text('-\$${venta.descuentoAplicado.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                    if (venta.cargoExtra > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${venta.conceptoCargoExtra}:', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                          Text('+\$${venta.cargoExtra.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                        ],
                      ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}