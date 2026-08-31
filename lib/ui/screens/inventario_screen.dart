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
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Barra de búsqueda
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
              onChanged: (value) => context.read<InventarioProvider>().filtrar(value), 
            ),
          ),
          
          // 2. Filtros por Categoría ordenados alfabéticamente
          Selector<InventarioProvider, String>(
            selector: (_, provider) {
              // Extraemos las categorías únicas
              final unicas = provider.productos.map((p) => p.categoria).toSet().toList();
              // Ordenamos alfabéticamente
              unicas.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
              // Anteponemos 'Todas' siempre al principio
              return ['Todas', ...unicas].join('|'); 
            },
            builder: (context, categoriasString, child) {
              final categoriasUnicas = categoriasString.split('|');
              
              // Verificamos por seguridad que la categoría seleccionada siga existiendo
              if (!categoriasUnicas.contains(_categoriaSeleccionada)) {
                _categoriaSeleccionada = 'Todas';
              }

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
          
          // 3. Lista de productos filtrada
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