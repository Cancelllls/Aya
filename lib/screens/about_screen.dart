import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../services/sharh_cache_service.dart';
import '../version.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _cacheRunning = false;
  String _cacheStatus = '';
  String _cacheProgress = '';
  final _logLines = <String>[];
  SharhCacheService? _cacheService;

  @override
  void dispose() {
    _cacheService?.cancel();
    super.dispose();
  }

  Future<void> _startCaching() async {
    setState(() {
      _cacheRunning = true;
      _cacheStatus = 'Starting...';
      _logLines.clear();
    });

    _cacheService = SharhCacheService(
      onLog: (msg) {
        if (mounted) {
          setState(() {
            _logLines.insert(0, msg);
            if (_logLines.length > 50) _logLines.removeLast();
            _cacheStatus = msg;
          });
        }
      },
      onProgress: (done, total) {
        if (mounted) {
          setState(() {
            _cacheProgress = '$done / $total';
          });
        }
      },
    );

    try {
      // Cache all 6 books — grading is automatic for Bukhari/Muslim,
      // but explanations (sharh) are valuable for every book.
      final books = ['bukhari', 'muslim', 'tirmidhi', 'abudawud', 'nasai', 'ibnmajah'];
      for (var bookId in books) {
        if (mounted) {
          setState(() => _cacheStatus = 'Caching $bookId...');
        }
        await _cacheService!.cacheBook(bookId, 'ara');
      }
      if (mounted) {
        setState(() => _cacheStatus = 'Done!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cacheStatus = 'Error: $e');
      }
    }

    if (mounted) {
      setState(() => _cacheRunning = false);
    }
  }

  Future<void> _checkCache() async {
    final service = SharhCacheService(onLog: (_) {});
    try {
      final stats = await service.getCacheStats();
      final sizeKb = await service.getCacheSize();
      final path = await service.getCachePath();
      if (mounted) {
        setState(() {
          _cacheStatus = 'Cached: ${stats.entries.map((e) => '${e.key}=${e.value}').join(', ')}';
          _logLines.insert(0, '📦 ${sizeKb}KB at $path');
          if (stats.isNotEmpty) {
            _logLines.insert(0, stats.entries.map((e) => '  ${e.key}: ${e.value}').join('\n'));
          }
          _cacheProgress = '$sizeKb KB';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cacheStatus = 'No cache yet');
      }
    }
  }

  Future<void> _exportCache() async {
    try {
      final service = SharhCacheService(onLog: (_) {});
      final path = await service.exportToDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported to $path'),
            backgroundColor: const Color(0xFFE5C158),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = TranslationService.isArabic;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isArabic ? "حول التطبيق" : "About Aya",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
              ),
              child: Icon(Icons.mosque, size: 80, color: theme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? "تطبيق آية" : "Aya App",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic ? "الإصدار $appVersion" : "Version $appVersion",
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      isArabic
                          ? "تم تطوير هذا التطبيق كصدقة جارية، ليرافقك في رحلتك الإيمانية مع القرآن الكريم والأذكار اليومية ومواقيت الصلاة."
                          : "This application is developed as a continuous charity (Sadaqah Jariyah), to accompany you on your spiritual journey with the Holy Quran, daily supplications, and prayer times.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? "المطور" : "Developer",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: theme.primaryColor),
                ),
                title: const Text(
                  "Created specially for you",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isArabic
                      ? "صُنع بكل حب لخدمة الإسلام"
                      : "Made with love to serve Islam",
                ),
              ),
            ),

            // ── Developer / Cache Section ──
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              isArabic ? "ذاكرة التخزين المؤقت للشروح" : "Sharh Cache (Dev)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            if (_cacheStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _cacheStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_cacheProgress.isNotEmpty && _cacheRunning)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(
                  value: _cacheProgress.contains('/')
                      ? () {
                          final parts = _cacheProgress.split(' / ');
                          if (parts.length == 2) {
                            final d = int.tryParse(parts[0]) ?? 0;
                            final t = int.tryParse(parts[1]) ?? 1;
                            return t > 0 ? d / t : 0.0;
                          }
                          return null;
                        }()
                      : null,
                  color: const Color(0xFFE5C158),
                  backgroundColor: const Color(0xFFE5C158).withOpacity(0.2),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _cacheRunning ? null : _startCaching,
                  icon: Icon(
                    _cacheRunning ? Icons.hourglass_bottom : Icons.download,
                    size: 16,
                  ),
                  label: Text(
                    _cacheRunning
                        ? (_logLines.where((l) => !l.startsWith('  ')).firstOrNull ?? 'Running...')
                        : (isArabic ? 'تحميل الشروح' : 'Pre-cache Sharh'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE5C158),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _cacheRunning ? null : _checkCache,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(
                    isArabic ? 'فحص' : 'Check',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _cacheRunning ? null : _exportCache,
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(
                    isArabic ? 'تصدير' : 'Export',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            if (_cacheRunning)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    _cacheService?.cancel();
                    setState(() => _cacheRunning = false);
                  },
                  child: Text(
                    isArabic ? 'إيقاف' : 'Stop',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ),
            if (_logLines.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    _logLines.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFF88CC88),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),
            Text(
              isArabic
                  ? "جميع الحقوق محفوظة © ٢٠٢٦"
                  : "All rights reserved © 2026",
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
