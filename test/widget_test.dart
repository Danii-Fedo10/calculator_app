import 'package:calculator_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('2 + 3 = 5 using the buttons', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

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
  });
}