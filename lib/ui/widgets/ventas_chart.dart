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
    // 🚀 OPTIMIZACIÓN: Realizamos el cálculo de agrupaciones y del maxY 
    // en un solo bloque para evitar iterar las listas múltiples veces.
    List<double> ventasPorDia = List.filled(7, 0.0);
    List<double> gastosPorDia = List.filled(7, 0.0);
    double maxMonto = 0.0;

    for (var venta in ventasSemana) {
      int index = venta.fecha.weekday - 1;
      if (index >= 0 && index < 7) {
        ventasPorDia[index] += venta.totalFinal;
        if (ventasPorDia[index] > maxMonto) maxMonto = ventasPorDia[index];
      }
    }

    for (var mov in movimientosSemana) {
      if (!mov.esInversion) {
        int index = mov.fecha.weekday - 1;
        if (index >= 0 && index < 7) {
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
              _IndicadorLeyenda(color: Colors.green.shade400, texto: 'Ventas'),
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
                maxY: maxY, // Usamos el cálculo optimizado
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
                        toY: ventasPorDia[i],
                        color: Colors.green.shade400,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: gastosPorDia[i],
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