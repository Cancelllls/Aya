import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/tajweed_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TajweedRuleInfo', () {
    test('contains all 6 fundamental tajweed rule types', () {
      expect(TajweedRuleInfo.rules.containsKey(TajweedRuleType.ghunnah), isTrue);
      expect(TajweedRuleInfo.rules.containsKey(TajweedRuleType.qalqalah), isTrue);
      expect(TajweedRuleInfo.rules.containsKey(TajweedRuleType.ikhfa), isTrue);
      expect(TajweedRuleInfo.rules.containsKey(TajweedRuleType.idgham), isTrue);
      expect(TajweedRuleInfo.rules.containsKey(TajweedRuleType.iqlab), isTrue);
      expect(TajweedRuleInfo.rules.containsKey(TajweedRuleType.madd), isTrue);
    });

    test('each rule has Arabic and English names and descriptions', () {
      for (final rule in TajweedRuleInfo.rules.values) {
        expect(rule.nameAr, isNotEmpty);
        expect(rule.nameEn, isNotEmpty);
        expect(rule.descriptionAr, isNotEmpty);
        expect(rule.descriptionEn, isNotEmpty);
        expect(rule.color, isNotNull);
      }
    });

    test('rule colors are distinct and valid', () {
      final colors = TajweedRuleInfo.rules.values.map((r) => r.color).toSet();
      expect(colors.length, equals(TajweedRuleInfo.rules.length));
    });
  });

  group('TajweedService.buildSpans', () {
    testWidgets('returns single plain span when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              const text = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
              final spans = TajweedService.buildSpans(
                text: text,
                baseStyle: const TextStyle(fontSize: 20),
                context: context,
                isEnabled: false,
              );
              expect(spans.length, equals(1));
              expect((spans.first as TextSpan).text, equals(text));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('handles empty string gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final spans = TajweedService.buildSpans(
                text: '',
                baseStyle: const TextStyle(fontSize: 20),
                context: context,
                isEnabled: true,
              );
              expect(spans.length, equals(1));
              expect((spans.first as TextSpan).text, isEmpty);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('detects Ghunnah on Nun or Mim with Shaddah', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              const text = 'نّ مّ';
              final spans = TajweedService.buildSpans(
                text: text,
                baseStyle: const TextStyle(fontSize: 20),
                context: context,
                isEnabled: true,
              );
              expect(spans.isNotEmpty, isTrue);
              final hasGhunnahColor = spans.any(
                (s) => s is TextSpan && s.style?.color == const Color(0xFFFF4081),
              );
              expect(hasGhunnahColor, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('detects Qalqalah letters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              const text = 'قْ طْ بْ جْ دْ';
              final spans = TajweedService.buildSpans(
                text: text,
                baseStyle: const TextStyle(fontSize: 20),
                context: context,
                isEnabled: true,
              );
              expect(spans.isNotEmpty, isTrue);
              final hasQalqalahColor = spans.any(
                (s) => s is TextSpan && s.style?.color == const Color(0xFF29B6F6),
              );
              expect(hasQalqalahColor, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
