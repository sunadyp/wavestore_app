import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../services/pdf_service.dart';
import '../../models/venta.dart'; // <-- Agregamos esta importación para que reconozca "Carrito"

class CarritosActivosScreen extends StatelessWidget {
  const CarritosActivosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final carritos = provider.carritosActivos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartados Activos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: carritos.isEmpty
          ? const Center(
              child: Text(
                'No hay carritos activos en este momento.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: carritos.length,
              itemBuilder: (context, index) {
                final telefono = carritos.keys.elementAt(index);
                final carrito = carritos[telefono]!;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                    title: Text('Clienta: $telefono', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total: \$${carrito.total.toStringAsFixed(2)} | Artículos: ${carrito.articulos.length}'),
                    children: [
                      const Divider(),
                      // Lista de artículos en este carrito
                      ...carrito.articulos.map((articulo) => ListTile(
                            dense: true,
                            title: Text(articulo.productoNombre),
                            trailing: Text('${articulo.cantidad} x \$${articulo.precioUnitario}'),
                          )),
                      const Divider(),
                      
                      // Sección de Totales y Descuento
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Subtotal: \$${carrito.subtotal.toStringAsFixed(2)}'),
                                
                                // <-- NUEVO: Texto inteligente del descuento
                                if (carrito.descuentoMonto > 0)
                                  Text(
                                    'Descuento ${carrito.descuentoEsPorcentaje ? '(${carrito.descuentoValor.toInt()}%)' : ''}: -\$${carrito.descuentoMonto.toStringAsFixed(2)}', 
                                    style: const TextStyle(color: Colors.red)
                                  ),
                                  
                                Text('Total a cobrar: \$${carrito.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.local_offer),
                              label: const Text('Descuento'),
                              // <-- Pasamos el objeto carrito completo
                              onPressed: () => _mostrarDialogoDescuento(context, provider, telefono, carrito),
                            ),
                          ],
                        ),
                      ),
                      
                      // Botones de acción final
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón de Cancelar
                            IconButton(
                              tooltip: 'Cancelar y devolver inventario',
                              icon: const Icon(Icons.remove_shopping_cart, color: Colors.red),
                              onPressed: () => _confirmarCancelacion(context, provider, telefono),
                            ),
                            
                            // Botón para generar y mandar el PDF
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                              icon: const Icon(Icons.receipt),
                              label: const Text('Mandar Ticket'),
                              onPressed: () async {
                                await PdfService.generarYCompartirTicket(carrito);
                              },
                            ),

                            // Botón de Cobrar
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              icon: const Icon(Icons.check),
                              label: const Text('Cobrar'),
                              onPressed: () {
                                provider.cobrarCarrito(telefono);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Venta de $telefono cobrada con éxito')),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  // <-- NUEVO: Diálogo reescrito con StatefulBuilder para manejar los chips de % y $
  void _mostrarDialogoDescuento(BuildContext context, InventarioProvider provider, String telefono, Carrito carrito) {
    final ctrl = TextEditingController(text: carrito.descuentoValor > 0 ? carrito.descuentoValor.toString() : '');
    bool esPorcentaje = carrito.descuentoEsPorcentaje;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Aplicar Descuento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('\$ Monto'),
                      selected: !esPorcentaje,
                      onSelected: (val) => setStateDialog(() => esPorcentaje = false),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('% Porcentaje'),
                      selected: esPorcentaje,
                      onSelected: (val) => setStateDialog(() => esPorcentaje = true),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: esPorcentaje ? 'Porcentaje de descuento' : 'Monto a descontar',
                    prefixText: esPorcentaje ? '' : '\$ ',
                    suffixText: esPorcentaje ? '%' : '',
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final valor = double.tryParse(ctrl.text) ?? 0.0;
                  provider.aplicarDescuentoACarrito(telefono, valor, esPorcentaje);
                  Navigator.pop(ctx);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmarCancelacion(BuildContext context, InventarioProvider provider, String telefono) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar apartado?'),
        content: const Text('Los productos regresarán al inventario disponible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              provider.cancelarCarrito(telefono);
              Navigator.pop(ctx);
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}