import 'package:flutter/widgets.dart';

/// The app language: Arabic (default, right-to-left) or English
/// (left-to-right). Kept in memory like the other settings.
///
/// Every user-facing string is written as `tr('عربي', 'English')`, so both
/// languages sit side by side at the call site. [BunoApp] listens to
/// [current] and rebuilds the whole tree when it changes.
class BunoLocale {
  BunoLocale._();

  static const arabic = Locale('ar');
  static const english = Locale('en');
  static const supported = [arabic, english];

  static final current = ValueNotifier<Locale>(arabic);

  static bool get isEnglish => current.value.languageCode == 'en';

  /// The language's own name, as shown in the language picker.
  static String nameOf(Locale locale) =>
      locale.languageCode == 'en' ? 'English' : 'العربية';

  static void reset() => current.value = arabic;
}

/// Picks the string for the current [BunoLocale].
String tr(String ar, String en) => BunoLocale.isEnglish ? en : ar;

/// A string in both languages for `const` data (enums, mock lists), read
/// with [text] when it is shown.
class Tr {
  const Tr(this.ar, this.en);

  final String ar;
  final String en;

  String get text => tr(ar, en);

  @override
  String toString() => text;
}
