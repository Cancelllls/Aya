import 'dart:async';
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
  List<String> _selectedBooks = [];
  bool _startFresh = false;
  String? _cdnDownloading;

  static const _bookLabels = {
    'bukhari': 'Sahih al-Bukhari / صحيح البخاري',
    'muslim': 'Sahih Muslim / صحيح مسلم',
    'tirmidhi': "Jami' at-Tirmidhi / جامع الترمذي",
    'abudawud': 'Sunan Abu Dawud / سنن أبي داود',
    'nasai': "Sunan an-Nasa'i / سنن النسائي",
    'ibnmajah': 'Sunan Ibn Majah / سنن ابن ماجه',
  };

  @override
  void dispose() {
    _cacheService?.cancel();
    super.dispose();
  }

  Future<void> _startCaching() async {
    if (_selectedBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one book first')),
      );
      return;
    }

    setState(() {
      _cacheRunning = true;
      _cacheStatus = 'Starting...';
      _logLines.clear();
    });

    // Clear selected books if starting fresh
    if (_startFresh) {
      final svc = SharhCacheService(onLog: (_) {});
      for (var bookId in _selectedBooks) {
        await svc.clearBook(bookId);
      }
      _logLines.add('🧹 Cleared ${_selectedBooks.length} book(s)');
    }

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
      for (var bookId in _selectedBooks) {
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
      final done = await service.getBookProgress();
      final totals = await service.getBookTotals();
      final sizeKb = await service.getCacheSize();
      final path = await service.getCachePath();
      if (mounted) {
        setState(() {
          _cacheStatus = '';
          _logLines.clear();
          _logLines.add('📦 ${sizeKb}KB at $path');
          for (var bookId in _bookLabels.keys) {
            final d = done[bookId] ?? 0;
            final t = totals[bookId] ?? 0;
            final pct = t > 0 ? (d * 100 ~/ t) : 0;
            _logLines.add('  $bookId: $d/$t ($pct%)');
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

  Future<void> _downloadCdnBook(String bookId) async {
    setState(() {
      _cdnDownloading = bookId;
      _logLines.clear();
    });

    final service = SharhCacheService(
      onLog: (msg) {
        if (mounted) setState(() => _logLines.insert(0, msg));
      },
    );

    try {
      final added = await service.downloadFromCdn(bookId);
      if (mounted) {
        setState(() => _cdnDownloading = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $bookId: $added entries added'),
            backgroundColor: const Color(0xFFE5C158),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cdnDownloading = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $bookId: $e')),
        );
      }
    }
  }

  Future<void> _showBookPicker() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        final books = _bookLabels.keys.toList();
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Select Books to Cache'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var bookId in books)
                      CheckboxListTile(
                        title: Text(
                          _bookLabels[bookId] ?? bookId,
                          style: const TextStyle(fontSize: 13),
                        ),
                        value: _selectedBooks.contains(bookId),
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              _selectedBooks.add(bookId);
                            } else {
                              _selectedBooks.remove(bookId);
                            }
                          });
                          setState(() {});
                        },
                        dense: true,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() => _selectedBooks = books.toList());
                            setState(() {});
                          },
                          child: const Text('All', style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() => _selectedBooks = []);
                            setState(() {});
                          },
                          child: const Text('None', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Start fresh (clear existing)', style: TextStyle(fontSize: 13)),
                      value: _startFresh,
                      onChanged: (v) {
                        setDialogState(() => _startFresh = v);
                        setState(() {});
                      },
                      dense: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, _selectedBooks),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5C158),
                  ),
                  child: const Text('Done', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedBooks = result);
      if (result.isNotEmpty && !_cacheRunning) {
        unawaited(_startCaching());
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
            if (_selectedBooks.isNotEmpty && !_cacheRunning)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_selectedBooks.length} book(s) selected${_startFresh ? ' (fresh)' : ' (resume)'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
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
                  onPressed: _cacheRunning ? null : _showBookPicker,
                  icon: Icon(
                    _cacheRunning ? Icons.hourglass_bottom : Icons.download,
                    size: 16,
                  ),
                  label: Text(
                    _cacheRunning
                        ? (_logLines.where((l) => !l.startsWith('  ')).firstOrNull ?? 'Running...')
                        : (isArabic ? 'بدء' : 'Start'),
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

            // ── CDN Download Section ──
            const SizedBox(height: 16),
            const Divider(),
            Text(
              isArabic ? "تحميل الشروح الجاهزة" : "Download Pre-built Sharh",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (var bookId in ['bukhari', 'muslim', 'abudawud', 'tirmidhi', 'nasai'])
                  ActionChip(
                    avatar: Icon(
                      _cdnDownloading == bookId
                          ? Icons.hourglass_bottom
                          : Icons.cloud_download,
                      size: 14,
                    ),
                    label: Text(
                      _bookLabels[bookId]?.split(' / ').first ?? bookId,
                      style: const TextStyle(fontSize: 10),
                    ),
                    onPressed: _cdnDownloading != null || _cacheRunning
                        ? null
                        : () => _downloadCdnBook(bookId),
                    backgroundColor: const Color(0xFFE5C158).withOpacity(0.1),
                    side: const BorderSide(
                        color: Color(0xFFE5C158), width: 0.5),
                  ),
              ],
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
