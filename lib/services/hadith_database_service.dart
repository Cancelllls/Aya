import 'dart:convert';
import 'dart:isolate';
import 'package:sqflite/sqflite.dart';

import '../utils/text_helpers.dart';

/// Parse raw hadith JSON in a background isolate to keep the UI smooth.
/// Called via [HadithDatabaseService.parseHadithJson].
List<Map<String, dynamic>> _parseHadithJson(String jsonString) {
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  List<dynamic> raw = data['hadiths'] ?? [];
  if (raw.isEmpty && data['hadith'] != null) {
    raw = data['hadith'] as List<dynamic>;
  }
  return raw.cast<Map<String, dynamic>>();
}

/// Hadith-specific database operations.
/// Separated from [DatabaseService] to keep files focused and maintainable.
class HadithDatabaseService {
  final Database _db;

  HadithDatabaseService(this._db);

  /// Parse a raw hadith JSON string in a background isolate.
  /// Use this before calling [insertHadithBook] to keep the UI smooth.
  static Future<List<Map<String, dynamic>>> parseHadithJson(
    String jsonString,
  ) async {
    return Isolate.run(() => _parseHadithJson(jsonString));
  }

  Future<bool> isHadithBookDownloaded(String bookId, String lang) async {
    final dbBookId = '${lang}_$bookId';
    final bookRes = await _db.query(
      'hadith_books',
      where: 'book_id = ?',
      whereArgs: [dbBookId],
    );
    if (bookRes.isEmpty) return false;
    // Verify actual hadiths exist — prevents zombie entries
    final count = Sqflite.firstIntValue(await _db.rawQuery(
      'SELECT COUNT(*) FROM hadiths WHERE book_id = ?',
      [dbBookId],
    ));
    return (count ?? 0) > 0;
  }

