import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/venta.dart';
import '../../providers/inventario_provider.dart';

class TarjetaVentaHistorial extends StatelessWidget {
  final Venta venta;

  // 🚀 OPTIMIZACIÓN: Formateador en memoria única
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy - hh:mm a');

  const TarjetaVentaHistorial({super.key, required this.venta});

  @override
  Widget build(BuildContext context) {
    final int totalArticulos = venta.articulos.fold(0, (sum, item) => sum + item.cantidad);

    return Card(
      key: ValueKey(venta.id), // <-- Mantiene estable el acordeón al hacer scroll
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          child: Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text('Venta a: ${venta.telefonoCliente}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$totalArticulos artículos en total'),
            Text(
              _dateFormatter.format(venta.fecha),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          '+\$${venta.totalFinal.toStringAsFixed(2)}', 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
        ),
        children: [
          const Divider(),
          ...venta.articulos.map((articulo) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${articulo.cantidad}x ${articulo.productoNombre}', 
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '\$${articulo.subtotal.toStringAsFixed(2)}', 
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          )),
          
          if (venta.descuentoAplicado > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Descuento aplicado:', style: TextStyle(fontSize: 13, color: Colors.red)),
                  Text('-\$${venta.descuentoAplicado.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.red)),
                ],
              ),
            ),

          if (venta.cargoExtra > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${venta.conceptoCargoExtra}:', style: const TextStyle(fontSize: 13, color: Colors.blue)),
                  Text('+\$${venta.cargoExtra.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.blue)),
                ],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.settings_backup_restore, color: Colors.redAccent),
              label: const Text('Revertir Venta', style: TextStyle(color: Colors.redAccent)),
              // Capturamos el provider aquí de forma segura antes de abrir diálogos
              onPressed: () {
                final provider = context.read<InventarioProvider>();
                _confirmarReversion(context, venta, provider);
              },
            ),
          )
        ],
      ),
    );
  }

  void _confirmarReversion(BuildContext context, Venta venta, InventarioProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Advertencia!'),
        content: const Text('¿Estás seguro de querer revertir esta venta? El dinero se restará de la caja y los productos volverán al inventario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx); 
              _segundaConfirmacion(context, venta, provider); 
            },
            child: const Text('Sí, revertir'),
          ),
        ],
      ),
    );
  }

  void _segundaConfirmacion(BuildContext context, Venta venta, InventarioProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmación Final'),
        content: const Text('Esta acción no se puede deshacer. Presiona "CONFIRMAR" para proceder.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              provider.revertirVenta(venta.id);
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Venta revertida exitosamente'))
                );
              }
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }
}