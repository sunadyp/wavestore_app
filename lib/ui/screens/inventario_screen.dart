import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/item_producto.dart';
import '../widgets/formulario_producto.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String _categoriaSeleccionada = 'Todas';

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
    // 🚀 OPTIMIZACIÓN: Se eliminó el context.watch() global. 
    // Ahora esta pantalla principal es inmune a reconstrucciones innecesarias.

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Barra de búsqueda (Completamente estática)
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              // context.read() no escucha, solo ejecuta. ¡Perfecto para rendimiento!
              onChanged: (value) => context.read<InventarioProvider>().filtrar(value), 
            ),
          ),
          
          // 2. Filtros por Categoría (Selector inteligente)
          Selector<InventarioProvider, String>(
            // Retornamos un String con las categorías unidas para que Flutter sepa 
            // con exactitud milimétrica si realmente hubo un cambio o no.
            selector: (_, provider) {
              final unicas = {'Todas', ...provider.productos.map((p) => p.categoria)};
              return unicas.join('|'); 
            },
            builder: (context, categoriasString, child) {
              final categoriasUnicas = categoriasString.split('|');
              return SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: categoriasUnicas.map((categoria) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(categoria),
                        selected: _categoriaSeleccionada == categoria,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        onSelected: (bool selected) {
                          setState(() {
                            _categoriaSeleccionada = categoria;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          
          // 3. Lista de productos filtrada (Consumer localizado)
          Expanded(
            child: Consumer<InventarioProvider>(
              builder: (context, provider, child) {
                final inventarioBuscador = provider.productos;
                final inventarioFiltrado = _categoriaSeleccionada == 'Todas'
                    ? inventarioBuscador
                    : inventarioBuscador.where((p) => p.categoria == _categoriaSeleccionada).toList();

                if (inventarioFiltrado.isEmpty) {
                  return const Center(child: Text('No hay productos que coincidan'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: inventarioFiltrado.length,
                  itemBuilder: (context, index) {
                    final producto = inventarioFiltrado[index];
                    
                    // Gracias al ValueKey, cuando se actualiza el stock de un producto, 
                    // Flutter repinta SOLO esa tarjeta y deja las demás intactas.
                    return ItemProducto(
                      key: ValueKey(producto.id), 
                      producto: producto,
                    );
                  },
                );
              },
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