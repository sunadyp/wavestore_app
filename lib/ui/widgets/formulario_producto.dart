import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // <-- Importamos para usar IDs seguros
import '../../providers/inventario_provider.dart';
import '../../models/producto.dart';

class FormularioProducto extends StatefulWidget {
  final Producto? productoActual;
  const FormularioProducto({super.key, this.productoActual});

  @override
  State<FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<FormularioProducto> {
  final _formKey = GlobalKey<FormState>(); // <-- Llave para validar el formulario
  final _nombreCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  
  String? _categoriaSeleccionada;
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
  }

  // 🚀 OPTIMIZACIÓN CRÍTICA: Liberar memoria para evitar crashes en celulares de gama media/baja
  @override
  void dispose() {
    _nombreCtrl.dispose();
    _costoCtrl.dispose();
    _precioCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
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
          textCapitalization: TextCapitalization.words, // Capitaliza automáticamente
          decoration: const InputDecoration(hintText: 'Ej. Skincare'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final nuevaCat = controller.text.trim();
                context.read<InventarioProvider>().agregarCategoria(nuevaCat);
                setState(() => _categoriaSeleccionada = nuevaCat);
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
    
    // Solo escuchamos cambios en las categorías, no en todo el inventario
    final categoriasDisponibles = context.select<InventarioProvider, List<String>>(
      (provider) => provider.categorias
    );

    // Asignación segura de la categoría inicial
    if (_categoriaSeleccionada == null || !categoriasDisponibles.contains(_categoriaSeleccionada)) {
      _categoriaSeleccionada = categoriasDisponibles.isNotEmpty ? categoriasDisponibles.first : 'General';
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Evita que el teclado tape el formulario
        top: 20, left: 20, right: 20,
      ),
      child: SingleChildScrollView(
        child: Form( // <-- Usamos Form para aplicar validaciones a todos los campos
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _nombreCtrl, 
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nombre del producto', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_outlined)),
                      items: categoriasDisponibles.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setState(() => _categoriaSeleccionada = val),
                    ),
                  ),
                  IconButton(
                    onPressed: _mostrarDialogoNuevaCategoria,
                    icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary, size: 30),
                    tooltip: 'Agregar nueva categoría',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Agrupamos Costo y Precio en una misma fila para mejor UX
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl, 
                      decoration: const InputDecoration(labelText: 'Costo', prefixText: '\$ '), 
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null || double.tryParse(value) == null ? 'Monto inválido' : null,
                    )
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl, 
                      decoration: const InputDecoration(labelText: 'Precio venta', prefixText: '\$ '), 
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null || double.tryParse(value) == null ? 'Monto inválido' : null,
                    )
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _cantidadCtrl, 
                decoration: const InputDecoration(labelText: 'Stock Inicial', prefixIcon: Icon(Icons.inventory_2_outlined)), 
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null ? 'Requerido' : null,
              ),
              
              if (!esEdicion) ...[
                const SizedBox(height: 15),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Restar costo de la caja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Desactívalo si es mercancía de un pedido anterior.', style: TextStyle(fontSize: 12)),
                  value: _afectaCaja,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) => setState(() => _afectaCaja = val),
                ),
              ],

              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  // Validación automática antes de procesar
                  if (_formKey.currentState!.validate()) {
                    final prod = Producto(
                      id: esEdicion ? widget.productoActual!.id : const Uuid().v4(), // Generación segura
                      nombre: _nombreCtrl.text.trim(),
                      categoria: _categoriaSeleccionada ?? 'General',
                      costo: double.parse(_costoCtrl.text),
                      precioVenta: double.parse(_precioCtrl.text),
                      cantidad: int.parse(_cantidadCtrl.text),
                    );

                    if (esEdicion) {
                      context.read<InventarioProvider>().editarProducto(prod.id, prod);
                    } else {
                      context.read<InventarioProvider>().agregarProducto(prod, afectaCaja: _afectaCaja);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  esEdicion ? 'Actualizar Producto' : 'Guardar Producto', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}