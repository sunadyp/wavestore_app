import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/producto.dart';

class FormularioProducto extends StatefulWidget {
  final Producto? productoActual; // Puede recibir un producto o ser nulo

  const FormularioProducto({super.key, this.productoActual});

  @override
  State<FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<FormularioProducto> {
  final _nombreCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Si recibimos un producto (estamos editando), llenamos los inputs
    if (widget.productoActual != null) {
      final p = widget.productoActual!;
      _nombreCtrl.text = p.nombre;
      _costoCtrl.text = p.costo.toString();
      _precioCtrl.text = p.precioVenta.toString();
      _cantidadCtrl.text = p.cantidad.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos una variable para saber si estamos editando
    final esEdicion = widget.productoActual != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: _costoCtrl, decoration: const InputDecoration(labelText: 'Costo'), keyboardType: TextInputType.number),
          TextField(controller: _precioCtrl, decoration: const InputDecoration(labelText: 'Precio de venta'), keyboardType: TextInputType.number),
          TextField(controller: _cantidadCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              final nuevoProducto = Producto(
                id: esEdicion ? widget.productoActual!.id : DateTime.now().toString(),
                nombre: _nombreCtrl.text,
                costo: double.tryParse(_costoCtrl.text) ?? 0,
                precioVenta: double.tryParse(_precioCtrl.text) ?? 0,
                cantidad: int.tryParse(_cantidadCtrl.text) ?? 0,
              );

              if (esEdicion) {
                context.read<InventarioProvider>().editarProducto(widget.productoActual!.id, nuevoProducto);
              } else {
                context.read<InventarioProvider>().agregarProducto(nuevoProducto);
              }
              Navigator.pop(context);
            },
            child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}