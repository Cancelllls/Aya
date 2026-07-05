import re

with open('lib/screens/surah_reader_screen.dart', 'r') as f:
    content = f.read()

# 1. Add imports
content = content.replace("import 'dart:async';", "import 'dart:async';\nimport 'dart:convert';\nimport 'package:http/http.dart' as http;")

# 2. Add state variables
state_vars = """
  bool _isLoadingReciters = false;
  List<dynamic> _dynamicReciters = [];
"""
content = content.replace("bool _hideContinuousBorders = false;", "bool _hideContinuousBorders = false;\n" + state_vars)

# 3. Add fetch method before initState
fetch_method = """
  Future<void> _fetchDynamicReciters(String scriptType) async {
    if (scriptType == 'hafs') {
      if (mounted) setState(() { _dynamicReciters = []; });
      return;
    }
    
    // Map script type to mp3quran riwayah id
    int riwayahId = 1;
    switch (scriptType) {
      case 'warsh': riwayahId = 2; break;
      case 'qaloon': riwayahId = 5; break;
      case 'shuba': riwayahId = 15; break;
      case 'duri': riwayahId = 13; break;
      case 'susi': riwayahId = 7; break;
      case 'bazzi': riwayahId = 4; break;
      case 'qunbul': riwayahId = 6; break;
      case 'hisham': riwayahId = 19; break;
      case 'ibn-dhakwan': riwayahId = 16; break;
    }

    if (mounted) setState(() => _isLoadingReciters = true);
    try {
      final lang = TranslationService.isArabic ? 'ar' : 'eng';
      final res = await http.get(Uri.parse('https://mp3quran.net/api/v3/reciters?language=$lang&riwayah=$riwayahId'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (mounted) {
          setState(() {
            _dynamicReciters = data['reciters'] ?? [];
            _isLoadingReciters = false;
            
            // Set first dynamic reciter as default if none selected or if current is invalid
            final currentReciter = widget.storage.getString('default_reciter') ?? '';
            if (!currentReciter.startsWith('mp3quran_server_') && _dynamicReciters.isNotEmpty) {
              final moshaf = _dynamicReciters[0]['moshaf'] as List;
              if (moshaf.isNotEmpty) {
                final server = moshaf[0]['server'] as String;
                widget.storage.setString('default_reciter', 'mp3quran_server_$server');
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReciters = false);
    }
  }
"""
content = content.replace("@override\n  void initState() {", fetch_method + "\n  @override\n  void initState() {")

# 4. Call fetch method in initState
content = content.replace("_loadAyahs();", "_loadAyahs();\n    _fetchDynamicReciters(_quranScriptType);")

