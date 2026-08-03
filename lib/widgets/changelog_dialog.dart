import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../version.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';

/// Shows changelog on first launch after version bump, reading from assets/changelog.json.
class ChangelogDialog {
  static Future<void> showIfNew(BuildContext context) async {
    try {
      final storage = await StorageService.getInstance();
      final seen = storage.getString('seen_changelog', defaultValue: '');
      if (seen == appVersion) return;

      final isArabic = TranslationService.isArabic;
      final jsonStr = await rootBundle.loadString('assets/changelog.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final versions =
          (data['versions'] as List).cast<Map<String, dynamic>>();

      Map<String, dynamic>? entry;
      for (var v in versions) {
        if (v['version'] == appVersion) {
          entry = v;
          break;
        }
      }

      if (entry != null && context.mounted) {
        final title = entry['title'] as String? ?? '';
        final changes = (entry['changes'] as Map<String, dynamic>);
        final lines = ((changes[isArabic ? 'ar' : 'en'] as List?) ?? <dynamic>[])
            .cast<String>();

        unawaited(showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? '!جديد في الإصدار' : "What's New!",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE5C158),
                  ),
                ),
                Text(
                  'v$appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6, right: 10),
                          child: Icon(Icons.check_circle_outline,
                              size: 16, color: Color(0xFFE5C158)),
                        ),
                        Flexible(
                          child: Text(
                            line,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: Text(
                  isArabic ? 'حسناً، فهمت' : 'Got it!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ));
      }
    } catch (_) {
      // Silently skip — changelog is non-critical
    }
  }
}
