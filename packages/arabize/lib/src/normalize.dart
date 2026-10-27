final RegExp _diacritics = RegExp('[ً-ٰٟ]');
final RegExp _alefVariants = RegExp('[آأإٱ]');

/// Returns [text] in a form that is easier to compare when searching.
///
/// Removes tashkeel and tatweel, and maps alef variants to bare alef, alef
/// maqsura to ya, and ta marbuta to ha. Each mapping can be turned off.
String normalizeArabic(
  String text, {
  bool removeDiacritics = true,
  bool unifyAlef = true,
  bool unifyYa = true,
  bool unifyTaMarbuta = true,
}) {
  var result = text.replaceAll('ـ', '');
  if (removeDiacritics) result = result.replaceAll(_diacritics, '');
  if (unifyAlef) result = result.replaceAll(_alefVariants, 'ا');
  if (unifyYa) result = result.replaceAll('ى', 'ي');
  if (unifyTaMarbuta) result = result.replaceAll('ة', 'ه');
  return result;
}
