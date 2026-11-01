# arabize

Small text utilities for Arabic apps.

```dart
import 'package:arabize/arabize.dart';

normalizeArabic('إِسْلَامِيَّة'); // اسلاميه
toArabicDigits('2026');          // ٢٠٢٦
toWesternDigits('٢٠٢٦');         // 2026
```

`normalizeArabic` removes tashkeel and tatweel and unifies alef, ya and ta marbuta, so search matches what users mean. Use it on both the query and the searched text. Each mapping can be turned off with a named argument.

`toArabicDigits` takes `easternVariant: true` for the Persian and Urdu digit forms. `toWesternDigits` converts both forms back.

Part of [arabize](https://github.com/Omarelnasherty/arabize), which also has lint rules, a CLI and test helpers for Arabic and RTL Flutter apps.
