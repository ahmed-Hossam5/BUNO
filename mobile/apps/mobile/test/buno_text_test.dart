import 'package:buno/theme/buno_tokens_ext.dart';
import 'package:buno/widgets/buno_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The isolated (LTR) runs BunoText makes from [text].
Future<List<String>> _isolated(WidgetTester tester, String text) async {
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.rtl,
    child: BunoText(text, style: BunoType.body),
  ));
  final lri = String.fromCharCode(0x2066);
  final runs = <String>[];
  tester.widget<RichText>(find.byType(RichText)).text.visitChildren((span) {
    final t = (span as TextSpan).text;
    if (t != null && t.startsWith(lri)) runs.add(t.substring(1, t.length - 1));
    return true;
  });
  return runs;
}

void main() {
  testWidgets('station and unit codes stay one LTR run', (tester) async {
    expect(await _isolated(tester, 'BUN-01 · متصلة'), ['BUN-01']);
    expect(await _isolated(tester, 'BUN-04 · آخر نبضة من 3 ث'), ['BUN-04', '3']);
    expect(await _isolated(tester, 'الوحدة PB-0417'), ['PB-0417']);
  });

  testWidgets('plain numbers are unchanged', (tester) async {
    expect(await _isolated(tester, 'خانة #3 · 92%'), ['#3', '92%']);
    expect(await _isolated(tester, 'بعد 12:30'), ['12:30']);
  });
}
