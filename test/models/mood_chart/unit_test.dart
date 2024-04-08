import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/models/mood_chart.dart';
import '../../test_settings.dart';

final TestSettings testSettings = TestSettings();

void main() {
  group('MoodChart', () {
    test('createEmojiColorMap returns correct mapping', () {
      final moodChart = MoodChart(const {});
      final emojiColorMap = moodChart.createEmojiColorMap();

      expect(emojiColorMap['😁'], const Color.fromARGB(255, 0, 102, 4));
      expect(emojiColorMap['🙂'], const Color.fromARGB(255, 49, 192, 61));
      expect(emojiColorMap['😌'], const Color.fromARGB(255, 35, 184, 134));
    }, skip: TestSettings.moodChart[0]['skip'] as bool);

    test('createEmojiMoodMap returns correct mapping', () {
      final moodChart = MoodChart(const {});
      final emojiMoodMap = moodChart.createEmojiMoodMap();

      expect(emojiMoodMap['😁'], 'Very Happy');
      expect(emojiMoodMap['🙂'], 'Happy');
      expect(emojiMoodMap['😌'], 'Calm');
    }, skip: TestSettings.moodChart[1]['skip'] as bool);

    
  });
}