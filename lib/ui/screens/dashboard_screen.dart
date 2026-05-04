import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/tarjeta_financiera.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Diálogo genérico para Entrada/Salida de dinero[cite: 1]
  void _mostrarDialogoDinero(BuildContext context, {required bool esInversion}) {
    final controllerMonto = TextEditingController();
    final controllerDesc = TextEditingController(); // Descripción opcional[cite: 1]

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esInversion ? 'Añadir Inversión' : 'Registrar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerDesc,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
            TextField(
              controller: controllerMonto,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto \$'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final monto = double.tryParse(controllerMonto.text) ?? 0.0;
              if (monto > 0) {
                if (esInversion) {
                  context.read<InventarioProvider>().registrarInversion(monto);
                } else {
                  context.read<InventarioProvider>().registrarGasto(monto);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final tema = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Tarjeta de Saldo Principal[cite: 1]
        TarjetaFinanciera(
          titulo: 'Saldo', 
          valor: '\$${provider.dineroEnCaja.toStringAsFixed(2)}',
          icono: Icons.account_balance_wallet, 
          colorFondo: tema.primary, 
          colorTexto: Colors.white,
        ),
        
        const SizedBox(height: 16),
        
        // BOTONES DE ACCIÓN RÁPIDA[cite: 1]
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoDinero(context, esInversion: true),
                icon: const Icon(Icons.add_chart),
                label: const Text('Inversión'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue.shade900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoDinero(context, esInversion: false),
                icon: const Icon(Icons.money_off),
                label: const Text('Gasto'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red.shade900),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),

        TarjetaFinanciera(
          titulo: 'Total de Venta (Inventario)', 
          valor: '\$${provider.dineroPosible.toStringAsFixed(2)}',
          icono: Icons.trending_up, 
          colorFondo: Colors.white, 
          colorTexto: Colors.black87,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TarjetaFinanciera(
              titulo: 'Invertido', 
              valor: '\$${provider.capitalInvertido.toStringAsFixed(2)}',
              icono: Icons.inventory, 
              colorFondo: Colors.white, 
              colorTexto: Colors.black87, 
              esPequena: true,
            )),
            const SizedBox(width: 12),
            Expanded(child: TarjetaFinanciera(
              titulo: 'Utilidad Potencial', 
              valor: '\$${provider.gananciaPotencial.toStringAsFixed(2)}',
              icono: Icons.savings, 
              colorFondo: tema.secondary, 
              colorTexto: Colors.black87, 
              esPequena: true,
            )),
          ],
        ),
      ],
    );
  }
}