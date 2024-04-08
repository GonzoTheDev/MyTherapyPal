import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/models/theme.dart';

void main() {
  group('AppTheme', () {
    test('All properties are nullable', () {
      final theme = AppTheme();
      expect(theme.appBarColor, isNull);
      expect(theme.backArrowColor, isNull);
    });
  });

  group('DarkTheme', () {
    late DarkTheme darkTheme;

    setUp(() {
      darkTheme = DarkTheme();
    });

    test('Dark theme colors are set correctly', () {
      expect(darkTheme.appBarColor, equals(const Color(0xff1d1b25)));
      expect(darkTheme.backArrowColor, equals(Colors.white));
      expect(darkTheme.backgroundColor, equals(const Color(0xff272336)));
      expect(darkTheme.replyDialogColor, equals(const Color(0xff272336)));
      expect(darkTheme.linkPreviewOutgoingChatColor, equals(const Color(0xff272336)));
      expect(darkTheme.linkPreviewIncomingChatColor, equals(const Color(0xff9f85ff)));
    });

    test('Dark theme text styles are set correctly', () {
      expect(darkTheme.incomingChatLinkTitleStyle, equals(const TextStyle(color: Colors.black)));
      expect(darkTheme.outgoingChatLinkTitleStyle, equals(const TextStyle(color: Colors.white)));
      expect(darkTheme.outgoingChatLinkBodyStyle, equals(const TextStyle(color: Colors.white)));
      expect(darkTheme.incomingChatLinkBodyStyle, equals(const TextStyle(color: Colors.white)));
      expect(darkTheme.linkPreviewIncomingTitleStyle, equals(const TextStyle()));
      expect(darkTheme.linkPreviewOutgoingTitleStyle, equals(const TextStyle()));
    });
  });

  group('LightTheme', () {
    late LightTheme lightTheme;

    setUp(() {
      lightTheme = LightTheme();
    });

    test('Light theme colors are set correctly', () {
      expect(lightTheme.appBarColor, equals(Colors.white));
      expect(lightTheme.backArrowColor, equals(Colors.teal));
      expect(lightTheme.backgroundColor, equals(const Color(0xffeeeeee)));
      expect(lightTheme.replyDialogColor, equals(const Color(0xffFCD8DC)));
      expect(lightTheme.linkPreviewOutgoingChatColor, equals(const Color(0xffFCD8DC)));
      expect(lightTheme.linkPreviewIncomingChatColor, equals(const Color(0xFFEEEEEE)));
    });

    test('Light theme text styles are set correctly', () {
      expect(lightTheme.incomingChatLinkTitleStyle, equals(const TextStyle(color: Colors.black)));
      expect(lightTheme.outgoingChatLinkTitleStyle, equals(const TextStyle(color: Colors.black)));
      expect(lightTheme.outgoingChatLinkBodyStyle, equals(const TextStyle(color: Colors.grey)));
      expect(lightTheme.incomingChatLinkBodyStyle, equals(const TextStyle(color: Colors.grey)));
      expect(lightTheme.linkPreviewIncomingTitleStyle, equals(const TextStyle()));
      expect(lightTheme.linkPreviewOutgoingTitleStyle, equals(const TextStyle()));
    });
  });
}