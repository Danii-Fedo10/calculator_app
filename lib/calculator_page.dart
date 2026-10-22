import 'package:flutter/material.dart';

import 'calc_button.dart';
import 'calculator_engine.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _engine = CalculatorEngine();
  bool _secondFunctions = false;

  static const _rows = [
    ['RAD', '2nd', 'MC', 'MR', 'AC'],
    ['x²', 'xʸ', '√x', 'ʸ√x', '1/x'],
    ['sin', 'cos', 'tan', 'ln', 'log'],
    ['x!', 'eˣ', '10ˣ', 'π', 'e'],
    ['M+', 'M−', '%', '⌫', 'CE'],
    ['7', '8', '9', '÷', ''],
    ['4', '5', '6', '×', ''],
    ['1', '2', '3', '−', '±'],
    ['0', '.', '=', '+', ''],
  ];

  String _visibleLabel(String label) {
    if (!_secondFunctions) return label;
    return switch (label) {
      'sin' => 'sin⁻¹',
      'cos' => 'cos⁻¹',
      'tan' => 'tan⁻¹',
      'x²' => '√x',
      '√x' => 'x²',
      'ln' => 'eˣ',
      'eˣ' => 'ln',
      'log' => '10ˣ',
      '10ˣ' => 'log',
      'xʸ' => 'ʸ√x',
      'ʸ√x' => 'xʸ',
      _ => label,
    };
  }

  void _onPressed(String originalLabel) {
    if (originalLabel.isEmpty) return;
    final label = _visibleLabel(originalLabel);

    setState(() {
      switch (label) {
        case 'RAD':
          _engine.toggleAngleUnit();
        case '2nd':
          _secondFunctions = !_secondFunctions;
        case 'AC':
          _engine.clear();
        case 'CE':
          _engine.clearEntry();
        case 'C':
          _engine.clear();
        case '⌫':
          _engine.backspace();
        case '%':
          _engine.percent();
        case '±':
          _engine.toggleSign();
        case '.':
          _engine.inputDecimal();
        case '=':
          _engine.equals();
        case 'MC':
          _engine.memoryClear();
        case 'MR':
          _engine.memoryRecall();
        case 'M+':
          _engine.memoryAdd();
        case 'M−':
          _engine.memorySubtract();
        case 'π' || 'e':
          _engine.useConstant(label);
        case '÷' || '×' || '−' || '+' || 'xʸ' || 'ʸ√x':
          _engine.inputOperator(label);
        case 'x²' ||
              '√x' ||
              '1/x' ||
              'x!' ||
              'sin' ||
              'cos' ||
              'tan' ||
              'sin⁻¹' ||
              'cos⁻¹' ||
              'tan⁻¹' ||
              'ln' ||
              'log' ||
              'eˣ' ||
              '10ˣ':
          _engine.applyFunction(label);
        default:
          _engine.inputDigit(label);
      }
    });
  }

  bool _isOperator(String label) => '÷×−+='.contains(label);

  bool _isAction(String label) =>
      {'AC', 'CE', 'C', '⌫', '±', '%', 'RAD', '2nd', 'MC', 'MR', 'M+', 'M−'}
          .contains(label);

  String _buttonLabel(String label) =>
      label == 'RAD' ? _engine.angleUnit : _visibleLabel(label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _engine.expression,
                      key: const Key('expression'),
                      style: TextStyle(fontSize: 18, color: scheme.outline),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _engine.display,
                          key: const Key('display'),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 68,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                child: Column(
                  children: [
                    for (final row in _rows)
                      Expanded(
                        child: Row(
                          children: [
                            for (final label in row)
                              Expanded(
                                child: label.isEmpty
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: CalcButton(
                                          key: ValueKey('key_$label'),
                                          label: _buttonLabel(label),
                                          onPressed: () => _onPressed(label),
                                          backgroundColor:
                                              _isOperator(label)
                                              ? scheme.primary
                                              : _isAction(label)
                                              ? scheme.secondaryContainer
                                              : scheme.surfaceContainerHighest,
                                          foregroundColor:
                                              _isOperator(label)
                                              ? scheme.onPrimary
                                              : _isAction(label)
                                              ? scheme.onSecondaryContainer
                                              : scheme.onSurface,
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
