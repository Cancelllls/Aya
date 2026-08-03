import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/translation_service.dart';
import '../services/database_service.dart';
import '../services/sharh_cache_service.dart';

class HadithExplanationScreen extends StatefulWidget {
  final String query;
  final String displayLang;
  final bool isSharh;
  final String? bookId;
  final int? hadithNumber;

  const HadithExplanationScreen({
    super.key,
    required this.query,
    required this.displayLang,
    this.isSharh = false,
    this.bookId,
    this.hadithNumber,
  });

  @override
  State<HadithExplanationScreen> createState() =>
      _HadithExplanationScreenState();
}

class _HadithExplanationScreenState extends State<HadithExplanationScreen> {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, String>> _parsedExplanations = [];

  // CDN download state
  bool _offeringDownload = false;
  bool _downloading = false;
  String _downloadProgress = '';
  String _downloadBookId = '';

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  Future<void> _fetchExplanation() async {
    // 1. Check offline sharh cache first
    if (widget.bookId != null && widget.hadithNumber != null) {
      try {
        final service = SharhCacheService();
        final cached = await service.cachedExplanation(
          widget.bookId!,
          widget.hadithNumber!,
        );
        if (cached != null && mounted) {
          await _showCachedResult(cached);
          return;
        }

        // Cache miss — check if CDN data is available for this book
        if (_isCdnAvailable(widget.bookId!) && mounted) {
          setState(() {
            _isLoading = false;
            _offeringDownload = true;
            _downloadBookId = widget.bookId!;
          });
          return;
        }
      } catch (_) {}
    }

    // 2. No cache, no CDN — go online
    await _fetchFromDorar();
  }

  bool _isCdnAvailable(String bookId) {
    return SharhCacheService.availableBooks.containsKey(bookId);
  }

  Future<void> _showCachedResult(Map<String, dynamic> cached) async {
    final explanation = (cached['e'] ?? '').toString();
    final grading = (cached['g'] ?? '').toString();
    final source = (cached['_source'] ?? '').toString();

    // Use correct hadith text from our database, not the scraper's search result.
    String hadithText = (cached['t'] ?? '').toString();
    if (widget.bookId != null && widget.hadithNumber != null) {
      try {
        final db = await DatabaseService.getInstance();
        final lang = widget.displayLang == 'eng' ? 'eng' : 'ara';
        final row = await db.getHadithByNumber(widget.bookId!, lang, widget.hadithNumber!);
        if (row != null) {
          final txt = lang == 'ara'
              ? (row['arabic'] as String? ?? '')
              : (row['english'] as String? ?? '');
          if (txt.trim().isNotEmpty) hadithText = txt;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _parsedExplanations = [
          {
            'text': hadithText,
            'explanation': explanation,
            'grading': grading.isNotEmpty
                ? grading
                : (source.isNotEmpty ? '\u{1F4DA} $source' : ''),
          },
        ];
        _isLoading = false;
        _downloading = false;
        _offeringDownload = false;
      });
    }
  }

