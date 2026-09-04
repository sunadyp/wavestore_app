import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto.dart';
import '../../providers/inventario_provider.dart';

class ModalTransferencia extends StatefulWidget {
  final Producto producto;

  const ModalTransferencia({super.key, required this.producto});

  @override
  State<ModalTransferencia> createState() => _ModalTransferenciaState();
}

class _ModalTransferenciaState extends State<ModalTransferencia> {
  final _cantidadCtrl = TextEditingController();
  bool _haciaConcept = true; // true: Principal -> Concept | false: Concept -> Principal

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int stockOrigen = _haciaConcept ? widget.producto.cantidad : widget.producto.cantidadConcept;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transferir ${widget.producto.nombre}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // Selector de dirección
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('A Concept Store')),
                    selected: _haciaConcept,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    onSelected: (val) => setState(() {
                      _haciaConcept = true;
                      _cantidadCtrl.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Al Principal')),
                    selected: !_haciaConcept,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    onSelected: (val) => setState(() {
                      _haciaConcept = false;
                      _cantidadCtrl.clear();
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          Text(
            'Stock disponible para enviar: $stockOrigen',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 5),

          TextField(
            controller: _cantidadCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad a transferir',
              prefixIcon: Icon(Icons.sync_alt),
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final qty = int.tryParse(_cantidadCtrl.text) ?? 0;
              if (qty > 0 && qty <= stockOrigen) {
                
                // 🚀 LLAMADA REAL AL PROVIDER
                context.read<InventarioProvider>().transferirStock(
                  widget.producto.id, 
                  qty, 
                  _haciaConcept
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transferencia realizada con éxito')),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cantidad inválida o superior al stock'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Confirmar Transferencia', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}