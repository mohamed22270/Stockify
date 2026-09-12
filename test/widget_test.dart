import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockflow_flutter/main.dart';

void main() {
  testWidgets('loads the offline inventory dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: StockFlowApp()));
    await tester.pumpAndSettle();

    expect(find.text('StockFlow'), findsOneWidget);
    expect(find.text('Good morning, Mubashir'), findsOneWidget);
    expect(find.text('Stock units'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
  });
}
