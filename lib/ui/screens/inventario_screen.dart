import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/item_producto.dart';
import '../widgets/formulario_producto.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  // Función interna para no repetir código del modal
  void _mostrarFormulario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FormularioProducto(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final inventario = provider.productos;

    return Scaffold(
      body: Column(
        children: [
          // 1. Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => provider.filtrar(value), // Filtra en tiempo real
            ),
          ),
          
          // 2. Lista de productos filtrada
          Expanded(
            child: inventario.isEmpty 
              ? const Center(child: Text('No hay productos que coincidan'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: inventario.length,
                  itemBuilder: (context, index) => ItemProducto(producto: inventario[index]),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}