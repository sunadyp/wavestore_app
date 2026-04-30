import 'package:flutter/material.dart';
import '../models/producto.dart';

class UIUtils {
  // Diálogo para confirmar eliminación
  static Future<bool?> confirmarEliminacion(BuildContext context, String nombre) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¿Eliminar producto?'),
        content: Text('¿Estás seguro de que quieres eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  // --- Diálogo para apartar/vender producto y mandarlo a un Carrito ---
  static Future<Map<String, dynamic>?> mostrarDialogoVenta(BuildContext context, Producto producto) {
    final qtyCtrl = TextEditingController(text: '1');
    final telefonoCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Apartar ${producto.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Teléfono de la clienta',
                hintText: 'Ej. 8331234567',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad a apartar',
                suffixText: 'un.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text);
              final telefono = telefonoCtrl.text.trim();
              
              if (telefono.isNotEmpty && qty != null && qty > 0) {
                Navigator.pop(ctx, {'telefono': telefono, 'cantidad': qty});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un teléfono y cantidad válidos')),
                );
              }
            },
            child: const Text('AGREGAR AL CARRITO'),
          ),
        ],
      ),
    );
  }

  // --- NUEVO: Diálogo para reabastecer y calcular costo promedio ---
  static Future<Map<String, dynamic>?> mostrarDialogoReabastecer(BuildContext context, Producto producto) {
    final qtyCtrl = TextEditingController();
    final costoCtrl = TextEditingController(text: producto.costo.toString()); 

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Reabastecer ${producto.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa las nuevas unidades y su costo individual. La app calculará el costo promedio automáticamente.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Unidades entrantes',
                suffixText: 'un.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: costoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Costo unitario (De esta tanda)',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text);
              final costo = double.tryParse(costoCtrl.text);
              
              if (qty != null && qty > 0 && costo != null && costo >= 0) {
                Navigator.pop(ctx, {'cantidad': qty, 'costo': costo});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa cantidades y costos válidos')),
                );
              }
            },
            child: const Text('AGREGAR STOCK'),
          ),
        ],
      ),
    );
  }
}