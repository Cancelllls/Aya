import 'package:flutter/material.dart';
import '../../services/translation_service.dart';

enum SahwCause { addition, omission, doubt }
enum DoubtCertainty { hasPrevailingBelief, completelyUncertain }

class SujoodSahwWizardScreen extends StatefulWidget {
  const SujoodSahwWizardScreen({super.key});

  @override
  State<SujoodSahwWizardScreen> createState() => _SujoodSahwWizardScreenState();
}

class _SujoodSahwWizardScreenState extends State<SujoodSahwWizardScreen> {
  SahwCause? _cause;
  DoubtCertainty? _doubtType;

  void _reset() {
    setState(() {
      _cause = null;
      _doubtType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = TranslationService.isArabic;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isArabic ? 'مساعد سجود السهو الذكي' : 'Sujood as-Sahw Wizard',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_cause != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: isArabic ? 'إعادة البدء' : 'Restart',
              onPressed: _reset,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Color(0xFFE5C158),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'حدد الموقف الذي وقع لك في الصلاة لنعطيك الحكم الشرعي الدقيق وموعد السجود'
                          : 'Select what happened during your prayer to get the exact ruling and timing of prostration.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Step 1: Select Main Cause
            Text(
              isArabic ? '1. ما الذي حدث في صلاتك؟' : '1. What happened in your prayer?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            _buildOptionCard(
              theme: theme,
              title: isArabic ? 'نقصان (نسيان واجب)' : 'Omission (Forgot an Obligation)',
              subtitle: isArabic
                  ? 'مثل نسيان التشهد الأول، أو تسبيح الركوع أو السجود'
                  : 'E.g. missed the first Tashahhud, or tasbeeh of bowing/prostrating',
              icon: Icons.remove_circle_outline,
              isSelected: _cause == SahwCause.omission,
              onTap: () {
                setState(() {
                  _cause = SahwCause.omission;
                  _doubtType = null;
                });
              },
            ),
            const SizedBox(height: 10),

            _buildOptionCard(
              theme: theme,
              title: isArabic ? 'زيادة في الصلاة' : 'Addition in Prayer',
              subtitle: isArabic
                  ? 'مثل ركوع زائد، سجود ثالث، ركعة خامسة، أو تسليم قبل التمام ناسياً'
                  : 'E.g. extra bowing, 3rd prostration, 5th rak\'ah, or premature salam',
              icon: Icons.add_circle_outline,
              isSelected: _cause == SahwCause.addition,
              onTap: () {
                setState(() {
                  _cause = SahwCause.addition;
                  _doubtType = null;
                });
              },
            ),
            const SizedBox(height: 10),

            _buildOptionCard(
              theme: theme,
              title: isArabic ? 'شك في عدد الركعات' : 'Doubt in Rak\'ah Count',
              subtitle: isArabic
                  ? 'ترددت هل صليت ثلاثاً أم أربعاً، أو ركعتين أم ثلاثاً'
                  : 'Unsure whether you prayed 3 or 4, or 2 or 3 rak\'ahs',
              icon: Icons.flaky_outlined,
              isSelected: _cause == SahwCause.doubt,
              onTap: () {
                setState(() {
                  _cause = SahwCause.doubt;
                });
              },
            ),

            // Step 2: Doubt branching
            if (_cause == SahwCause.doubt) ...[
              const SizedBox(height: 24),
              Text(
                isArabic
                    ? '2. هل ترجح لديك أحد الأمرين أم الشك متساوٍ؟'
                    : '2. Do you have a prevailing conviction or equal uncertainty?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              _buildOptionCard(
                theme: theme,
                title: isArabic
                    ? 'شك متساوٍ (لم يترجح شيء)'
                    : 'Completely Uncertain (No strong inclination)',
                subtitle: isArabic
                    ? 'نسبة الاحتمالين متساوية 50/50 ولا تدري كم صليت'
                    : 'Equal uncertainty, unable to incline toward either number',
                icon: Icons.balance,
                isSelected: _doubtType == DoubtCertainty.completelyUncertain,
                onTap: () {
                  setState(() {
                    _doubtType = DoubtCertainty.completelyUncertain;
                  });
                },
              ),
              const SizedBox(height: 10),

              _buildOptionCard(
                theme: theme,
                title: isArabic
                    ? 'غلب على ظني أحد الأمرين (ترجيح)'
                    : 'Prevailing Belief (Inclined to one number)',
                subtitle: isArabic
                    ? 'يغلب على ظنك أنك صليت ثلاثاً أو أربعاً بقرينة أو شعور غالب'
                    : 'You strongly incline toward 3 or 4 based on indication',
                icon: Icons.trending_up,
                isSelected: _doubtType == DoubtCertainty.hasPrevailingBelief,
                onTap: () {
                  setState(() {
                    _doubtType = DoubtCertainty.hasPrevailingBelief;
                  });
                },
              ),
            ],

            // Step 3: Ruling Output
            if (_shouldShowRuling) ...[
              const SizedBox(height: 28),
              _buildRulingCard(theme, isArabic),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  bool get _shouldShowRuling {
    if (_cause == SahwCause.omission || _cause == SahwCause.addition) {
      return true;
    }
    if (_cause == SahwCause.doubt && _doubtType != null) {
      return true;
    }
    return false;
  }

  Widget _buildOptionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : theme.dividerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulingCard(ThemeData theme, bool isArabic) {
    final bool isBeforeSalam = _isProstrationBeforeSalam;
    final String timingBadge = isBeforeSalam
        ? (isArabic ? 'السجود قبل السلام' : 'PROSTRATE BEFORE SALAM')
        : (isArabic ? 'السجود بعد السلام' : 'PROSTRATE AFTER SALAM');

    final String explanation = _getExplanation(isArabic);
    final String dalil = _getDalil(isArabic);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5C158),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5C158).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timing Header Badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isBeforeSalam
                    ? [const Color(0xFFD97706), const Color(0xFFB45309)]
                    : [const Color(0xFF0F766E), const Color(0xFF115E59)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isBeforeSalam
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  timingBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Steps
          Text(
            isArabic ? 'ما يجب عليك فعله:' : 'What you must do:',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

          // How to prostrate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories,
                  color: Color(0xFFE5C158),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'تسجد سجدتين كالمعتاد قائلاً «سبحان ربي الأعلى» ثلاثاً في كل سجدة، وتكبّر عند الهوي والرفع.'
                        : 'Perform two standard prostrations saying "Subhana Rabbiya al-A\'la" 3 times in each, with Takbeer.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Dalil
          Text(
            isArabic ? 'الدليل من السنة:' : 'Evidence from Sunnah:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dalil,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFFE5C158),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isProstrationBeforeSalam {
    if (_cause == SahwCause.omission) return true;
    if (_cause == SahwCause.addition) return false;
    if (_cause == SahwCause.doubt) {
      if (_doubtType == DoubtCertainty.completelyUncertain) {
        return true; // Build on certainty, prostrate before salam
      } else {
        return false; // Prevailing belief, complete, salam, then prostrate after salam
      }
    }
    return true;
  }

  String _getExplanation(bool isArabic) {
    if (_cause == SahwCause.omission) {
      return isArabic
          ? 'عند نسيان واجب من واجبات الصلاة، فإنك تكمل صلاتك حتى تنتهي من التشهد الأخير والصلاة الإبراهيمية، ثم تسجد سجدتين للسهو قبل أن تسلم، ثم تسلم بعدهما.'
          : 'When an obligation is accidentally omitted, complete your prayer including final Tashahhud, perform 2 prostrations of forgetfulness BEFORE the Tasleem, then make salam.';
    } else if (_cause == SahwCause.addition) {
      return isArabic
          ? 'عند زيادة ركوع أو سجود أو ركعة سهواً، تكمل صلاتك وتسلم كالمعتاد، ثم تسجد سجدتي السهو بعد السلام، ثم تسلم مرة ثانية بعدهما.'
          : 'When an extra action is added accidentally, complete prayer and make salam as normal. Then prostrate twice AFTER the salam, and conclude with another salam.';
    } else {
      if (_doubtType == DoubtCertainty.completelyUncertain) {
        return isArabic
            ? 'إذا شككت في عدد الركعات ولم يترجح لديك شيء، فاطرح الشك وابنِ على اليقين (وهو الأقل، مثلاً اعتبرها 3 وليس 4)، وأتِ بما بقي عليك، ثم اسجد سجدتي السهو قبل السلام، ثم سلّم.'
            : 'If uncertain with equal doubt, discard doubt and build upon certainty (the lower number). Complete remaining rak\'ahs, prostrate twice BEFORE salam, then make salam.';
      } else {
        return isArabic
            ? 'إذا غلب على ظنك أحد الأمرين، فابنِ على ما غلب على ظنك وأتم صلاتك عليه، ثم سلّم، ثم اسجد سجدتي السهو بعد السلام وسلّم ثانية ترغيماً للشيطان.'
            : 'If you have a strong prevailing belief, build upon it and complete your prayer, make salam, then prostrate twice AFTER salam and make salam again.';
      }
    }
  }

  String _getDalil(bool isArabic) {
    if (_cause == SahwCause.omission) {
      return isArabic
          ? '«أن النبي ﷺ قام في صلاة الظهر وعليه جلوس، فلما أتم صلاته سجد سجدتين فكبر في كل سجدة وهو جالس قبل أن يسلم» (البخاري ومسلم).'
          : '"The Prophet ﷺ stood up in Dhuhr prayer when he should have sat (first Tashahhud); when he finished his prayer, he made two prostrations before saying salam" (Bukhari & Muslim).';
    } else if (_cause == SahwCause.addition) {
      return isArabic
          ? '«صلى النبي ﷺ الظهر خمساً فقيل له: أزيد في الصلاة؟ قال: وما ذاك؟ قالوا: صليت خمساً، فسجد سجدتين بعدما سلم» (البخاري ومسلم).'
          : '"The Prophet ﷺ prayed 5 rak\'ahs for Dhuhr; when informed, he performed two prostrations after having made salam" (Bukhari & Muslim).';
    } else {
      if (_doubtType == DoubtCertainty.completelyUncertain) {
        return isArabic
            ? '«إذا شك أحدكم في صلاته فلم يدر كم صلى أثلاثاً أم أربعاً؟ فليطرح الشك وليبن على ما استيقن ثم يسجد سجدتين قبل أن يسلم» (رواه مسلم).'
            : '"If one doubts whether he prayed 3 or 4, let him discard doubt, build on certainty, and prostrate twice before salam" (Sahih Muslim).';
      } else {
        return isArabic
            ? '«إذا شك أحدكم في صلاته فليتحرّ الصواب فليتم عليه ثم ليسلم ثم يسجد سجدتين» (البخاري ومسلم عن ابن مسعود).'
            : '"Let him determine what is most likely correct, complete upon it, make salam, then prostrate twice" (Bukhari & Muslim).';
      }
    }
  }
}
