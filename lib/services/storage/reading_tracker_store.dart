import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';

/// Focused store for Quran reading progress, bookmarks, and audio playback positions.
class ReadingTrackerStore {
  final SharedPreferences _prefs;
  final DatabaseService _db;

  ReadingTrackerStore(this._prefs, this._db);

  // ── Bookmarks ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final list = await _db.getBookmarks();
    return list
        .map(
          (b) => {
            'surahNumber': b['surah_number'],
            'surahName': b['surah_name'],
            'ayahNumber': b['ayah_number'],
          },
        )
        .toList();
  }

  Future<void> addBookmark(
    int surahNumber,
    String surahName,
    int ayahNumber,
  ) async {
    await _db.addBookmark(surahNumber, surahName, ayahNumber);
  }

  Future<void> removeBookmark(int surahNumber, {int? ayahNumber}) async {
    await _db.removeBookmark(surahNumber, ayah: ayahNumber);
  }

  // ── Last Read Position ─────────────────────────────────────
  Future<void> saveLastReadPosition(int surahNum, int ayahNum) async {
    await _prefs.setInt('last_read_surah', surahNum);
    await _prefs.setInt('last_read_ayah', ayahNum);
    await _prefs.setInt('last_read_ayah_surah_$surahNum', ayahNum);
  }

  Map<String, int>? getLastReadPosition() {
    final surahNum = _prefs.getInt('last_read_surah');
    final ayahNum = _prefs.getInt('last_read_ayah');
    if (surahNum != null && ayahNum != null) {
      return {'surah': surahNum, 'ayah': ayahNum};
    }
    return null;
  }

  int? getLastReadAyahForSurah(int surahNum) {
    return _prefs.getInt('last_read_ayah_surah_$surahNum');
  }

  // ── Last Audio Position ────────────────────────────────────
  Future<void> saveLastAudioPosition(
    int surahNum,
    int ayahNum,
    String reciter,
    String surahName,
  ) async {
    await _prefs.setInt('last_audio_surah', surahNum);
    await _prefs.setInt('last_audio_ayah', ayahNum);
    await _prefs.setString('last_audio_reciter', reciter);
    await _prefs.setString('last_audio_surah_name', surahName);
  }

  Future<void> saveLastAudioTimestamp(int positionMs) async {
    await _prefs.setInt('last_audio_timestamp_ms', positionMs);
  }

  Map<String, dynamic>? getLastAudioPosition() {
    final surahNum = _prefs.getInt('last_audio_surah');
    final ayahNum = _prefs.getInt('last_audio_ayah');
    final reciter = _prefs.getString('last_audio_reciter');
    final surahName =
        _prefs.getString('last_audio_surah_name') ?? "Surah $surahNum";
    if (surahNum != null && ayahNum != null && reciter != null) {
      return {
        'surah': surahNum,
        'ayah': ayahNum,
        'reciter': reciter,
        'surahName': surahName,
      };
    }
    return null;
  }

  int? getLastAudioTimestamp() {
    return _prefs.getInt('last_audio_timestamp_ms');
  }
}
