import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/inventario_provider.dart';
import '../widgets/tarjeta_financiera.dart';
import '../widgets/lista_historial_ventas.dart';
import '../widgets/lista_historial_movimientos.dart'; // <-- NUEVA IMPORTACIÓN

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  bool _fechasInicializadas = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es').then((_) {
      if (mounted) {
        setState(() {
          _fechasInicializadas = true;
        });
      }
    });
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    context.select<InventarioProvider, (int, int)>(
      (p) => (p.ventas.length, p.productos.length)
    );

    final provider = context.read<InventarioProvider>();
    final tema = Theme.of(context).colorScheme;

    if (!_fechasInicializadas) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: tema.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: tema.primary,
            tabs: const [
              Tab(text: 'Mensual', icon: Icon(Icons.calendar_month)),
              Tab(text: 'Métricas Clave', icon: Icon(Icons.star_rounded)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPestanaMensual(context, provider),
                _buildPestanaMetricas(context, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestanaMensual(BuildContext context, InventarioProvider provider) {
    final estadisticas = provider.obtenerEstadisticasMensuales();
    final promedio = provider.promedioMensual;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
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
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _mostrarDesgloseMes(context, provider, fecha, mesFormateado), // <-- Actualizado
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
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPestanaMetricas(BuildContext context, InventarioProvider provider) {
    final ticketPromedio = provider.ticketPromedio;
    final productoMasVendido = provider.productoMasVendido;
    final productoMayorIngreso = provider.productoMayorIngreso;
    final productosPorAgotarse = provider.productosPorAgotarse;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TarjetaFinanciera(
          titulo: 'Ticket Promedio de Compra', 
          valor: '\$${ticketPromedio.toStringAsFixed(2)}',
          icono: Icons.receipt_long, 
          colorFondo: Colors.white, 
          colorTexto: Colors.black87,
        ),
        const SizedBox(height: 16),

        if (productoMasVendido != null)
          _InsightCard(
            titulo: 'Producto Estrella (Más Vendido)',
            subtitulo: productoMasVendido['nombre'],
            detalle: '${productoMasVendido['cantidad']} unidades vendidas',
            icono: Icons.star,
            colorFondo: Colors.amber.shade50,
            colorIcono: Colors.amber.shade800,
          ),
        
        if (productoMasVendido != null) const SizedBox(height: 16),

        if (productoMayorIngreso != null)
          _InsightCard(
            titulo: 'Venta con Mayor Ingreso',
            subtitulo: productoMayorIngreso['nombre'],
            detalle: 'Generó \$${(productoMayorIngreso['ingreso'] as double).toStringAsFixed(2)}',
            icono: Icons.monetization_on,
            colorFondo: Colors.green.shade50,
            colorIcono: Colors.green.shade800,
          ),

        const SizedBox(height: 24),
        const Text(
          'Alerta de Stock: Por Agotarse', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)
        ),
        const SizedBox(height: 12),

        if (productosPorAgotarse.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('¡Excelente! No tienes productos con stock crítico.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...productosPorAgotarse.map((prod) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade100, width: 1.5)
            ),
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              title: Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Quedan ${prod.cantidad}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          )),
      ],
    );
  }

  // <-- ACTUALIZADO: Ahora extrae ventas y gastos, y muestra pestañas
  void _mostrarDesgloseMes(BuildContext context, InventarioProvider provider, DateTime mesSeleccionado, String nombreMes) {
    final inicioMes = DateTime(mesSeleccionado.year, mesSeleccionado.month, 1);
    final finMes = DateTime(mesSeleccionado.year, mesSeleccionado.month + 1, 0); 
    final finDelDiaMes = DateTime(finMes.year, finMes.month, finMes.day, 23, 59, 59);

    // Filtrar ventas
    final ventasDelMes = provider.obtenerVentasPorRango(inicioMes, finMes);
    ventasDelMes.sort((a, b) => b.fecha.compareTo(a.fecha));

    // Filtrar gastos/inversiones
    final movimientosDelMes = provider.movimientos.where((m) {
      return m.fecha.isAfter(inicioMes.subtract(const Duration(seconds: 1))) &&
             m.fecha.isBefore(finDelDiaMes);
    }).toList();
    movimientosDelMes.sort((a, b) => b.fecha.compareTo(a.fecha));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.85, 
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalle de $nombreMes',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                ),
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Ventas'),
                    Tab(text: 'Gastos/Ingresos'),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListaHistorialVentas(ventas: ventasDelMes),
                      ListaHistorialMovimientos(movimientos: movimientosDelMes),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

class _InsightCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String detalle;
  final IconData icono;
  final Color colorFondo;
  final Color colorIcono;

  const _InsightCard({
    required this.titulo,
    required this.subtitulo,
    required this.detalle,
    required this.icono,
    required this.colorFondo,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorIcono.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: colorIcono.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icono, color: colorIcono, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontSize: 12, color: colorIcono, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  subtitulo, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(detalle, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}