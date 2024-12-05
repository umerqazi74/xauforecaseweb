import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Helper function to get the date string for a given index, assuming `startDate` as the initial date.
String getDateForIndex(int index, DateTime startDate) {
  final date = startDate.add(Duration(days: index));
  return DateFormat('MM/dd').format(date); // Format as desired
}

class PredictionChart extends StatelessWidget {
  final List<double> data;
  final DateTime startDate;

  PredictionChart({required this.data, required this.startDate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 300,
          padding: EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50, // Adjust to fit larger numbers
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toStringAsFixed(2), // Format with 2 decimal places
                          style: TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50, // Adjust to fit larger numbers
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toStringAsFixed(2), // Format with 2 decimal places
                          style: TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Convert `value` to integer index
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) return Container();

                      // Get date string for the current index
                      final dateStr = getDateForIndex(index, startDate);

                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(dateStr, style: TextStyle(fontSize: 10)),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(

                  spots: List.generate(
                    data.length,
                        (index) => FlSpot(index.toDouble(), data[index]),
                  ),
                  isCurved: true,
                  barWidth: 2,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PastComparisonChart extends StatelessWidget {
  final List<double> actualData;
  final List<double> predictedData;
  final DateTime startDate;

  PastComparisonChart({
    required this.actualData,
    required this.predictedData,
    required this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50, // Adjust to fit larger numbers
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(2), // Format with 2 decimal places
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50, // Adjust to fit larger numbers
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(2), // Format with 2 decimal places
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Convert `value` to integer index
                  final index = value.toInt();
                  if (index < 0 || index >= actualData.length) return Container();

                  // Get date string for the current index
                  final dateStr = getDateForIndex(index, startDate);

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(dateStr, style: TextStyle(fontSize: 10)),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                actualData.length,
                    (index) => FlSpot(index.toDouble(), actualData[index]),
              ),
              isCurved: true,
              barWidth: 2,
              color: Colors.green,
            ),
            LineChartBarData(
              spots: List.generate(
                predictedData.length,
                    (index) => FlSpot(index.toDouble(), predictedData[index]),
              ),
              isCurved: true,
              barWidth: 2,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
