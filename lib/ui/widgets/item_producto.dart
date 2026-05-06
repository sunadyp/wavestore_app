import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/producto.dart';
import '../../utils/ui_utils.dart';
import 'formulario_producto.dart';

class ItemProducto extends StatelessWidget {
  final Producto producto;

  const ItemProducto({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final inventario = context.read<InventarioProvider>();

    return Dismissible(
      key: Key(producto.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => UIUtils.confirmarEliminacion(context, producto.nombre),
      onDismissed: (_) {
        inventario.eliminarProducto(producto.id);
        _notificar(context, '${producto.nombre} eliminado');
      },
      background: _buildDeleteBackground(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row( 
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      producto.nombre, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${producto.cantidad} | \$${producto.precioVenta}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            producto.categoria,
                            style: TextStyle(
                              fontSize: 10, 
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        Text(
                          'Ganancia: \$${producto.utilidad.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green, 
                            fontWeight: FontWeight.w600, 
                            fontSize: 11
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact, 
                    icon: const Icon(Icons.add_box, color: Colors.blue, size: 22),
                    onPressed: () => _reabastecer(context, inventario),
                  ),
                  if (producto.cantidad > 0)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.point_of_sale, color: Colors.green, size: 22),
                      onPressed: () => _ejecutarVenta(context, inventario),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 22),
                    onPressed: () => _abrirEditor(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ejecutarVenta(BuildContext context, InventarioProvider provider) async {
    final resultado = await UIUtils.mostrarDialogoVenta(context, producto);
    if (resultado != null) {
      final String telefono = resultado['telefono'];
      final int qty = resultado['cantidad'];
      if (qty > 0 && qty <= producto.cantidad) {
        provider.agregarAlCarrito(telefono, producto, qty);
        _notificar(context, '$qty agregados al carrito de $telefono');
      } else {
        _notificar(context, 'Stock insuficiente');
      }
    }
  }

  // NUEVO: Diálogo de reabastecimiento integrado aquí para tener control del Switch
  void _reabastecer(BuildContext context, InventarioProvider provider) async {
    final qtyCtrl = TextEditingController();
    final costoCtrl = TextEditingController(text: producto.costo.toString());
    bool afectaCaja = true;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reabastecer\n${producto.nombre}', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad a ingresar'),
                    autofocus: true,
                  ),
                  TextField(
                    controller: costoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Costo unitario (\$)'),
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Restar de la caja', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Apágalo si es mercancía vieja o regalada.', style: TextStyle(fontSize: 12)),
                    value: afectaCaja,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) => setState(() => afectaCaja = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    final q = int.tryParse(qtyCtrl.text) ?? 0;
                    final c = double.tryParse(costoCtrl.text) ?? 0.0;
                    if (q > 0) {
                      Navigator.pop(ctx, {'cantidad': q, 'costo': c, 'afectaCaja': afectaCaja});
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          }
        );
      }
    );

    if (resultado != null) {
      final int qty = resultado['cantidad'];
      final double costo = resultado['costo'];
      final bool afecta = resultado['afectaCaja'];
      
      // NUEVO: Pasamos el parámetro afectaCaja
      provider.reabastecerProducto(producto.id, qty, costo, afectaCaja: afecta);
      _notificar(context, 'Stock actualizado exitosamente');
    }
  }

  void _abrirEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (_) => FormularioProducto(productoActual: producto),
    );
  }

  void _notificar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildDeleteBackground() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    color: Colors.red.shade400,
    margin: const EdgeInsets.only(bottom: 12),
    child: const Icon(Icons.delete, color: Colors.white),
  );
}