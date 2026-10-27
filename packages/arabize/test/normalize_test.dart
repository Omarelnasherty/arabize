import 'package:arabize/arabize.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeArabic', () {
    test('removes tashkeel', () {
      expect(normalizeArabic('مُحَمَّد'), 'محمد');
    });

    test('removes tatweel', () {
      expect(normalizeArabic('مـحـمـد'), 'محمد');
    });

    test('maps alef variants to bare alef', () {
      expect(
        normalizeArabic('أحمد إبراهيم آمنة ٱلله'),
        'احمد ابراهيم امنه الله',
      );
    });

    test('maps alef maqsura to ya', () {
      expect(normalizeArabic('مصطفى'), 'مصطفي');
    });

    test('maps ta marbuta to ha', () {
      expect(normalizeArabic('مدرسة'), 'مدرسه');
    });

    test('makes spelling variants equal', () {
      expect(normalizeArabic('إِسْلَامِيَّة'), normalizeArabic('اسلاميه'));
    });

    test('leaves other text alone', () {
      expect(normalizeArabic('abc 123 !'), 'abc 123 !');
      expect(normalizeArabic(''), '');
    });

    test('each mapping can be turned off', () {
      expect(normalizeArabic('أُمَّة', removeDiacritics: false), 'اُمَّه');
      expect(normalizeArabic('أمة', unifyAlef: false), 'أمه');
      expect(normalizeArabic('على', unifyYa: false), 'على');
      expect(normalizeArabic('أمة', unifyTaMarbuta: false), 'امة');
    });
  });
}