  Future<void> insertHadithBook(
    String bookId,
    String lang,
    List<dynamic> hadiths,
  ) async {
    final dbBookId = '${lang}_$bookId';

    await _db.transaction((txn) async {
      await txn.insert('hadith_books', {
        'book_id': dbBookId,
        'lang': lang,
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete('hadiths', where: 'book_id = ?', whereArgs: [dbBookId]);

      final batch = txn.batch();
      for (var h in hadiths) {
        final text = h['text'] ?? h['hadithText'] ?? h['arabic'] ?? h['body'] ?? '';
        final number = h['hadithnumber'] ?? h['hadithNumber'] ?? h['number'] ?? 0;
        batch.insert('hadiths', {
          'book_id': dbBookId,
          'hadith_number': number,
          'arabic': lang == 'ara' ? text : '',
          'english': lang == 'eng' ? text : '',
          'search_arabic': lang == 'ara'
              ? stripTashkeel(text.toString()).toLowerCase()
              : '',
          'search_english': lang == 'eng'
              ? text.toString().toLowerCase()
              : '',
          'grades': jsonEncode(h['grades'] ?? []),
        });
      }
      await batch.commit(noResult: true);
      // Populate FTS5 index
      await txn.execute(
        'INSERT INTO hadiths_fts(search_arabic, search_english) '
        'SELECT search_arabic, search_english FROM hadiths '
        'WHERE book_id = ?',
        [dbBookId],
      );
    });
  }

  Future<void> deleteHadithBook(String bookId, String lang) async {
    final dbBookId = '${lang}_$bookId';
    await _db.transaction((txn) async {
      await txn.delete('hadiths', where: 'book_id = ?', whereArgs: [dbBookId]);
      await txn.delete('hadith_books', where: 'book_id = ?', whereArgs: [dbBookId]);
    });
  }

  Future<List<Map<String, dynamic>>> getHadiths(
    String bookId, String lang, int limit, int offset,
  ) async {
    final dbBookId = '${lang}_$bookId';
    return await _db.query('hadiths',
      where: 'book_id = ?', whereArgs: [dbBookId],
      orderBy: 'hadith_number ASC', limit: limit, offset: offset);
  }

  Future<int> getHadithCount(String bookId, String lang) async {
    final dbBookId = '${lang}_$bookId';
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM hadiths WHERE book_id = ?', [dbBookId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>?> getHadithByNumber(
      String bookId, String lang, int hadithNumber) async {
    final dbBookId = '${lang}_$bookId';
    final results = await _db.query('hadiths',
      where: 'book_id = ? AND hadith_number = ?',
      whereArgs: [dbBookId, hadithNumber],
      limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> searchHadiths(
    String bookId, String lang, String query, int limit, int offset,
  ) async {
    final dbBookId = '${lang}_$bookId';
    final cleanQuery = stripTashkeel(query).toLowerCase();
    final intQuery = int.tryParse(query);

    // FTS5 MATCH for instant single-book search
    try {
      if (intQuery != null) {
        return await _db.rawQuery(
          'SELECT h.* FROM hadiths h '
          'LEFT JOIN hadiths_fts f ON h.id = f.rowid '
          'WHERE h.book_id = ? AND (h.hadith_number = ? OR hadiths_fts MATCH ?) '
          'ORDER BY hadiths_fts MATCH ? IS NULL, h.hadith_number ASC '
          'LIMIT ? OFFSET ?',
          [dbBookId, intQuery, '"$cleanQuery"', '"$cleanQuery"', limit, offset],
        );
      }
      return await _db.rawQuery(
        'SELECT h.* FROM hadiths h '
        'INNER JOIN hadiths_fts f ON h.id = f.rowid '
        'WHERE h.book_id = ? AND hadiths_fts MATCH ? '
        'ORDER BY rank LIMIT ? OFFSET ?',
        [dbBookId, '"$cleanQuery"', limit, offset],
      );
    } catch (_) {
      // Fallback: LIKE
      final p = '%${stripTashkeel(query).toLowerCase()}%';
      if (intQuery != null) {
        return await _db.query('hadiths',
          where: 'book_id = ? AND (hadith_number = ? OR search_arabic LIKE ? OR search_english LIKE ?)',
          whereArgs: [dbBookId, intQuery, p, p],
          orderBy: 'hadith_number ASC', limit: limit, offset: offset);
      }
      return await _db.query('hadiths',
        where: 'book_id = ? AND (search_arabic LIKE ? OR search_english LIKE ?)',
        whereArgs: [dbBookId, p, p],
        orderBy: 'hadith_number ASC', limit: limit, offset: offset);
    }
  }

  Future<List<Map<String, dynamic>>> searchAllHadiths(
    String lang, String query, int limit,
    {List<String>? excludeBookIds}) async {
    final cleanQuery = stripTashkeel(query).toLowerCase();
    final langPrefix = '${lang}_%';
    final intQuery = int.tryParse(query);

    // FTS5 MATCH for instant cross-book search
    try {
      if (intQuery != null) {
        return await _db.rawQuery(
          'SELECT h.* FROM hadiths h '
          'LEFT JOIN hadiths_fts f ON h.id = f.rowid '
          'WHERE h.book_id LIKE ? AND (h.hadith_number = ? OR hadiths_fts MATCH ?) '
          'LIMIT ?',
          [langPrefix, intQuery, '"$cleanQuery"', limit],
        );
      }
      return await _db.rawQuery(
        'SELECT h.* FROM hadiths h '
        'INNER JOIN hadiths_fts f ON h.id = f.rowid '
        'WHERE h.book_id LIKE ? AND hadiths_fts MATCH ? '
        'ORDER BY rank LIMIT ?',
        [langPrefix, '"$cleanQuery"', limit],
      );
    } catch (_) {
      // Fallback: LIKE
      final p = '%${stripTashkeel(query).toLowerCase()}%';
      if (intQuery != null) {
        return await _db.query('hadiths',
          where: 'book_id LIKE ? AND (hadith_number = ? OR search_arabic LIKE ? OR search_english LIKE ?)',
          whereArgs: [langPrefix, intQuery, p, p],
          orderBy: 'hadith_number ASC', limit: limit);
      }
      return await _db.query('hadiths',
        where: 'book_id LIKE ? AND (search_arabic LIKE ? OR search_english LIKE ?)',
        whereArgs: [langPrefix, p, p],
        orderBy: 'hadith_number ASC', limit: limit);
    }
  }

  Future<String?> getCachedTranslation(String textHash) async {
    final results = await _db.query('hadith_translations',
      where: 'text_hash = ?', whereArgs: [textHash], limit: 1);
    if (results.isEmpty) return null;
    return results.first['translated_text'] as String?;
  }

  Future<void> cacheTranslation(
    String textHash, String sourceText, String translatedText, String targetLang,
  ) async {
    await _db.insert('hadith_translations', {
      'text_hash': textHash,
      'source_text': sourceText,
      'translated_text': translatedText,
      'target_lang': targetLang,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
