import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/translation_service.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _cashController = TextEditingController();
  final _goldGramsController = TextEditingController();
  final _goldPriceController = TextEditingController();
  final _silverGramsController = TextEditingController();
  final _silverPriceController = TextEditingController();
  final _merchandiseController = TextEditingController();
  final _debtsController = TextEditingController();

  int _selectedGoldKarat = 24; // 24, 21, 18

  @override
  void dispose() {
    _cashController.dispose();
    _goldGramsController.dispose();
    _goldPriceController.dispose();
    _silverGramsController.dispose();
    _silverPriceController.dispose();
    _merchandiseController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) {
    final text = controller.text.replaceAll(',', '').trim();
    return double.tryParse(text) ?? 0.0;
  }

  double get _goldValue {
    final grams = _parse(_goldGramsController);
    final price = _parse(_goldPriceController);
    final purityMultiplier = _selectedGoldKarat / 24.0;
    return grams * price * purityMultiplier;
  }

  double get _silverValue {
    final grams = _parse(_silverGramsController);
    final price = _parse(_silverPriceController);
    return grams * price;
  }

  double get _netWealth {
    final cash = _parse(_cashController);
    final merchandise = _parse(_merchandiseController);
    final debts = _parse(_debtsController);
    final total = cash + _goldValue + _silverValue + merchandise - debts;
    return total > 0 ? total : 0.0;
  }

  double get _nisabThreshold {
    final goldPrice = _parse(_goldPriceController);
    // Standard gold Nisab is 85 grams of 24k gold
    if (goldPrice > 0) {
      return 85.0 * goldPrice;
    }
    // Fallback if silver price is provided: 595 grams of silver
    final silverPrice = _parse(_silverPriceController);
    if (silverPrice > 0) {
      return 595.0 * silverPrice;
    }
    return 0.0;
  }

  bool get _isNisabReached {
    if (_nisabThreshold <= 0) return _netWealth > 0;
    return _netWealth >= _nisabThreshold;
  }

  double get _zakatAmount {
    if (!_isNisabReached) return 0.0;
    return _netWealth * 0.025; // 2.5%
  }

  void _shareSummary(bool isArabic) {
    final String summary = isArabic
        ? '''
حساب الزكاة الشرعية (تطبيق آية):
----------------------------------
صافي الأموال الخاضعة للزكاة: ${_netWealth.toStringAsFixed(2)}
قيمة النصاب الشرعي: ${_nisabThreshold > 0 ? _nisabThreshold.toStringAsFixed(2) : 'غير محدد'}
حالة النصاب: ${_isNisabReached ? 'بلغ النصاب الشرعي' : 'دون النصاب'}
مقدار الزكاة الواجبة (2.5%): ${_zakatAmount.toStringAsFixed(2)}
----------------------------------
﴿وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ﴾
تم الحساب عبر تطبيق آية
'''
        : '''
Zakah Calculation Summary (Aya App):
----------------------------------
Net Zakah-Eligible Wealth: ${_netWealth.toStringAsFixed(2)}
Nisab Threshold: ${_nisabThreshold > 0 ? _nisabThreshold.toStringAsFixed(2) : 'Not specified'}
Status: ${_isNisabReached ? 'Nisab Reached' : 'Below Nisab'}
Zakah Due (2.5%): ${_zakatAmount.toStringAsFixed(2)}
----------------------------------
"And establish prayer and give Zakah" (Quran 2:43)
Calculated via Aya App
''';
    Share.share(summary);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = TranslationService.isArabic;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isArabic ? 'حاسبة الزكاة الذكية' : 'Smart Zakah Calculator',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: isArabic ? 'مشاركة الحساب' : 'Share calculation',
            onPressed: () => _shareSummary(isArabic),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Result Card
            _buildResultCard(theme, isArabic),
            const SizedBox(height: 20),

            // Cash Section
            _buildSectionCard(
              theme: theme,
              title: isArabic ? '1. السيولة والأموال النقدية' : '1. Cash & Bank Balances',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildNumberField(
                  controller: _cashController,
                  label: isArabic
                      ? 'السيولة النقدية والودائع البنكية'
                      : 'Cash on hand, bank accounts & savings',
                  theme: theme,
                  isArabic: isArabic,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gold Section
            _buildSectionCard(
              theme: theme,
              title: isArabic ? '2. الذهب المدخر' : '2. Gold (Savings & Investment)',
              icon: Icons.diamond_outlined,
              children: [
                Row(
                  children: [
                    Text(
                      isArabic ? 'العيار:' : 'Karat:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 24, label: Text('24k')),
                        ButtonSegment(value: 21, label: Text('21k')),
                        ButtonSegment(value: 18, label: Text('18k')),
                      ],
                      selected: {_selectedGoldKarat},
                      onSelectionChanged: (val) {
                        setState(() {
                          _selectedGoldKarat = val.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _goldGramsController,
                        label: isArabic ? 'الوزن (غرام)' : 'Weight (Grams)',
                        theme: theme,
                        isArabic: isArabic,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _goldPriceController,
                        label: isArabic ? 'سعر غرام الذهب' : 'Gold Price / g',
                        theme: theme,
                        isArabic: isArabic,
                      ),
                    ),
                  ],
                ),
                if (_goldValue > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'القيمة التقديرية للذهب: ${_goldValue.toStringAsFixed(2)}'
                        : 'Gold Value: ${_goldValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Silver Section
            _buildSectionCard(
              theme: theme,
              title: isArabic ? '3. الفضة' : '3. Silver',
              icon: Icons.auto_awesome,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _silverGramsController,
                        label: isArabic ? 'الوزن (غرام)' : 'Weight (Grams)',
                        theme: theme,
                        isArabic: isArabic,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _silverPriceController,
                        label: isArabic ? 'سعر غرام الفضة' : 'Silver Price / g',
                        theme: theme,
                        isArabic: isArabic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trade & Debts Section
            _buildSectionCard(
              theme: theme,
              title: isArabic ? '4. عروض التجارة والخصومات' : '4. Merchandise & Deductions',
              icon: Icons.storefront_outlined,
              children: [
                _buildNumberField(
                  controller: _merchandiseController,
                  label: isArabic
                      ? 'قيمة بضائع التجارة المعروضة للبيع'
                      : 'Business inventory & merchandise value',
                  theme: theme,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  controller: _debtsController,
                  label: isArabic
                      ? 'الديون الحالة المستحقة عليك (تُخصم)'
                      : 'Immediate debts/liabilities due (deducted)',
                  theme: theme,
                  isArabic: isArabic,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Clarification Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFE5C158),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'تنبيه شرعي: تجب الزكاة بنسبة 2.5% إذا بلغ صافي المال قيمة نصاب الذهب (85 غراماً عيار 24) أو الفضة (595 غراماً)، ومضت عليه سنة قمرية كاملة (الحول).'
                          : 'Sharia Note: Zakah of 2.5% becomes obligatory if your net wealth equals or exceeds the Nisab of 85g 24k gold (or 595g silver) and has been held for a full lunar year.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isNisabReached && _zakatAmount > 0
              ? [const Color(0xFF0F766E), const Color(0xFF134E4A)]
              : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'مقدار الزكاة الواجبة (2.5%):' : 'Obligatory Zakah (2.5%):',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isNisabReached && _netWealth > 0
                      ? const Color(0xFFE5C158)
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isNisabReached && _netWealth > 0
                      ? (isArabic ? 'بلغ النصاب' : 'Nisab Reached')
                      : (isArabic ? 'دون النصاب' : 'Below Nisab'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isNisabReached && _netWealth > 0
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _zakatAmount.toStringAsFixed(2),
            style: const TextStyle(
              color: Color(0xFFE5C158),
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'صافي المال الخاضع للزكاة:' : 'Net Zakah Wealth:',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                _netWealth.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_nisabThreshold > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'قيمة النصاب (85غ ذهب):' : 'Nisab (85g Gold):',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  _nisabThreshold.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFE5C158), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    required bool isArabic,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
