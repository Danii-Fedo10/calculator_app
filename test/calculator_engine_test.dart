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
