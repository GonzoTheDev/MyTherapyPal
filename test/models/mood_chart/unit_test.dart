import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/models/mood_chart.dart';

void main() {
  group('MoodChart', () {
    test('createEmojiColorMap returns correct mapping', () {
      final moodChart = MoodChart({});
      final emojiColorMap = moodChart.createEmojiColorMap();

      expect(emojiColorMap['😁'], const Color.fromARGB(255, 0, 102, 4));
      expect(emojiColorMap['🙂'], const Color.fromARGB(255, 49, 192, 61));
      expect(emojiColorMap['😌'], const Color.fromARGB(255, 35, 184, 134));
    });

    test('createEmojiMoodMap returns correct mapping', () {
      final moodChart = MoodChart(const {});
      final emojiMoodMap = moodChart.createEmojiMoodMap();

      expect(emojiMoodMap['😁'], 'Very Happy');
      expect(emojiMoodMap['🙂'], 'Happy');
      expect(emojiMoodMap['😌'], 'Calm');
    });

    
  });
}