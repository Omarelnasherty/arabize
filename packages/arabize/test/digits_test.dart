import 'package:arabize/arabize.dart';
import 'package:test/test.dart';

void main() {
  group('toArabicDigits', () {
    test('converts every digit', () {
      expect(toArabicDigits('0123456789'), '٠١٢٣٤٥٦٧٨٩');
    });

    test('leaves other characters alone', () {
      expect(toArabicDigits('رقم 12: abc'), 'رقم ١٢: abc');
    });

    test('uses the Persian forms when asked', () {
      expect(toArabicDigits('456', easternVariant: true), '۴۵۶');
    });
  });

  group('toWesternDigits', () {
    test('converts Arabic-Indic digits', () {
      expect(toWesternDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('converts Persian digits', () {
      expect(toWesternDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('leaves other characters alone', () {
      expect(toWesternDigits('السعر ٥٠ جنيه'), 'السعر 50 جنيه');
    });
  });
}
