import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../services/quran_verses.dart';

class WelcomeHeader extends StatelessWidget {
  final bool isDark;
  final PredefinedVerse _randomVerse;

  const WelcomeHeader({
    Key? key,
    required this.isDark,
    required PredefinedVerse randomVerse,
  })  : _randomVerse = randomVerse,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF042F1A), const Color(0xFF02170D)]
              : [const Color(0xFF0D9488), const Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.t('welcome'),
            style: TextStyle(
              color: isDark
                  ? const Color(0xFFE5C158)
                  : Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TranslationService.t('blessed_day'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _randomVerse.getDisplayString(TranslationService.isArabic),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
