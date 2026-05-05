import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/tarjeta_financiera.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  // Capitaliza la primera letra del mes para que se vea más estético
  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Inicializar formato de fechas en español si es necesario
    initializeDateFormatting('es');
    
    final provider = context.watch<InventarioProvider>();
    final estadisticas = provider.obtenerEstadisticasMensuales();
    final promedio = provider.promedioMensual;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Desempeño Mensual', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 16),

        // TARJETA DE PROMEDIO GLOBAL
        TarjetaFinanciera(
          titulo: 'Promedio de Ganancia Mensual', 
          valor: '\$${promedio.toStringAsFixed(2)}',
          icono: Icons.auto_graph_rounded, 
          colorFondo: Theme.of(context).colorScheme.primary, 
          colorTexto: Colors.white,
        ),
        
        const SizedBox(height: 24),
        const Text(
          'Historial por Mes', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 12),

        if (estadisticas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Column(
                children: [
                  Icon(Icons.insert_chart_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no hay datos suficientes\npara mostrar estadísticas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          // LISTA DE MESES
          ...estadisticas.map((stat) {
            final fecha = stat['fecha'] as DateTime;
            final mesFormateado = _capitalizar(DateFormat.yMMMM('es').format(fecha));
            final ingresos = stat['ingresos'] as double;
            final gastos = stat['gastos'] as double;
            final ganancia = stat['ganancia'] as double;

            final esGananciaPositiva = ganancia >= 0;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mesFormateado,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: esGananciaPositiva ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${esGananciaPositiva ? '+' : ''}\$${ganancia.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: esGananciaPositiva ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetalleMonto(
                          titulo: 'Ventas',
                          monto: ingresos,
                          color: Colors.blue.shade700,
                        ),
                        _DetalleMonto(
                          titulo: 'Gastos',
                          monto: gastos,
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// Widget auxiliar para mostrar Ventas y Gastos limpios dentro de la tarjeta
class _DetalleMonto extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color color;

  const _DetalleMonto({
    required this.titulo,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}