import 'package:flutter_test/flutter_test.dart';
import 'package:nawaitu/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NawaituApp());
    expect(find.text("Assalamu'alaikum"), findsOneWidget);
  });
}
