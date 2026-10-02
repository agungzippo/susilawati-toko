import 'package:flutter_test/flutter_test.dart';
import 'package:toko_susilawati_app/main.dart';

void main() {
  testWidgets('SUSILAWATI TOKO app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TokoSusilawatiApp());
    expect(find.byType(TokoSusilawatiApp), findsOneWidget);
  });
}
