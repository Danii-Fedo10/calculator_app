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

  static const _rows = [
    ['C', '⌫', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['±', '0', '.', '='],
  ];

  void _onPressed(String label) {
    setState(() {
      switch (label) {
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
        case '÷' || '×' || '−' || '+':
          _engine.inputOperator(label);
        default:
          _engine.inputDigit(label);
      }
    });
  }

  bool _isOperator(String label) => '÷×−+='.contains(label);
  bool _isAction(String label) => ['C', '⌫', '%', '±'].contains(label);

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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _engine.expression,
                      key: const Key('expression'),
                      style: TextStyle(fontSize: 20, color: scheme.outline),
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
                            fontSize: 72,
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
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (final row in _rows)
                      Expanded(
                        child: Row(
                          children: [
                            for (final label in row)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CalcButton(
                                    key: ValueKey('key_$label'),
                                    label: label,
                                    onPressed: () => _onPressed(label),
                                    backgroundColor: _isOperator(label)
                                        ? scheme.primary
                                        : _isAction(label)
                                        ? scheme.secondaryContainer
                                        : scheme.surfaceContainerHighest,
                                    foregroundColor: _isOperator(label)
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
