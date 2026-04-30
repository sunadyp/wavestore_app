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
  }

  // NUEVO: Diálogo para crear categoría desde el formulario[cite: 1]
  void _mostrarDialogoNuevaCategoria() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ej: Maquillaje, Skincare'),
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

    // Aseguramos que la categoría seleccionada exista en la lista actual[cite: 1]
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
            
            // FILA PARA CATEGORÍA Y BOTÓN DE AGREGAR[cite: 1]
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
                  context.read<InventarioProvider>().agregarProducto(prod);
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