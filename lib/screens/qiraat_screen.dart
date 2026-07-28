import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../models/quran_models.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';

class QiraatScreen extends StatefulWidget {
  const QiraatScreen({super.key});
  @override
  State<QiraatScreen> createState() => _QiraatScreenState();
}

class _QiraatScreenState extends State<QiraatScreen> {
  bool _isLoadingRiwayat = true;
  List<dynamic> _riwayat = [];
  Map<String, dynamic>? _selectedRiwayah;

  bool _isLoadingReciters = false;
  List<dynamic> _reciters = [];
  Map<String, dynamic>? _selectedReciter;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int? _playingSurah;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<Surah> _surahs = [];

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
    _loadSurahs();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  Future<void> _loadSurahs() async {
    final surahs = await ApiService.fetchSurahList();
    if (mounted) setState(() => _surahs = surahs);
  }

  Future<void> _fetchRiwayat() async {
    try {
      final lang = TranslationService.isArabic ? 'ar' : 'en';
      final res = await http.get(
        Uri.parse('https://mp3quran.net/api/v3/riwayat?language=$lang'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (mounted) {
          setState(() {
            _riwayat = data['riwayat'];
            _isLoadingRiwayat = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRiwayat = false);
    }
  }

  Future<void> _fetchReciters(int riwayahId) async {
    setState(() {
      _isLoadingReciters = true;
      _reciters = [];
      _selectedReciter = null;
    });
    try {
      final lang = TranslationService.isArabic ? 'ar' : 'en';
      final res = await http.get(
        Uri.parse(
          'https://mp3quran.net/api/v3/reciters?language=$lang&riwayah=$riwayahId',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (mounted) {
          setState(() {
            _reciters = data['reciters'];
            _isLoadingReciters = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReciters = false);
    }
  }

  Future<void> _playSurah(int surahNumber) async {
    if (_selectedReciter == null) return;
    final moshaf = _selectedReciter!['moshaf'] as List;
    if (moshaf.isEmpty) return;
    final server = moshaf[0]['server'] as String;
    final formattedNumber = surahNumber.toString().padLeft(3, '0');
    final url = server.endsWith('/')
        ? '$server$formattedNumber.mp3'
        : '$server/$formattedNumber.mp3';

    await _audioPlayer.play(UrlSource(url));
    setState(() => _playingSurah = surahNumber);
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() => _playingSurah = null);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          TranslationService.isArabic
              ? "تلاوات القراءات"
              : "Qira'at Recitations",
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isLoadingRiwayat)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          else if (_riwayat.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<Map<String, dynamic>>(
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic
                      ? "اختر الرواية"
                      : "Select Qira'ah",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                value: _selectedRiwayah,
                items: _riwayat.map((r) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: r,
                    child: Text(r['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRiwayah = val);
                    _fetchReciters(val['id']);
                  }
                },
              ),
            ),

          if (_isLoadingReciters)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          else if (_reciters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<Map<String, dynamic>>(
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic
                      ? "اختر القارئ"
                      : "Select Reciter",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                value: _selectedReciter,
                items: _reciters.map((r) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: r,
                    child: Text(r['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedReciter = val;
                    _stopAudio();
                  });
                },
              ),
            ),

          const SizedBox(height: 16),
          Expanded(
            child: _selectedReciter == null
                ? Center(
                    child: Text(
                      TranslationService.isArabic
                          ? "يرجى اختيار الرواية والقارئ"
                          : "Please select Qira'ah and Reciter",
                    ),
                  )
                : ListView.builder(
                    itemCount: _surahs.length,
                    itemBuilder: (context, index) {
                      final surah = _surahs[index];
                      final isPlaying =
                          _playingSurah == surah.number && _isPlaying;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPlaying
                              ? const Color(0xFFE5C158)
                              : theme.cardColor,
                          child: Text(
                            '${surah.number}',
                            style: TextStyle(
                              color: isPlaying ? Colors.black : null,
                            ),
                          ),
                        ),
                        title: Text(
                          TranslationService.isArabic
                              ? surah.name
                              : surah.englishName,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.stop_circle
                                : Icons.play_circle_fill,
                            color: const Color(0xFFE5C158),
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              _stopAudio();
                            } else {
                              _playSurah(surah.number);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),

          if (_playingSurah != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TranslationService.isArabic
                        ? "جاري التشغيل: سورة ${_surahs.firstWhere((s) => s.number == _playingSurah).name}"
                        : "Playing: ${_surahs.firstWhere((s) => s.number == _playingSurah).englishName}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    activeColor: const Color(0xFFE5C158),
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds > 0
                        ? _duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
