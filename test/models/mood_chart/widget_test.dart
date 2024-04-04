import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/models/mood_chart.dart';

void main() {
  testWidgets('MoodChart renders correctly', (WidgetTester tester) async {

    // Sample aggregated data
    final aggregatedData = {
      DateTime(2023, 5, 1): {'😁': 2, '🙂': 1},
      DateTime(2023, 5, 2): {'😌': 3},
      DateTime(2023, 5, 3): {'😢': 1, '🙁': 2},
    };

    // Build the widget tree
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MoodChart(aggregatedData),
      ),
    ));

    // Verify that the chart is rendered
    expect(find.byType(BarChart), findsOneWidget);

    // Verify the bar chart data
    final barChartGroupData = tester.widget<BarChart>(find.byType(BarChart)).data.barGroups;
    expect(barChartGroupData.length, 7); 

  });
}