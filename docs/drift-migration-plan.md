# Drift Migration Plan

## Status: Plan Only (Not Implemented)

---

## 1. Why Drift?

| | sqflite (current) | Drift |
|---|---|---|
| SQLite engine | Android system (no FTS5) | Bundled via FFI (FTS5 ✅) |
| Type safety | `Map<String, dynamic>` | Typed data classes (compile-time) |
| Migration API | Manual `onUpgrade` | Declarative `schemaVersion` |
| Full-text search | LIKE fallback only (slow) | FTS5 MATCH (10-50x faster) |
| APK impact | 0 | +2-3 MB (bundled SQLite with FTS5) |
| Streams/reactive | Manual polling | Built-in `watch()` streams |

---

## 2. Current Schema (15 tables, 8 indexes)

### Tables to migrate

| Table | Rows (approx) | Key queries |
|-------|--------------|-------------|
| `surahs` | 114 | `SELECT * ORDER BY number` |
| `ayahs` | 6,236 | `SELECT WHERE surah_number = ?`, `LIKE` search |
| `prayer_times_cache` | ~500 | Upsert by `cache_key`, TTL expiry |
| `bookmarks` | ~50 | Insert/delete by `(surah_number, ayah_number)` |
| `custom_dhikrs` | ~20 | CRUD by `id` |
| `monthly_prayer_cache` | ~400 | Upsert by `(year, month, day)` |
| `audio_downloads` | ~20 | Upsert by `(reciter_id, audio_type)` |
| `hadith_books` | 26 | Upsert by `book_id` |
| `hadiths` | **125,000+** | Bulk insert, `ORDER BY hadith_number`, LIKE/FTS search |
| `hadiths_fts` | 125,000+ | `MATCH` queries (virtual) |
| `prayer_tracker` | ~365/year | Upsert by `date`, range query |
| `hadith_translations` | ~500 | Upsert by `text_hash` |

---

## 3. Migration Phases

### Phase 1: Add Drift dependency (15 min)

```yaml
# pubspec.yaml
dev_dependencies:
  drift_dev: ^2.15.0
  build_runner: ^2.4.0

dependencies:
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.6.0  # already present
  drift_flutter: ^0.2.0         # for Flutter integration
```

Run `dart run build_runner build` to generate code.

### Phase 2: Define schema in `.drift` file (2 hours)

Create `lib/services/drift/database.drift`:

```sql
-- Tables match current schema exactly (same names, same column types)
-- This ensures seamless transition for existing users

CREATE TABLE surahs (
  number INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  englishName TEXT NOT NULL,
  englishNameTranslation TEXT NOT NULL,
  numberOfAyahs INTEGER NOT NULL,
  revelationType TEXT NOT NULL
);

CREATE TABLE ayahs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  surah_number INTEGER NOT NULL REFERENCES surahs(number),
  ayah_number INTEGER NOT NULL,
  global_number INTEGER NOT NULL,
  text_arabic TEXT NOT NULL,
  text_arabic_clean TEXT NOT NULL,
  text_english TEXT NOT NULL,
  tafsir TEXT,
  juz INTEGER,
  hizb INTEGER
);
CREATE INDEX idx_ayahs_surah ON ayahs(surah_number);

-- ... (all 15 tables)

-- FTS5 table (NOW WORKS because Drift bundles FTS5-enabled SQLite via FFI)
CREATE VIRTUAL TABLE hadiths_fts USING fts5(
  search_arabic, search_english,
  tokenize='unicode61 remove_diacritics 2'
);
```

### Phase 3: Create `AppDatabase` class (1 hour)

```dart
// lib/services/drift/app_database.dart
@DriftDatabase(tables: [Surahs, Ayahs, Hadiths, ...])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Schema version matches our current DB version
  @override
  int get schemaVersion => 8;

  // ... typed query methods
}
```

### Phase 4: Rewrite queries as typed methods (4 hours)

Each `DatabaseService` method becomes a Drift query:

**Before (sqflite):**
```dart
Future<List<Map<String, dynamic>>> getSurahs() async {
  return await db.query('surahs', orderBy: 'number ASC');
}
```

**After (Drift):**
```dart
Future<List<Surah>> getSurahs() {
  return (select(surahs)..orderBy([(t) => OrderingTerm(expression: t.number)])).get();
}
```

### Phase 5: Update callers (3 hours)

