import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto.dart';
import '../../providers/inventario_provider.dart';

class ModalSalidaStock extends StatefulWidget {
  final Producto producto;
  final bool esConceptStore;

  const ModalSalidaStock({super.key, required this.producto, required this.esConceptStore});

  @override
  State<ModalSalidaStock> createState() => _ModalSalidaStockState();
}

class _ModalSalidaStockState extends State<ModalSalidaStock> {
  final _cantidadCtrl = TextEditingController();
  String _motivoSeleccionado = 'Regalo';

  final List<String> _motivos = [
    'Regalo',
    'Mercancía Dañada',
    'Extravío',
    'Uso Personal'
  ];

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int stockDisponible = widget.esConceptStore ? widget.producto.cantidadConcept : widget.producto.cantidad;
    final String origenTexto = widget.esConceptStore ? 'la Concept Store' : 'el Principal';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registrar Salida',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
          const SizedBox(height: 5),
          Text(
            'Se restará del stock de $origenTexto sin registrar ganancia en caja.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: _motivoSeleccionado,
            decoration: const InputDecoration(
              labelText: 'Motivo de la salida',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info_outline),
            ),
            items: _motivos.map((motivo) {
              return DropdownMenuItem(value: motivo, child: Text(motivo));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _motivoSeleccionado = val);
            },
          ),
          
          const SizedBox(height: 15),

          TextField(
            controller: _cantidadCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cantidad (Max: $stockDisponible)',
              prefixIcon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final qty = int.tryParse(_cantidadCtrl.text) ?? 0;
              if (qty > 0 && qty <= stockDisponible) {
                
                context.read<InventarioProvider>().registrarSalida(
                  widget.producto.id, 
                  qty, 
                  _motivoSeleccionado,
                  deConceptStore: widget.esConceptStore
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salida registrada correctamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cantidad inválida o superior al stock disponible'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Confirmar Salida', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}