import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/producto.dart';

class FormularioProducto extends StatefulWidget {
  final Producto? productoActual;
  const FormularioProducto({super.key, this.productoActual});

  @override
  State<FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<FormularioProducto> {
  final _nombreCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  String _categoriaSeleccionada = 'General';
  
  // Viene en TRUE por defecto para que reste de la caja automáticamente
  bool _afectaCaja = true;

  @override
  void initState() {
    super.initState();
    if (widget.productoActual != null) {
      final p = widget.productoActual!;
      _nombreCtrl.text = p.nombre;
      _costoCtrl.text = p.costo.toString();
      _precioCtrl.text = p.precioVenta.toString();
      _cantidadCtrl.text = p.cantidad.toString();
      _categoriaSeleccionada = p.categoria;
    }
    // Eliminamos el bloque 'else' que lo pasaba a false. Ahora siempre inicia en true.
  }

  void _mostrarDialogoNuevaCategoria() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<InventarioProvider>().agregarCategoria(controller.text);
                setState(() => _categoriaSeleccionada = controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.productoActual != null;
    final categoriasDisponibles = context.watch<InventarioProvider>().categorias;

    if (!categoriasDisponibles.contains(_categoriaSeleccionada)) {
      _categoriaSeleccionada = categoriasDisponibles.first;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: categoriasDisponibles.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) => setState(() => _categoriaSeleccionada = val!),
                  ),
                ),
                IconButton(
                  onPressed: _mostrarDialogoNuevaCategoria,
                  icon: const Icon(Icons.add_circle, color: Colors.pink),
                ),
              ],
            ),

            TextField(controller: _costoCtrl, decoration: const InputDecoration(labelText: 'Costo'), keyboardType: TextInputType.number),
            TextField(controller: _precioCtrl, decoration: const InputDecoration(labelText: 'Precio venta'), keyboardType: TextInputType.number),
            TextField(controller: _cantidadCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
            
            // Switch para decidir si afecta la caja (Solo visible al crear)
            if (!esEdicion) ...[
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Restar costo de la caja', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Desactívalo si este producto ya lo tenías comprado desde antes.', style: TextStyle(fontSize: 12)),
                value: _afectaCaja,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) => setState(() => _afectaCaja = val),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                final prod = Producto(
                  id: esEdicion ? widget.productoActual!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  nombre: _nombreCtrl.text,
                  categoria: _categoriaSeleccionada,
                  costo: double.tryParse(_costoCtrl.text) ?? 0,
                  precioVenta: double.tryParse(_precioCtrl.text) ?? 0,
                  cantidad: int.tryParse(_cantidadCtrl.text) ?? 0,
                );

                if (esEdicion) {
                  context.read<InventarioProvider>().editarProducto(prod.id, prod);
                } else {
                  context.read<InventarioProvider>().agregarProducto(prod, afectaCaja: _afectaCaja);
                }
                Navigator.pop(context);
              },
              child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}