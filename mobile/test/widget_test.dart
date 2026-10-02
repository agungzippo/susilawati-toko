import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toko_susilawati_app/main.dart';
import 'package:toko_susilawati_app/screens/splash_screen.dart';
import 'package:toko_susilawati_app/widgets/bag_3d_graphic.dart';
import 'package:toko_susilawati_app/widgets/box_3d_icon.dart';

void main() {
  testWidgets('SUSILAWATI TOKO app splash screen renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(const TokoSusilawatiApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('susilawati'), findsOneWidget);
    expect(find.text('t o k o  .'), findsOneWidget);

    // Settle timer
    await tester.pumpAndSettle(const Duration(milliseconds: 2000));
  });

  testWidgets('Bag3DGraphic renders different bag types', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Bag3DGraphic(bagType: 'Tas Tote Minimalis', width: 100, height: 100),
          ),
        ),
      ),
    );
    expect(find.byType(Bag3DGraphic), findsOneWidget);
  });

  testWidgets('Box3DIcon renders 3D box graphic', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Box3DIcon(size: 40),
          ),
        ),
      ),
    );
    expect(find.byType(Box3DIcon), findsOneWidget);
  });
}
