import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/venta.dart';
import '../../models/movimiento.dart'; // <-- NUEVO IMPORT

class VentasChart extends StatelessWidget {
  final List<Venta> ventasSemana;
  final List<Movimiento> movimientosSemana; // <-- NUEVO PARÁMETRO

  const VentasChart({
    super.key, 
    required this.ventasSemana,
    required this.movimientosSemana, // <-- Requerido
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220, // Lo hice un poquito más alto para que quepa la leyenda
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
                maxY: _getMaxY(),
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
                barGroups: _generarGrupos(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generarGrupos() {
    List<double> ventasPorDia = List.filled(7, 0.0);
    List<double> gastosPorDia = List.filled(7, 0.0);

    // Sumar ventas
    for (var venta in ventasSemana) {
      int index = venta.fecha.weekday - 1;
      if (index >= 0 && index < 7) {
        ventasPorDia[index] += venta.totalFinal; 
      }
    }

    // Sumar gastos (ignoramos las inversiones para esta gráfica)
    for (var mov in movimientosSemana) {
      int index = mov.fecha.weekday - 1;
      if (index >= 0 && index < 7) {
        if (!mov.esInversion) {
          gastosPorDia[index] += mov.monto;
        }
      }
    }

    // Generar las barras dobles
    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 4, // Espacio entre la barra de venta y la de gasto
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
    });
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

  double _getMaxY() {
    double maxMonto = 0;
    List<double> ventas = List.filled(7, 0.0);
    List<double> gastos = List.filled(7, 0.0);

    for (var v in ventasSemana) {
      int idx = v.fecha.weekday - 1;
      if (idx >= 0 && idx < 7) ventas[idx] += v.totalFinal;
    }
    for (var m in movimientosSemana) {
      int idx = m.fecha.weekday - 1;
      if (idx >= 0 && idx < 7 && !m.esInversion) gastos[idx] += m.monto;
    }

    for (int i = 0; i < 7; i++) {
      if (ventas[i] > maxMonto) maxMonto = ventas[i];
      if (gastos[i] > maxMonto) maxMonto = gastos[i];
    }
    
    return maxMonto == 0 ? 100 : maxMonto * 1.2;
  }
}

// Widget auxiliar para la leyenda
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