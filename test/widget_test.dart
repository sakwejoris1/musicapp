import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChuyassiApp());
    expect(find.byType(ChuyassiApp), findsOneWidget);
  });
}
