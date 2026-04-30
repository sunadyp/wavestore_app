import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/venta.dart';

class VentasChart extends StatelessWidget {
  final List<Venta> ventasSemana;

  const VentasChart({super.key, required this.ventasSemana});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(enabled: true),
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
    );
  }

  List<BarChartGroupData> _generarGrupos() {
    List<double> montosPorDia = List.filled(7, 0.0);
    for (var venta in ventasSemana) {
      int index = venta.fecha.weekday - 1;
      if (index >= 0 && index < 7) {
        montosPorDia[index] += venta.totalFinal; // <--- CAMBIO AQUÍ
      }
    }

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: montosPorDia[i],
            color: Colors.pinkAccent.shade100,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
    List<double> montos = List.filled(7, 0.0);
    for (var v in ventasSemana) {
      int idx = v.fecha.weekday - 1;
      if (idx >= 0 && idx < 7) montos[idx] += v.totalFinal; // <--- CAMBIO AQUÍ
    }
    for (var m in montos) {
      if (m > maxMonto) maxMonto = m;
    }
    return maxMonto == 0 ? 100 : maxMonto * 1.2;
  }
}