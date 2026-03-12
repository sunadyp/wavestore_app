import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart'; // <--- Asegúrate de tener esta importación
import '/models/venta.dart';

class VentasChart extends StatelessWidget {
  final List<Venta> ventasSemana;

  const VentasChart({super.key, required this.ventasSemana});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180, // Bajamos un poco la altura para que respire
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
      // Ajuste: DateTime.weekday va de 1 (lunes) a 7 (domingo)
      int index = venta.fecha.weekday - 1;
      if (index >= 0 && index < 7) {
        montosPorDia[index] += venta.total;
      }
    }

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: montosPorDia[i],
            color: Colors.pinkAccent.shade100, // Color suave para que no canse
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
    
    // Lista de días
    const dias = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];
    
    // VALIDACIÓN CRÍTICA: Solo intentamos leer si el valor es un índice válido
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
      if (idx >= 0 && idx < 7) montos[idx] += v.total;
    }
    for (var m in montos) {
      if (m > maxMonto) maxMonto = m;
    }
    // Si no hay ventas, ponemos 100 de tope por defecto, si hay, le damos margen arriba
    return maxMonto == 0 ? 100 : maxMonto * 1.2;
  }
}