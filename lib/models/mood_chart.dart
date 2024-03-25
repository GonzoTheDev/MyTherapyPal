import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoodChart extends StatelessWidget {
  final Map<DateTime, Map<String, int>> aggregatedData;

  MoodChart(this.aggregatedData, {super.key});

  @override
  Widget build(BuildContext context) {
    
    // Generate the last 7 days to ensure all are represented
    List<DateTime> last7Days = List.generate(7, (index) => DateTime.now().subtract(Duration(days: index))).reversed.toList().map((date) => DateTime(date.year, date.month, date.day)).toList();

    return BarChart(BarChartData(
      barGroups: _createBarGroups(aggregatedData, createEmojiColorMap(), createEmojiMoodMap(), last7Days),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              // Use last7Days for generating labels to ensure all days are covered
              if (value.toInt() < last7Days.length) {
                final DateTime date = last7Days[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.all(4.0), // Add padding for better alignment
                  child: Text(
                    DateFormat('MMM dd').format(date), // Format date
                    style: const TextStyle(color: Colors.black, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      // Assuming you're handling touch interactions with aggregatedData to display tooltips
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: const Color.fromARGB(141, 0, 150, 135),
          tooltipPadding: const EdgeInsets.all(4.0),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final date = last7Days[group.x.toInt()];
            final dataForDate = aggregatedData[date];
            if (dataForDate != null) {
              String tooltipText = dataForDate.entries.fold("", (previousValue, entry) {
              final mood = createEmojiMoodMap()[entry.key]; 
              return "$previousValue${entry.key} $mood: ${entry.value}\n"; 
            }).trim();
              return BarTooltipItem(tooltipText, const TextStyle(color: Colors.white));
            }
            return null;
          },
        ),
      ),
    ));
  }


  final List<Map<String, dynamic>> moods = [
    {'emoji': '😁', 'mood': 'Very Happy', 'color': const Color.fromARGB(255, 0, 102, 4)}, 
    {'emoji': '🙂', 'mood': 'Happy', 'color': const Color.fromARGB(255, 49, 192, 61)}, 
    {'emoji': '😌', 'mood': 'Calm', 'color': const Color.fromARGB(255, 35, 184, 134)}, 
    {'emoji': '😢', 'mood': 'Very Sad', 'color': const Color.fromARGB(255, 44, 36, 116)}, 
    {'emoji': '🙁', 'mood': 'Sad', 'color': const Color.fromARGB(255, 63, 80, 179)},
    {'emoji': '😰', 'mood': 'Anxious', 'color': const Color.fromARGB(255, 180, 101, 194)}, 
    {'emoji': '😎', 'mood': 'Cool', 'color': const Color.fromARGB(255, 231, 140, 36)}, 
    {'emoji': '😜', 'mood': 'Silly', 'color': const Color.fromARGB(255, 220, 57, 111)}, 
    {'emoji': '😐', 'mood': 'Indifferent', 'color': const Color(0xFF9E9E9E)}, 
    {'emoji': '😥', 'mood': 'Disappointed', 'color': const Color(0xFF64B5F6)}, 
    {'emoji': '😓', 'mood': 'Stressed', 'color': const Color(0xFF9C27B0)}, 
    {'emoji': '😨', 'mood': 'Scared', 'color': const Color(0xFF546E7A)}, 
    {'emoji': '😳', 'mood': 'Embarrassed', 'color': const Color(0xFFF48FB1)}, 
    {'emoji': '😱', 'mood': 'Shocked', 'color': const Color(0xFF7C4DFF)}, 
    {'emoji': '😠', 'mood': 'Angry', 'color': const Color(0xFFD32F2F)}, 
    {'emoji': '😡', 'mood': 'Very Angry', 'color': const Color(0xFFB71C1C)}, 
    {'emoji': '😴', 'mood': 'Sleepy', 'color': const Color(0xFFB39DDB)}, 
    {'emoji': '😪', 'mood': 'Tired', 'color': const Color(0xFF607D8B)}, 
    {'emoji': '🤤', 'mood': 'Hungry', 'color': const Color.fromARGB(255, 112, 86, 84)}, 
    {'emoji': '🤢', 'mood': 'Nauseous', 'color': const Color.fromARGB(255, 153, 219, 77)}, 
    {'emoji': '🤒', 'mood': 'Sick', 'color': const Color(0xFFCDDC39)}, 
    {'emoji': '🤮', 'mood': 'Very Sick', 'color': const Color(0xFF4CAF50)}, 
    {'emoji': '🤕', 'mood': 'Hurt', 'color': const Color.fromARGB(255, 163, 57, 18)}, 
  ];

  Map<String, Color> createEmojiColorMap() {
    Map<String, Color> emojiColorMap = {};
    for (var mood in moods) {
      emojiColorMap[mood['emoji']] = mood['color'];
    }
    return emojiColorMap;
  }
  Map<String, String> createEmojiMoodMap() {
    Map<String, String> emojiMoodMap = {};
    for (var mood in moods) {
      emojiMoodMap[mood['emoji']] = mood['mood'];
    }
    return emojiMoodMap;
  }

  List<BarChartGroupData> _createBarGroups(
      Map<DateTime, Map<String, int>> aggregatedData,
      Map<String, Color> emojiColorMap,
      Map<String, String> emojiMoodMap,
      List<DateTime> last7Days) {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < last7Days.length; i++) {
      DateTime day = last7Days[i];
      Map<String, int> emojiCounts = aggregatedData[day] ?? {};
      
      List<BarChartRodData> rods = [];
      if (emojiCounts.isNotEmpty) {
        double totalY = 0;
        List<BarChartRodStackItem> rodStackItems = [];
        emojiCounts.forEach((emoji, count) {
          final color = emojiColorMap[emoji] ?? Colors.grey;
          final startY = totalY;
          totalY += count.toDouble();
          rodStackItems.add(BarChartRodStackItem(startY, totalY, color));
        });
        
        rods.add(BarChartRodData(
          toY: totalY, 
          rodStackItems: rodStackItems,
          width: 36,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ));
      } else {
        rods.add(BarChartRodData(
          toY: 0, 
          rodStackItems: [], 
        ));
      }
      
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: rods,
      ));

    }

    return barGroups;
  }
}
