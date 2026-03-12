import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/tarjeta_financiera.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final tema = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Resumen Financiero', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TarjetaFinanciera(
          titulo: 'Dinero en Caja', valor: '\$${provider.dineroEnCaja.toStringAsFixed(2)}',
          icono: Icons.account_balance_wallet, colorFondo: tema.primary, colorTexto: Colors.white,
        ),
        const SizedBox(height: 12),
        TarjetaFinanciera(
          titulo: 'Venta Potencial', valor: '\$${provider.dineroPosible.toStringAsFixed(2)}',
          icono: Icons.trending_up, colorFondo: Colors.white, colorTexto: Colors.black87,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TarjetaFinanciera(
              titulo: 'Invertido', valor: '\$${provider.capitalInvertido.toStringAsFixed(2)}',
              icono: Icons.inventory, colorFondo: Colors.white, colorTexto: Colors.black87, esPequena: true,
            )),
            const SizedBox(width: 12),
            Expanded(child: TarjetaFinanciera(
              titulo: 'Ganancia', valor: '\$${provider.gananciaPotencial.toStringAsFixed(2)}',
              icono: Icons.savings, colorFondo: tema.secondary, colorTexto: Colors.black87, esPequena: true,
            )),
          ],
        ),
      ],
    );
  }
}