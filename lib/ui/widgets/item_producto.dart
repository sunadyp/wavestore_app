import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/producto.dart';
import 'formulario_producto.dart';

class ItemProducto extends StatelessWidget {
  final Producto producto;

  const ItemProducto({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    // Dismissible crea el efecto de "deslizar para borrar"
    return Dismissible(
      key: Key(producto.id),
      direction: DismissDirection.endToStart, // Deslizar de derecha a izquierda
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        margin: const EdgeInsets.only(bottom: 12),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Llamamos a la función de eliminar que acabamos de crear
        context.read<InventarioProvider>().eliminarProducto(producto.id);
        
        // Mostramos un mensajito rápido abajo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${producto.nombre} eliminado')),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.inventory_2, color: Colors.white),
          ),
          title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(
            'Stock: ${producto.cantidad} un. | Precio: \$${producto.precioVenta.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          // Usamos Row para tener dos botones juntos
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de Vender (Solo se muestra si hay stock)
              // Botón de Vender con Confirmación
              if (producto.cantidad > 0)
                IconButton(
                  icon: const Icon(Icons.point_of_sale, color: Colors.green),
                  onPressed: () {
                    final qtyCtrl = TextEditingController(text: '1'); // Empieza en 1 por defecto
                    
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Vender ${producto.nombre}'),
                        content: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cantidad a vender'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx), // Cierra sin hacer nada
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () {
                              final qty = int.tryParse(qtyCtrl.text) ?? 0;
                              
                              if (qty > 0 && qty <= producto.cantidad) {
                                context.read<InventarioProvider>().registrarVenta(producto.id, qty);
                                Navigator.pop(ctx); // Cierra la alerta
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Venta de $qty confirmada')),
                                );
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Cantidad inválida o sin stock')),
                                );
                              }
                            },
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              // Botón de Editar original
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (context) => FormularioProducto(productoActual: producto),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}