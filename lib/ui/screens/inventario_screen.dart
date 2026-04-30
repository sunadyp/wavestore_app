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
  // Estado para el filtro actual
  String _categoriaSeleccionada = 'Todas';

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
    final inventarioBuscador = provider.productos;

    // Extraer categorías únicas dinámicamente de lo que hay en inventario
    final Set<String> categoriasUnicas = {'Todas'};
    for (var p in inventarioBuscador) {
      categoriasUnicas.add(p.categoria);
    }

    // Aplicar el filtro de los chips sobre los resultados del buscador
    final inventarioFiltrado = _categoriaSeleccionada == 'Todas'
        ? inventarioBuscador
        : inventarioBuscador.where((p) => p.categoria == _categoriaSeleccionada).toList();

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
              onChanged: (value) => provider.filtrar(value), // Filtra en tiempo real
            ),
          ),
          
          // 2. Filtros por Categoría (Chips)
          SizedBox(
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
          ),
          
          // 3. Lista de productos filtrada
          Expanded(
            child: inventarioFiltrado.isEmpty 
              ? const Center(child: Text('No hay productos que coincidan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: inventarioFiltrado.length,
                  itemBuilder: (context, index) => ItemProducto(producto: inventarioFiltrado[index]),
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