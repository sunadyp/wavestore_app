import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/tarjeta_financiera.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Diálogo genérico para Entrada/Salida de dinero
  void _mostrarDialogoDinero(BuildContext context, {required bool esInversion}) {
    final controllerMonto = TextEditingController();
    final controllerDesc = TextEditingController(); // Descripción opcional

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(esInversion ? 'Añadir Inversión' : 'Registrar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerDesc,
              decoration: const InputDecoration(
                labelText: 'Descripción (Ej. Pago de luz)',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controllerMonto,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: esInversion ? Colors.blue : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final monto = double.tryParse(controllerMonto.text) ?? 0.0;
              final desc = controllerDesc.text.trim();
              
              if (monto > 0) {
                if (esInversion) {
                  context.read<InventarioProvider>().registrarInversion(monto, desc);
                } else {
                  context.read<InventarioProvider>().registrarGasto(monto, desc);
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

    // Obtenemos los datos calculados en el Provider
    final gananciaActual = provider.gananciaMesActual;
    final promedio = provider.promedioMensual;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Tarjeta de Saldo Principal
        TarjetaFinanciera(
          titulo: 'Saldo', 
          valor: '\$${provider.dineroEnCaja.toStringAsFixed(2)}',
          icono: Icons.account_balance_wallet, 
          colorFondo: tema.primary, 
          colorTexto: Colors.white,
        ),
        
        const SizedBox(height: 20),

                // --- NUEVA SECCIÓN: RENDIMIENTO DEL NEGOCIO ---
        const Text('Rendimiento del Negocio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TarjetaFinanciera(
              titulo: 'Ganancia del Mes', 
              valor: '\$${gananciaActual.toStringAsFixed(2)}',
              icono: Icons.insights, 
              // Si la ganancia es positiva o 0, fondo verde. Si es negativa, fondo rojo.
              colorFondo: gananciaActual >= 0 ? Colors.blue.shade50 : Colors.red.shade50, 
              colorTexto: gananciaActual >= 0 ? Colors.blue.shade900 : Colors.red.shade900, 
              esPequena: true,
            )),
            const SizedBox(width: 12),
            Expanded(child: TarjetaFinanciera(
              titulo: 'Promedio Mensual', 
              valor: '\$${promedio.toStringAsFixed(2)}',
              icono: Icons.query_stats, 
              colorFondo: Colors.pink.shade50, 
              colorTexto: Colors.pink.shade900, 
              esPequena: true,
            )),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // BOTONES DE ACCIÓN RÁPIDA
        Row(
          children: [
            Expanded(
              child: _BotonAccionRapida(
                titulo: 'Inversión',
                icono: Icons.trending_up_rounded,
                colorBase: Colors.green,
                onTap: () => _mostrarDialogoDinero(context, esInversion: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _BotonAccionRapida(
                titulo: 'Gasto',
                icono: Icons.money_off_rounded,
                colorBase: Colors.red,
                onTap: () => _mostrarDialogoDinero(context, esInversion: false),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // SECCIÓN: PROYECCIÓN DE INVENTARIO
        const Text('Proyección de Inventario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        TarjetaFinanciera(
          titulo: 'Total de Venta (Inventario)', 
          valor: '\$${provider.dineroPosible.toStringAsFixed(2)}',
          icono: Icons.inventory_2_outlined, 
          colorFondo: Colors.white, 
          colorTexto: Colors.black87,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TarjetaFinanciera(
              titulo: 'Invertido', 
              valor: '\$${provider.capitalInvertido.toStringAsFixed(2)}',
              icono: Icons.shopping_bag_outlined, 
              colorFondo: Colors.white, 
              colorTexto: Colors.black87, 
              esPequena: true,
            )),
            const SizedBox(width: 12),
            Expanded(child: TarjetaFinanciera(
              titulo: 'Utilidad Potencial', 
              valor: '\$${provider.gananciaPotencial.toStringAsFixed(2)}',
              icono: Icons.savings_outlined, 
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

// Botón de acción rápida con diseño de tarjeta
class _BotonAccionRapida extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final MaterialColor colorBase;
  final VoidCallback onTap;

  const _BotonAccionRapida({
    required this.titulo,
    required this.icono,
    required this.colorBase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorBase.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: colorBase.shade100,
        highlightColor: colorBase.shade200.withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorBase.shade200, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorBase.shade100,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icono, color: colorBase.shade700, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: TextStyle(
                  color: colorBase.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}