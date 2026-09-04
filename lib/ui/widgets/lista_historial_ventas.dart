import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta.dart';

class ListaHistorialVentas extends StatelessWidget {
  final List<Venta> ventas;
  
  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy • HH:mm');
  
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: ventas.length,
      itemBuilder: (context, i) {
        final venta = ventas[i];
        
        final totalArticulos = venta.articulos.fold<int>(0, (sum, item) => sum + item.cantidad);
        
        return Card(
          key: ValueKey(venta.id), 
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary, 
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cliente: ${venta.telefonoCliente}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                // 🚀 Indicador visual discreto si fue pago con tarjeta
                if (venta.pagoConTarjeta)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.credit_card, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Tarjeta', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${_dateFormatter.format(venta.fecha)} | $totalArticulos ud.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Text(
              '+\$${venta.ingresoNeto.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                color: Colors.green,
                fontSize: 15,
              ),
            ),
            children: [
              const Divider(height: 1),
              
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
                    
                    // 🚀 Desglose de comisión de tarjeta solo si aplica
                    if (venta.pagoConTarjeta) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Comisión bancaria descontada:', style: TextStyle(fontSize: 12, color: Colors.orange)),
                          Text('-\$${venta.comisionTarjeta.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ingreso neto real a caja:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('\$${venta.ingresoNeto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
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