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
    // 🚀 AGREGAMOS EL CONTROLADOR DE PESTAÑAS (TABS)
    return DefaultTabController(
      length: 2, // Dos pestañas: Principal y Concept Store
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Barra de búsqueda (Mantiene estado global)
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
            
            // 2. Filtros por Categoría 
            Selector<InventarioProvider, String>(
              selector: (_, provider) {
                final unicas = provider.productos.map((p) => p.categoria).toSet().toList();
                unicas.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                return ['Todas', ...unicas].join('|'); 
              },
              builder: (context, categoriasString, child) {
                final categoriasUnicas = categoriasString.split('|');
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
            
            // 3. BARRA DE PESTAÑAS (TABS)
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.home_filled), text: 'Principal'),
                Tab(icon: Icon(Icons.storefront), text: 'Concept'),
              ],
            ),

            // 4. VISTAS DE LAS PESTAÑAS (TAB VIEWS)
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

                  // 🚀 AHORA RECIBE EL PARÁMETRO
                  Widget construirLista(bool esConceptStore) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: inventarioFiltrado.length,
                      itemBuilder: (context, index) {
                        return ItemProducto(
                          // Le agregamos el bool al key para que Flutter sepa que son tarjetas distintas
                          key: ValueKey('${inventarioFiltrado[index].id}_$esConceptStore'), 
                          producto: inventarioFiltrado[index],
                          esConceptStore: esConceptStore, // <-- SE LO PASAMOS AQUÍ
                        );
                      },
                    );
                  }

                  return TabBarView(
                    children: [
                      construirLista(false), // Vista Principal
                      construirLista(true),  // Vista Concept Store
                    ],
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
      ),
    );
  }
}