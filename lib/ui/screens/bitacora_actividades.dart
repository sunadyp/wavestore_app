import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../providers/inventario_provider.dart';

class BitacoraActividades extends StatefulWidget {
  const BitacoraActividades({super.key});

  @override
  State<BitacoraActividades> createState() => _BitacoraActividadesState();
}

class _BitacoraActividadesState extends State<BitacoraActividades> {
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy • hh:mm a');
  
  final ScrollController _scrollController = ScrollController();
  
  // Iniciamos mostrando solo 20 registros
  int _limiteActual = 20; 
  final int _incremento = 20;

  @override
  void initState() {
    super.initState();
    // Escuchamos el movimiento de la pantalla
    _scrollController.addListener(() {
      // Si llegamos casi al final de la lista actual (dejamos un margen de 50 pixeles)
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        _cargarMasRegistros();
      }
    });
  }

  void _cargarMasRegistros() {
    final totalActividades = context.read<InventarioProvider>().actividades.length;
    // Solo aumentamos el límite si aún hay registros ocultos
    if (_limiteActual < totalActividades) {
      setState(() {
        _limiteActual += _incremento;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // <-- Liberar memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final actividadesTotales = provider.actividades;

    // Recortamos la lista para mostrar solo la cantidad permitida por la paginación
    final int cantidadAMostrar = min(_limiteActual, actividadesTotales.length);
    final actividadesVisibles = actividadesTotales.sublist(0, cantidadAMostrar);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Actividad'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (actividadesTotales.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Limpiar historial',
              onPressed: () => _confirmarLimpieza(context, provider),
            ),
        ],
      ),
      body: actividadesTotales.isEmpty
          ? const Center(
              child: Text(
                'No hay movimientos registrados aún.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.amber.shade50,
                  child: Text(
                    'Mostrando ${actividadesVisibles.length} de ${actividadesTotales.length} movimientos.',
                    style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController, // <-- Conectamos el controlador
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    // Añadimos +1 si hay más elementos para mostrar el indicador de carga al final
                    itemCount: _limiteActual < actividadesTotales.length 
                        ? actividadesVisibles.length + 1 
                        : actividadesVisibles.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 60),
                    itemBuilder: (context, index) {
                      // Si es el último elemento y hay más por cargar, mostramos el "cargando"
                      if (index == actividadesVisibles.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final act = actividadesVisibles[index];
                      return ListTile(
                        key: ValueKey(act.id),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.history, color: Theme.of(context).colorScheme.primary, size: 20),
                        ),
                        title: Text(
                          act.descripcion,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _dateFormatter.format(act.fecha),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmarLimpieza(BuildContext context, InventarioProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Limpiar Bitácora?'),
        content: const Text('Esto borrará todo el registro de actividades. No afecta a tus ventas, productos ni dinero en caja, solo limpia este historial visual. ¿Estás seguro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.limpiarBitacora();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Historial de actividades borrado')),
              );
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}