Affected files (12 total):
- `lib/services/storage_service.dart` — wraps DB methods
- `lib/services/api_service.dart` — Quran queries, prayer cache
- `lib/services/notification_service.dart` — prayer tracker toggle
- `lib/services/backup_service.dart` — prayer tracker export
- `lib/services/sharh_cache_service.dart` — hadith loading
- `lib/screens/hadith_screen.dart` — hadith display + search
- `lib/screens/hadith_explanation_screen.dart` — translation cache
- `lib/screens/dashboard_screen.dart` — bookmarks
- `lib/screens/bookmarks_screen.dart` — bookmarks
- `lib/screens/prayer_tracker_screen.dart` — tracker
- `lib/screens/tasbih_screen.dart` — custom dhikrs
- `lib/services/audio_manager.dart` — bookmarks

**Change pattern**: `Map<String, dynamic>` → typed data class.
```dart
// Before:
final book = bookmarks.first;
final name = book['surah_name'] as String;
final num = book['ayah_number'] as int;

// After:
final book = bookmarks.first;
final name = book.surahName;
final num = book.ayahNumber;
```

### Phase 6: Seed data migration (1 hour)

`_seedQuranData` currently uses `Batch` inserts. Drift has `batch()` with identical API:

```dart
await batch((batch) {
  batch.insertAll(surahs, SurahsCompanion(...));
  batch.insertAll(ayahs, AyahsCompanion(...));
});
```

Hadith inserts (`insertHadithBook`) use the same pattern — 125K rows in transaction. Drift supports this with `batch.insertAll` in a transaction.

### Phase 7: Testing (2 hours)

- Unit tests for each query method
- Migration test: create DB at v7, run v8 migration, verify FTS5 table exists
- Performance test: cross-book search on 125K hadiths (expect <50ms MATCH vs 500-2000ms LIKE)
- Upgrade test: install old APK → seed data → install Drift APK → data intact

### Phase 8: Rollout strategy

1. **Dual-write for 1 release**: Write to both sqflite AND Drift during transition
2. **Read from Drift, fallback to sqflite**: If Drift query fails, fall back
3. **Drop sqflite**: After one release cycle with no issues

But that's overcomplicated for a single-developer app. Better approach:

1. **Ship Drift as a new release**
2. **On first open, Drift opens the existing `aya_app.db`** (same file, same schema)
3. **Add v9 migration**: creates FTS5 table on the existing DB
4. **Zero data loss**: existing Qur'an, hadith, bookmarks, tracker data loads from the same file

---

## 4. Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Schema mismatch during migration | App crash on boot | Test on emulator with real production DB |
| Typed query syntax errors | Compile failure | `flutter analyze` catches all |
| FTS5 population OOM on 125K rows | Slow first launch | INSERT ... SELECT in transaction, already tested |
| `build_runner` code generation failures | Can't compile | Commit generated files to git (Drift supports this) |
| DB file corruption during dual-write | Data loss | Transaction-wrapped, same file, no dual-write needed |
| iOS Drift FFI compilation | CI failure | Tested — Drift works on iOS via same FFI |

---

## 5. Timeline Estimate

| Phase | Time |
|-------|------|
| Add dependencies + build_runner setup | 15 min |
| Schema definition (.drift file) | 2 hours |
| AppDatabase class + queries | 4 hours |
| Update 12 caller files | 3 hours |
| Seed data + hadith insert migration | 1 hour |
| Testing + emulator verification | 2 hours |
| CI workflow adjustment | 30 min |
| **Total** | **~13 hours** |

---

## 6. Rollback Plan

If Drift causes issues in production:

1. Revert to the previous commit (sqflite-only code is preserved in git history)
2. The DB file on users' devices is untouched — sqflite can still read it
3. Schema is identical — no data migration needed to roll back

The key safety property: **Drift opens the same SQLite file with the same schema**. There's no data export/import step. The DB file on disk doesn't change format — only which library opens it.

---

## 7. FTS5 Post-Migration: What Changes

Once Drift is active with FTS5:

**searchHadiths (single-book):**
```dart
// Goes from: LIKE '%term%' → full table scan of 125K rows → 500ms-2s
// To:       MATCH 'term'   → FTS5 index lookup          → 5-20ms
```

**searchAllHadiths (cross-book, 13 books):**
```dart
// Goes from: LIKE '%term%' across all 125K rows → 2-5s
// To:       MATCH 'term' across FTS5 index       → 10-50ms
```

This is the **primary user-facing benefit** of the entire migration.

---

## 8. Decision Points

| Decision | Recommended |
|----------|-------------|
| Commit generated files to git? | **Yes** — CI doesn't need build_runner |
| Dual-write during transition? | **No** — unnecessary risk, same file |
| Start fresh DB or use existing? | **Use existing** — zero data loss |
| Drop sqflite immediately? | **Yes** — Drift replaces it completely |
| Add on new branch or main? | **New branch** — `drift-migration` |
