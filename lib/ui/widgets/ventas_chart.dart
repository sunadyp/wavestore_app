import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/venta.dart';
import '../../models/movimiento.dart';

class VentasChart extends StatelessWidget {
  final List<Venta> ventasSemana;
  final List<Movimiento> movimientosSemana;

  const VentasChart({
    super.key, 
    required this.ventasSemana,
    required this.movimientosSemana,
  });

  @override
  Widget build(BuildContext context) {
    // Cambiamos el nombre a ingresosPorDia para que abarque Ventas e Inversiones
    List<double> ingresosPorDia = List.filled(7, 0.0);
    List<double> gastosPorDia = List.filled(7, 0.0);
    double maxMonto = 0.0;

    // 1. Sumamos las Ventas a la barra verde (Ingresos)
    for (var venta in ventasSemana) {
      int index = venta.fecha.weekday - 1;
      if (index >= 0 && index < 7) {
        // 🚀 CAMBIO: Ahora suma el ingreso neto descontando comisiones
        ingresosPorDia[index] += venta.ingresoNeto;
        if (ingresosPorDia[index] > maxMonto) maxMonto = ingresosPorDia[index];
      }
    }

    // 2. Sumamos los Movimientos (Inversiones a la verde, Gastos a la roja)
    for (var mov in movimientosSemana) {
      int index = mov.fecha.weekday - 1;
      if (index >= 0 && index < 7) {
        if (mov.esInversion) {
          // Es un ingreso/inversión manual -> Va a la barra verde
          ingresosPorDia[index] += mov.monto;
          if (ingresosPorDia[index] > maxMonto) maxMonto = ingresosPorDia[index];
        } else {
          // Es un gasto -> Va a la barra roja
          gastosPorDia[index] += mov.monto;
          if (gastosPorDia[index] > maxMonto) maxMonto = gastosPorDia[index];
        }
      }
    }

    final double maxY = maxMonto == 0 ? 100 : maxMonto * 1.2;

    return Container(
      height: 220, 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // LEYENDA
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IndicadorLeyenda(color: Colors.green.shade400, texto: 'Ventas / Ingresos'),
              const SizedBox(width: 16),
              _IndicadorLeyenda(color: Colors.red.shade400, texto: 'Gastos'),
            ],
          ),
          const SizedBox(height: 15),
          
          // GRÁFICA
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY, 
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _getBottomTitles,
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: ingresosPorDia[i], // <-- Aquí se pintan Ventas + Inversiones
                        color: Colors.green.shade400,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: gastosPorDia[i], // <-- Aquí se pintan los Gastos
                        color: Colors.red.shade400,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey, 
      fontWeight: FontWeight.bold, 
      fontSize: 12
    );
    
    const dias = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];
    
    int index = value.toInt();
    String text = (index >= 0 && index < dias.length) ? dias[index] : '';

    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }
}

class _IndicadorLeyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _IndicadorLeyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}