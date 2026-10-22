import 'package:calculator_app/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CalculatorEngine calc;

  setUp(() {
    calc = CalculatorEngine();
  });

  test('adds two numbers', () {
    calc
      ..inputDigit('2')
      ..inputOperator('+')
      ..inputDigit('3')
      ..equals();
    expect(calc.display, '5');
  });

  test('avoids floating point noise', () {
    calc
      ..inputDigit('0')
      ..inputDecimal()
      ..inputDigit('1')
      ..inputOperator('+')
      ..inputDigit('0')
      ..inputDecimal()
      ..inputDigit('2')
      ..equals();
    expect(calc.display, '0.3');
  });

  test('chains operations', () {
    calc
      ..inputDigit('2')
      ..inputOperator('+')
      ..inputDigit('3')
      ..inputOperator('+');
    expect(calc.display, '5');
    calc
      ..inputDigit('4')
      ..equals();
    expect(calc.display, '9');
    expect(calc.history.map((entry) => entry.expression), ['5 + 4', '2 + 3']);
  });

  test('division by zero shows Error and recovers', () {
    calc
      ..inputDigit('5')
      ..inputOperator('÷')
      ..inputDigit('0')
      ..equals();
    expect(calc.display, 'Error');
    calc.inputDigit('7');
    expect(calc.display, '7');
  });

  test('ignores leading zeros', () {
    calc
      ..inputDigit('0')
      ..inputDigit('0')
      ..inputDigit('5');
    expect(calc.display, '5');
  });

  test('accepts standard ASCII operators', () {
    calc
      ..inputDigit('9')
      ..inputOperator('-')
      ..inputDigit('4')
      ..equals();
    expect(calc.display, '5');

    calc
      ..inputDigit('8')
      ..inputOperator('/')
      ..inputDigit('2')
      ..equals();
    expect(calc.display, '4');
  });

  test('uses radians by default and supports degree mode', () {
    expect(calc.angleUnit, 'RAD');
    calc
      ..useConstant('π')
      ..applyFunction('sin');
    expect(calc.display, '0');

    calc
      ..toggleAngleUnit()
      ..inputDigit('9')
      ..inputDigit('0')
      ..applyFunction('sin');
    expect(calc.angleUnit, 'DEG');
    expect(calc.display, '1');
  });

  test('supports inverse trigonometric functions in the selected unit', () {
    calc
      ..toggleAngleUnit()
      ..inputDigit('1')
      ..applyFunction('sin⁻¹');
    expect(calc.display, '90');
  });

  test('supports powers, roots, and reciprocal', () {
    calc
      ..inputDigit('2')
      ..inputOperator('xʸ')
      ..inputDigit('3')
      ..equals();
    expect(calc.display, '8');

    calc
      ..inputDigit('2')
      ..inputDigit('7')
      ..inputOperator('ʸ√x')
      ..inputDigit('3')
      ..equals();
    expect(calc.display, '3');

    calc
      ..inputDigit('4')
      ..applyFunction('1/x');
    expect(calc.display, '0.25');
  });

  test('supports logarithms, factorial, and memory', () {
    calc
      ..inputDigit('1')
      ..inputDigit('0')
      ..inputDigit('0')
      ..applyFunction('log');
    expect(calc.display, '2');

    calc
      ..inputDigit('5')
      ..applyFunction('x!');
    expect(calc.display, '120');

    calc
      ..inputDigit('4')
      ..memoryAdd()
      ..clear()
      ..memoryRecall();
    expect(calc.display, '4');
  });

  test('clears the current entry without losing a pending operation', () {
    calc
      ..inputDigit('2')
      ..inputOperator('+')
      ..inputDigit('8')
      ..clearEntry();
    expect(calc.display, '0');
    expect(calc.expression, '2 +');

    calc
      ..inputDigit('3')
      ..equals();
    expect(calc.display, '5');
  });

  test('exports and restores pending operations and calculation history', () {
    calc
      ..toggleAngleUnit()
      ..inputDigit('2')
      ..inputOperator('+')
      ..inputDigit('3')
      ..equals()
      ..memoryAdd()
      ..inputDigit('4')
      ..inputOperator('×');

    final restored = CalculatorEngine()..restoreState(calc.exportState());

    expect(restored.display, '4');
    expect(restored.angleUnit, 'DEG');
    expect(restored.expression, '4 ×');
    expect(restored.history, hasLength(1));
    expect(restored.history.single.expression, '2 + 3');
    restored
      ..clear()
      ..memoryRecall();
    expect(restored.display, '5');
  });

  test('invalid scientific operations show Error and recover', () {
    calc
      ..inputDigit('9')
      ..toggleSign()
      ..applyFunction('√x');
    expect(calc.display, 'Error');

    calc.inputDigit('2');
    expect(calc.display, '2');
  });

  test('backspace, sign toggle and clear', () {
    calc
      ..inputDigit('1')
      ..inputDigit('2')
      ..inputDigit('3')
      ..backspace();
    expect(calc.display, '12');
    calc.toggleSign();
    expect(calc.display, '-12');
    calc.clear();
    expect(calc.display, '0');
  });
}
