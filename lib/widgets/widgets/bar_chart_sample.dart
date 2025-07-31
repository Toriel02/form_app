// lib/widgets/bar_chart_sample.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartSample extends StatelessWidget {
  final String title;
  final Map<String, int> data; // Clave: Etiqueta, Valor: Conteo
  final Color barColor;

  const BarChartSample({
    super.key,
    required this.title,
    required this.data,
    this.barColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('No hay datos disponibles para este gráfico.'),
            ],
          ),
        ),
      );
    }

    // Convertir el mapa de datos en una lista de BarChartGroupData
    // para que fl_chart pueda dibujarlos.
    final List<BarChartGroupData> barGroups = [];
    final List<String> xTitles = data.keys.toList(); // Etiquetas para el eje X

    // Ordenar las claves numéricamente si son números (para escalas)
    // Opcional: Puedes quitar esta parte si no quieres ordenar numéricamente
    xTitles.sort((a, b) {
      try {
        // Intenta parsear a int si es posible para ordenar numéricamente
        return int.parse(a).compareTo(int.parse(b));
      } catch (e) {
        // Si no son números, ordena alfabéticamente
        return a.compareTo(b);
      }
    });


    double maxY = 0;
    for (int i = 0; i < xTitles.length; i++) {
      final key = xTitles[i];
      final value = data[key]!.toDouble();
      if (value > maxY) {
        maxY = value;
      }

      barGroups.add(
        BarChartGroupData(
          x: i, // El índice es la posición en el eje X
          barRods: [
            BarChartRodData(
              toY: value,
              color: barColor,
              width: 20,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
          showingTooltipIndicators: [0], // Muestra el tooltip para cada barra
        ),
      );
    }
    // Añade un pequeño margen a maxY para que las barras no toquen la parte superior
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 5) maxY = 5; // Mínimo 5 para que el gráfico no sea demasiado pequeño

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200, // Altura fija para el gráfico
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(
                    show: false,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Mostrar la etiqueta correcta basada en el índice
                          return SideTitleWidget(
                            space: 4,
                            meta: meta,
                            child: Text(
                              xTitles[value.toInt()], // Usa la etiqueta de tu lista ordenada
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink(); // No muestra el máximo y mínimo
                          }
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: (maxY / 5).ceilToDouble(), // Intervalos más limpios
                        reservedSize: 28,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey,
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItem: (
                        BarChartGroupData group, // Tipo explícito para 'group'
                        int groupIndex,
                        BarChartRodData rod,     // Tipo explícito para 'rod'
                        int rodIndex,
                      ) {
                        // Acceso correcto al valor x del grupo
                        final label = xTitles[group.x];
                        
                        // Acceso correcto al valor Y de la barra
                        final value = rod.toY.toInt();

                        return BarTooltipItem(
                          '$label: $value', // Usar las variables locales
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}