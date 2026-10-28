const String _western = '0123456789';
const String _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
const String _easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';

String _convert(String text, String from, String to) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index == -1 ? char : to[index]);
  }
  return buffer.toString();
}

/// Replaces Western digits in [text] with Arabic-Indic digits.
///
/// With [easternVariant] set, the Persian and Urdu forms are used instead.
String toArabicDigits(String text, {bool easternVariant = false}) => _convert(
  text,
  _western,
  easternVariant ? _easternArabicIndic : _arabicIndic,
);

/// Replaces Arabic-Indic and Persian digits in [text] with Western digits.
String toWesternDigits(String text) => _convert(
  _convert(text, _arabicIndic, _western),
  _easternArabicIndic,
  _western,
);
