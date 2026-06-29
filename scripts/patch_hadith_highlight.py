with open('lib/screens/hadith_screen.dart', 'r') as f:
    text = f.read()

# Add _highlightedHadithNumber
if 'int? _highlightedHadithNumber;' not in text:
    text = text.replace('bool _isLoading = true;', 'bool _isLoading = true;\n  int? _highlightedHadithNumber;')

# Update _jumpToHadithByNumber
old_jump = '''  void _jumpToHadithByNumber(int num) {
    final idx = _hadithList.indexWhere((element) => element['number'] == num);
    if (idx != -1) {
      setState(() {
        _currentPage = (idx / _pageSize).floor() + 1;
        _jumpController.clear();
      });'''

new_jump = '''  void _jumpToHadithByNumber(int num) {
    final idx = _hadithList.indexWhere((element) => element['number'] == num);
    if (idx != -1) {
      setState(() {
        _currentPage = (idx / _pageSize).floor() + 1;
        _jumpController.clear();
        _highlightedHadithNumber = num;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedHadithNumber = null;
          });
        }
      });'''
text = text.replace(old_jump, new_jump)

# Update _buildHadithCard to use highlight
old_card = '''  Widget _buildHadithCard(Map<String, dynamic> h, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.primaryColor.withOpacity(0.1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.cardColor,
              theme.cardColor.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),'''

new_card = '''  Widget _buildHadithCard(Map<String, dynamic> h, ThemeData theme) {
    final bool isHighlighted = _highlightedHadithNumber == h['number'];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isHighlighted ? 8 : 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isHighlighted ? const Color(0xFFE5C158) : theme.primaryColor.withOpacity(0.1), width: isHighlighted ? 2.0 : 1.0),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              isHighlighted ? const Color(0xFFE5C158).withOpacity(0.2) : theme.cardColor,
              isHighlighted ? const Color(0xFFE5C158).withOpacity(0.1) : theme.cardColor.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),'''
text = text.replace(old_card, new_card)

with open('lib/screens/hadith_screen.dart', 'w') as f:
    f.write(text)
