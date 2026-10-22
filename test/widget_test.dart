import 'package:calculator_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('2 + 3 = 5 using the buttons', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();

    Future<void> press(String label) async {
      await tester.tap(find.byKey(ValueKey('key_$label')));
      await tester.pump();
    }

    await press('2');
    await press('+');
    await press('3');
    await press('=');

    final display = tester.widget<Text>(find.byKey(const Key('display')));
    expect(display.data, '5');
    expect(find.byKey(const Key('history_button')), findsOneWidget);
  });

  testWidgets('restores calculator state and history after reopening', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();

    Future<void> press(String label) async {
      await tester.tap(find.byKey(ValueKey('key_$label')));
      await tester.pump();
    }

    await press('2');
    await press('+');
    await press('3');
    await press('=');
    await press('RAD');
    await press('2nd');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '5');
    expect(find.text('DEG'), findsOneWidget);
    expect(find.text('sin⁻¹'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history_button')));
    await tester.pumpAndSettle();
    expect(find.text('2 + 3'), findsOneWidget);
    expect(find.text('5'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('history_0')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '5');
  });
}
