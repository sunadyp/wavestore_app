import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/producto.dart';
import '../../utils/ui_utils.dart'; // Importante
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
      // Lógica de confirmación externa
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
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: _buildAvatar(context),
          title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Stock: ${producto.cantidad} | \$${producto.precioVenta}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (producto.cantidad > 0)
                IconButton(
                  icon: const Icon(Icons.point_of_sale, color: Colors.green),
                  onPressed: () => _ejecutarVenta(context, inventario),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                onPressed: () => _abrirEditor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS DE APOYO PARA LIMPIAR EL BUILD ---

  void _ejecutarVenta(BuildContext context, InventarioProvider provider) async {
    final qty = await UIUtils.mostrarDialogoVenta(context, producto);
    
    if (qty != null && qty > 0 && qty <= producto.cantidad) {
      provider.registrarVenta(producto.id, qty);
      _notificar(context, 'Venta de $qty confirmada');
    } else if (qty != null) {
      _notificar(context, 'Cantidad inválida o sin stock suficiente');
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

  Widget _buildAvatar(BuildContext context) => CircleAvatar(
    backgroundColor: Theme.of(context).colorScheme.secondary,
    child: const Icon(Icons.inventory_2, color: Colors.white),
  );

  Widget _buildDeleteBackground() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    color: Colors.red.shade400,
    margin: const EdgeInsets.only(bottom: 12),
    child: const Icon(Icons.delete, color: Colors.white),
  );
}