  Future<void> _downloadFromCdn() async {
    setState(() {
      _downloading = true;
      _offeringDownload = false;
      _downloadProgress = 'Connecting...';
    });

    final service = SharhCacheService(
      onLog: (msg) {
        if (mounted) setState(() => _downloadProgress = msg);
      },
    );

    try {
      await service.downloadFromCdn(_downloadBookId);

      // Now check cache again for our specific hadith
      if (widget.hadithNumber != null) {
        final cached = await service.cachedExplanation(
          _downloadBookId,
          widget.hadithNumber!,
        );
        if (cached != null && mounted) {
          await _showCachedResult(cached);
          return;
        }
      }

      // Book downloaded but this hadith wasn't in it — go online
      if (mounted) {
        _downloading = false;
        await _fetchFromDorar();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _isLoading = false;
          _offeringDownload = true;
          _error = TranslationService.isArabic
              ? 'فشل التحميل: ${e.toString().split('\n').first}'
              : 'Download failed: ${e.toString().split('\n').first}';
        });
      }
    }
  }

  Future<void> _fetchFromDorar() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _offeringDownload = false;
        _downloading = false;
        _error = '';
      });
    }

    final client = DorarClient();
    try {
      List<Map<String, String>> parsed = [];
      if (widget.isSharh) {
        final sharhResults = await client.searchSharh(
          HadithSearchParams(value: widget.query, page: 1),
        );
        parsed = sharhResults.data.map((s) {
          final sharhFull = (s.sharhText ?? '')
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          String explanation = '';
          String grading = '';

          int rawiIndex = sharhFull.indexOf('الراوي');
          int takhreejIndex = sharhFull.indexOf('التخريج');

          if (rawiIndex != -1 && takhreejIndex != -1) {
            int doubleNewline = sharhFull.indexOf('\n\n', takhreejIndex);
            if (doubleNewline != -1) {
              grading = sharhFull.substring(rawiIndex, doubleNewline).trim();
              explanation = sharhFull.substring(doubleNewline).trim();
            } else {
              int endOfTakhreej = sharhFull.indexOf('\n', takhreejIndex);
              if (endOfTakhreej == -1) endOfTakhreej = sharhFull.length;
              grading = sharhFull.substring(rawiIndex, endOfTakhreej).trim();
              explanation = sharhFull.substring(endOfTakhreej).trim();
            }
          } else {
            explanation = sharhFull;
          }

          return {
            'text': (s.hadithText).replaceAll(RegExp(r'<[^>]*>'), '').trim(),
            'explanation': explanation,
            'grading': grading,
          };
        }).toList();
      } else {
        final hadithResults = await client.searchHadith(
          HadithSearchParams(value: widget.query, page: 1),
        );
        parsed = hadithResults.data
            .map(
              (h) => {
                'text': h.hadith.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                'explanation': '',
                'grading':
                    'الراوي: ${h.rawi}\n'
                    'المحدث: ${h.mohdith}\n'
                    'المصدر: ${h.book}\n'
                    'خلاصة حكم المحدث: ${h.grade}'
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .trim(),
              },
            )
            .toList();
      }

      if (widget.displayLang == 'eng' && parsed.isNotEmpty) {
        final List<Map<String, String>> translatedParsed = [];
        for (var item in parsed) {
          translatedParsed.add({
            'text': await _translateOrCache(item['text'] ?? ''),
            'explanation': await _translateOrCache(item['explanation'] ?? ''),
            'grading': await _translateOrCache(item['grading'] ?? ''),
          });
        }
        if (mounted) {
          setState(() {
            _parsedExplanations = translatedParsed;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _parsedExplanations = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('RangeError') || msg.contains('RangeError')) {
          msg = TranslationService.isArabic
              ? 'نتائج كثيرة جداً - حاول تضييق نطاق البحث'
              : 'Too many results — try a more specific query';
        }
        setState(() {
          _error = TranslationService.isArabic
              ? 'تعذر جلب النتائج. $msg'
              : 'No results found. $msg';
          _isLoading = false;
        });
      }
    } finally {
      await client.dispose();
    }
  }

  // ── Book name labels ──

  static const _bookLabels = {
    'bukhari': 'Sahih al-Bukhari',
    'muslim': 'Sahih Muslim',
    'abudawud': 'Sunan Abu Dawud',
    'tirmidhi': "Jami' at-Tirmidhi",
    'nasai': "Sunan an-Nasa'i",
    'ibnmajah': 'Sunan Ibn Majah',
  };

  static const _bookSizes = {
    'bukhari': '~6.6 MB',
    'muslim': '~3.0 MB',
    'abudawud': '~18 MB',
    'tirmidhi': '~2.5 MB',
    'nasai': '~4.2 MB',
  };

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = TranslationService.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSharh
              ? (isArabic ? "شرح الحديث" : "Hadith Explanation")
              : (isArabic ? "تخريج الحديث" : "Hadith Grading"),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: _buildBody(theme, isArabic),
    );
  }

  Widget _buildBody(ThemeData theme, bool isArabic) {
    // Loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE5C158)),
      );
    }

    // Download offer
    if (_offeringDownload) {
      return _buildDownloadOffer(theme, isArabic);
    }

    // Downloading
    if (_downloading) {
      return _buildDownloadProgress(theme, isArabic);
    }

    // Error
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Empty results
    if (_parsedExplanations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                isArabic
                    ? "لم نجد شرحاً لهذا الحديث في قاعدة البيانات."
                    : "No explanation found in our database.",
                style: TextStyle(fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5C158),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.travel_explore),
                label: Text(isArabic ? "ابحث عن الشرح عبر الإنترنت" : "Search Online",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () async {
                  final q = Uri.encodeComponent(widget.query +
                      (widget.isSharh ? (isArabic ? " شرح حديث" : " hadith explanation") : ""));
                  final url = Uri.parse("https://www.google.com/search?q=$q");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    // Results
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _parsedExplanations.length,
      itemBuilder: (context, index) {
        final item = _parsedExplanations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
          ),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: Text(
                    item['text'] ?? '',
                    style: TextStyle(fontSize: 16, height: 1.6,
                        fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                    textAlign: TextAlign.start,
                    textDirection: widget.displayLang == 'eng' ? TextDirection.ltr : TextDirection.rtl,
                  ),
                ),
                if ((item['explanation'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: Text(
                      item['explanation']!,
                      style: TextStyle(fontSize: 15, height: 1.6,
                          color: theme.textTheme.bodyLarge?.color),
                      textAlign: TextAlign.start,
                      textDirection: widget.displayLang == 'eng' ? TextDirection.ltr : TextDirection.rtl,
                    ),
                  ),
                ],
                if ((item['grading'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildBeautifulGrading(item['grading']!, theme, widget.displayLang),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadOffer(ThemeData theme, bool isArabic) {
    final bookName = _bookLabels[_downloadBookId] ?? _downloadBookId;
    final size = _bookSizes[_downloadBookId] ?? '~5 MB';
    final icon = _downloadBookId == 'bukhari' ? Icons.auto_stories : Icons.menu_book;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE5C158).withOpacity(0.1),
              ),
              child: Icon(icon, size: 64, color: const Color(0xFFE5C158)),
            ),
            const SizedBox(height: 24),
            Text(
              isArabic
                  ? 'تحميل شروح الأحاديث'
                  : 'Download Hadith Explanations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'الشروح الكلاسيكية لـ $bookName غير متوفرة بعد. قم بتحميلها مرة واحدة للوصول دون اتصال.'
                  : '$bookName sharh not yet downloaded. Get it once for offline access.',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_download, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    '$size • ${_downloadBookId == 'bukhari' ? 'Gzip' : 'JSON'} • jsDelivr CDN',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5C158),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.download),
                label: Text(
                  isArabic ? 'تحميل الآن' : 'Download Now',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _downloadFromCdn,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _fetchFromDorar,
              child: Text(
                isArabic
                    ? 'البحث عبر الإنترنت بدلاً من ذلك'
                    : 'Search online instead',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(ThemeData theme, bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Color(0xFFE5C158),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? 'جاري التحميل...' : 'Downloading...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _downloadProgress,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Grading widget (unchanged) ──

  Widget _buildBeautifulGrading(String grading, ThemeData theme, String displayLang) {
    if (grading.trim().isEmpty) return const SizedBox();

    final Map<String, String> parsed = {};
    final parts = grading.split(RegExp(r'\n|\|'));
    for (var part in parts) {
      if (part.trim().isEmpty) continue;
      final split = part.split(':');
      if (split.length >= 2) {
        final key = split[0].trim();
        final value = split.sublist(1).join(':').trim();
        if (value.isNotEmpty) parsed[key] = value;
      }
    }

    if (parsed.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(grading, style: TextStyle(
          fontSize: 13, height: 1.6, color: theme.textTheme.bodyMedium?.color),
          textAlign: TextAlign.start,
          textDirection: displayLang == 'eng' ? TextDirection.ltr : TextDirection.rtl,
        ),
      );
    }

    return Directionality(
      textDirection: displayLang == 'eng' ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: parsed.entries.map((e) {
            final isGrade = e.key.contains('حكم') || e.key.toLowerCase().contains('grade');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGrade
                          ? const Color(0xFFE5C158).withOpacity(0.2)
                          : theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(e.key, style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isGrade ? const Color(0xFFE5C158) : theme.primaryColor)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(e.value, style: TextStyle(fontSize: 14,
                          fontWeight: isGrade ? FontWeight.bold : FontWeight.normal,
                          color: theme.textTheme.bodyLarge?.color, height: 1.4)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _makeKey(String text) {
    return base64Encode(utf8.encode(text.trim())).substring(0, 200);
  }

  Future<String> _translateOrCache(String text) async {
    if (text.trim().isEmpty) return text;
    final key = _makeKey(text);
    final db = await DatabaseService.getInstance();
    final cached = await db.getCachedTranslation(key);
    if (cached != null) return cached;

    try {
      final url = Uri.parse(
        'https://lingva.ml/api/v1/ar/en/${Uri.encodeComponent(text)}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final translated = decoded['translation'] as String? ?? text;
        await db.cacheTranslation(key, text, translated, 'en');
        return translated;
      }
    } catch (_) {}
    return text;
  }
}