# 5. Fix UI dropdown
ui_dropdown = """
                              DropdownButton<String>(
                                value: _quranScriptType,
                                underline: SizedBox(),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFFE5C158),
                                ),
                                items: [
                                  DropdownMenuItem(value: 'hafs', child: Text(TranslationService.isArabic ? 'حفص عن عاصم' : 'Hafs A\\'n Assem')),
                                  DropdownMenuItem(value: 'warsh', child: Text(TranslationService.isArabic ? 'ورش عن نافع' : 'Warsh A\\'n Nafi\\'')),
                                  DropdownMenuItem(value: 'qaloon', child: Text(TranslationService.isArabic ? 'قالون عن نافع' : 'Qalun A\\'n Nafi\\'')),
                                  DropdownMenuItem(value: 'shuba', child: Text(TranslationService.isArabic ? 'شعبة عن عاصم' : 'Shuba A\\'n Assem')),
                                  DropdownMenuItem(value: 'duri', child: Text(TranslationService.isArabic ? 'الدوري عن أبي عمرو' : 'Al-Duri A\\'n Abi Amr')),
                                  DropdownMenuItem(value: 'susi', child: Text(TranslationService.isArabic ? 'السوسي عن أبي عمرو' : 'As-Susi A\\'n Abi Amr')),
                                  DropdownMenuItem(value: 'bazzi', child: Text(TranslationService.isArabic ? 'البزي عن ابن كثير' : 'Al-Bazzi A\\'n Ibn Katheer')),
                                  DropdownMenuItem(value: 'qunbul', child: Text(TranslationService.isArabic ? 'قنبل عن ابن كثير' : 'Qunbul A\\'n Ibn Katheer')),
                                  DropdownMenuItem(value: 'hisham', child: Text(TranslationService.isArabic ? 'هشام عن ابن عامر' : 'Hisham A\\'n Ibn Amir')),
                                  DropdownMenuItem(value: 'ibn-dhakwan', child: Text(TranslationService.isArabic ? 'ابن ذكوان عن ابن عامر' : 'Ibn Dhakwan A\\'n Ibn Amir')),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setModalState(() {
                                      _quranScriptType = newValue;
                                    });
                                    setState(() {
                                      _quranScriptType = newValue;
                                    });
                                    widget.storage.setString('quran_script_type', newValue);
                                    
                                    // Switch reciter
                                    if (newValue == 'hafs') {
                                      widget.storage.setString('default_reciter', 'ar.alafasy');
                                    }
                                    
                                    _fetchDynamicReciters(newValue);
                                    _loadAyahs();
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TranslationService.isArabic ? 'القارئ' : 'Reciter',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                                ),
                              ),
                              if (_isLoadingReciters)
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5C158)),
                                )
                              else if (_quranScriptType == 'hafs')
                                DropdownButton<String>(
                                  value: widget.storage.getString('default_reciter') ?? 'ar.alafasy',
                                  underline: SizedBox(),
                                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFFE5C158)),
                                  items: availableReciters.map((r) {
                                    return DropdownMenuItem(
                                      value: r.id,
                                      child: Text(TranslationService.isArabic ? r.nameAr : r.nameEn),
                                    );
                                  }).toList(),
                                  onChanged: (String? val) {
                                    if (val != null) {
                                      setModalState(() {});
                                      setState(() {});
                                      widget.storage.setString('default_reciter', val);
                                    }
                                  }
                                )
                              else
                                DropdownButton<String>(
                                  value: (() {
                                    final current = widget.storage.getString('default_reciter') ?? '';
                                    if (!current.startsWith('mp3quran_server_') || _dynamicReciters.isEmpty) return null;
                                    final serverCurrent = current.substring(16);
                                    final match = _dynamicReciters.where((r) {
                                      final moshaf = r['moshaf'] as List;
                                      if (moshaf.isEmpty) return false;
                                      return (moshaf[0]['server'] as String) == serverCurrent;
                                    }).toList();
                                    return match.isNotEmpty ? serverCurrent : null;
                                  })(),
                                  underline: SizedBox(),
                                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFFE5C158)),
                                  items: _dynamicReciters.map((r) {
                                    final moshaf = r['moshaf'] as List;
                                    if (moshaf.isEmpty) return null;
                                    final server = moshaf[0]['server'] as String;
                                    return DropdownMenuItem(
                                      value: server,
                                      child: Text(r['name'] as String),
                                    );
                                  }).whereType<DropdownMenuItem<String>>().toList(),
                                  onChanged: (String? val) {
                                    if (val != null) {
                                      setModalState(() {});
                                      setState(() {});
                                      widget.storage.setString('default_reciter', 'mp3quran_server_$val');
                                    }
                                  }
                                ),
"""

content = re.sub(r"DropdownButton<String>\(\s*value: _quranScriptType,[\s\S]*?\},[\s\S]*?\),", ui_dropdown, content)

# Modify play methods
content = content.replace("final supportsAyahSync = _quranScriptType == 'hafs';", "final supportsAyahSync = _quranScriptType == 'hafs';")
content = content.replace("if (ayahIndex != null) {", "if (ayahIndex != null && supportsAyahSync) {")

with open('lib/screens/surah_reader_screen.dart', 'w') as f:
    f.write(content)
