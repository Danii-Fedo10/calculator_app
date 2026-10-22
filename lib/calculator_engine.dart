import 'dart:math' as math;

class CalculationHistoryEntry {
  const CalculationHistoryEntry({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  final String expression;
  final String result;
  final DateTime timestamp;

  Map<String, Object> toJson() => {
    'expression': expression,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CalculationHistoryEntry.fromJson(Map<String, dynamic> json) {
    final expression = json['expression'];
    final result = json['result'];
    final timestamp = json['timestamp'];
    final parsedResult = result is String
        ? double.tryParse(result.replaceFirst('×10^', 'e'))
        : null;
    if (expression is! String ||
        result is! String ||
        timestamp is! String ||
        expression.isEmpty ||
        result.isEmpty ||
        parsedResult == null ||
        !parsedResult.isFinite) {
      throw const FormatException('Invalid calculation history entry.');
    }
    return CalculationHistoryEntry(
      expression: expression,
      result: result,
      timestamp: DateTime.parse(timestamp),
    );
  }
}

class CalculatorEngine {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _startNewNumber = false;
  bool _degrees = false;
  double _memory = 0;
  final List<CalculationHistoryEntry> _history = [];

  String get display => _display;
  String get angleUnit => _degrees ? 'DEG' : 'RAD';
  List<CalculationHistoryEntry> get history =>
      List.unmodifiable(_history);

  String get expression =>
      _operator == null ? '' : '${_format(_firstOperand!)} $_operator';

  void inputDigit(String digit) {
    if (_startNewNumber || _display == '0' || _display == 'Error') {
      _display = digit;
      _startNewNumber = false;
    } else {
      final digitCount = _display.replaceAll(RegExp(r'[-.]'), '').length;
      if (digitCount >= 15) return;
      _display += digit;
    }
  }

  void inputDecimal() {
    if (_startNewNumber || _display == 'Error') {
      _display = '0.';
      _startNewNumber = false;
    } else if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void inputOperator(String op) {
    if (_display == 'Error') return;
    final normalized = _normalizeOperator(op);
    if (_operator != null && !_startNewNumber) {
      final expression = '${_format(_firstOperand!)} $_operator $_display';
      _calculate();
      if (_display == 'Error') return;
      _addHistory(expression);
    }
    _firstOperand = _parseDisplay();
    _operator = normalized;
    _startNewNumber = true;
  }

  void equals() {
    if (_operator == null || _display == 'Error') return;
    final expression = '${_format(_firstOperand!)} $_operator $_display';
    _calculate();
    if (_display != 'Error') {
      _addHistory(expression);
    }
    _firstOperand = null;
    _operator = null;
    _startNewNumber = true;
  }

  void clear() {
    _display = '0';
    _firstOperand = null;
    _operator = null;
    _startNewNumber = false;
  }

  void clearEntry() {
    _display = '0';
    _startNewNumber = false;
  }

  void clearHistory() {
    _history.clear();
  }

  void useHistoryEntry(CalculationHistoryEntry entry) {
    final value = double.tryParse(entry.result.replaceFirst('×10^', 'e'));
    if (value == null || !value.isFinite) {
      throw const FormatException('History result is not a valid number.');
    }
    _display = entry.result;
    _firstOperand = null;
    _operator = null;
    _startNewNumber = true;
  }

  void backspace() {
    if (_startNewNumber || _display == 'Error') return;
    final isSingleDigit =
        _display.length == 1 ||
        (_display.length == 2 && _display.startsWith('-'));
    _display = isSingleDigit ? '0' : _display.substring(0, _display.length - 1);
  }

  void toggleSign() {
    if (_display == 'Error' || _display == '0') return;
    _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
  }

  void percent() {
    if (_display == 'Error') return;
    final expression = '$_display%';
    _setResult(_parseDisplay() / 100, historyExpression: expression);
  }

  void toggleAngleUnit() {
    _degrees = !_degrees;
  }

  void useConstant(String constant) {
    if (_display == 'Error') return;
    final value = switch (constant) {
      'π' => math.pi,
      'e' => math.e,
      _ => null,
    };
    if (value == null) return;
    _display = _format(value);
    _startNewNumber = true;
  }

  void applyFunction(String function) {
    if (_display == 'Error') return;
    final value = _parseDisplay();
    final result = switch (function) {
      'x²' => value * value,
      '√x' => value < 0 ? double.nan : math.sqrt(value),
      '1/x' => value == 0 ? double.infinity : 1 / value,
      'x!' => _factorial(value),
      'sin' => _cleanTrigResult(math.sin(_toRadians(value))),
      'cos' => _cleanTrigResult(math.cos(_toRadians(value))),
      'tan' => _cleanTrigResult(math.tan(_toRadians(value))),
      'sin⁻¹' => _fromRadians(math.asin(value)),
      'cos⁻¹' => _fromRadians(math.acos(value)),
      'tan⁻¹' => _fromRadians(math.atan(value)),
      'ln' => value <= 0 ? double.nan : math.log(value),
      'log' => value <= 0 ? double.nan : math.log(value) / math.ln10,
      'eˣ' => math.exp(value),
      '10ˣ' => math.pow(10, value).toDouble(),
      _ => value,
    };
    _setResult(result, historyExpression: '$function($_display)');
  }

  void memoryClear() {
    _memory = 0;
  }

  void memoryRecall() {
    if (_display == 'Error') return;
    _setResult(_memory);
  }

  void memoryAdd() {
    if (_display == 'Error') return;
    final result = _memory + _parseDisplay();
    if (!result.isFinite) {
      _setError();
      return;
    }
    _memory = result;
  }

  void memorySubtract() {
    if (_display == 'Error') return;
    final result = _memory - _parseDisplay();
    if (!result.isFinite) {
      _setError();
      return;
    }
    _memory = result;
  }

  Map<String, Object?> exportState() => {
    'version': 1,
    'display': _display,
    'firstOperand': _firstOperand,
    'operator': _operator,
    'startNewNumber': _startNewNumber,
    'degrees': _degrees,
    'memory': _memory,
    'history': _history.map((entry) => entry.toJson()).toList(),
  };

  void restoreState(Map<String, dynamic> state) {
    if (state['version'] != 1) {
      throw const FormatException('Unsupported saved calculator version.');
    }

    final display = state['display'];
    final firstOperand = state['firstOperand'];
    final operator = state['operator'];
    final startNewNumber = state['startNewNumber'];
    final degrees = state['degrees'];
    final memory = state['memory'];
    final history = state['history'];
    const validOperators = {'+', '−', '×', '÷', 'xʸ', 'ʸ√x'};
    final parsedDisplay = display is String
        ? double.tryParse(display.replaceFirst('×10^', 'e'))
        : null;

    if (display is! String ||
        (display != 'Error' &&
            (parsedDisplay == null || !parsedDisplay.isFinite)) ||
        (firstOperand != null && firstOperand is! num) ||
        (firstOperand is num && !firstOperand.toDouble().isFinite) ||
        (operator != null &&
            (operator is! String || !validOperators.contains(operator))) ||
        ((firstOperand == null) != (operator == null)) ||
        startNewNumber is! bool ||
        degrees is! bool ||
        memory is! num ||
        !memory.toDouble().isFinite ||
        history is! List) {
      throw const FormatException('Saved calculator state is invalid.');
    }

    final restoredHistory = <CalculationHistoryEntry>[];
    for (final item in history) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Saved calculation history is invalid.');
      }
      restoredHistory.add(CalculationHistoryEntry.fromJson(item));
    }

    _display = display;
    _firstOperand = (firstOperand as num?)?.toDouble();
    _operator = operator as String?;
    _startNewNumber = startNewNumber;
    _degrees = degrees;
    _memory = memory.toDouble();
    _history
      ..clear()
      ..addAll(restoredHistory);
  }

  String _normalizeOperator(String op) {
    switch (op) {
      case '-':
      case '−':
        return '−';
      case '*':
      case '×':
        return '×';
      case '/':
      case '÷':
        return '÷';
      case '^':
      case 'xʸ':
        return 'xʸ';
      case 'ʸ√x':
        return op;
      default:
        return op;
    }
  }

  double _toRadians(double value) => _degrees ? value * math.pi / 180 : value;

  double _fromRadians(double value) => _degrees ? value * 180 / math.pi : value;

  double _cleanTrigResult(double value) {
    if (value.abs() < 1e-9) return 0;
    if ((value.abs() - 1).abs() < 1e-9) return value.sign;
    return value;
  }

  double _factorial(double value) {
    if (value < 0 || value != value.truncateToDouble() || value > 170) {
      return double.nan;
    }
    var result = 1.0;
    for (var factor = 2; factor <= value; factor++) {
      result *= factor;
    }
    return result;
  }

  void _calculate() {
    final a = _firstOperand;
    final op = _operator;
    if (a == null || op == null) return;

    final b = _parseDisplay();
    final result = switch (op) {
      '+' => a + b,
      '−' => a - b,
      '×' => a * b,
      '÷' => b == 0 ? double.infinity : a / b,
      'xʸ' => math.pow(a, b).toDouble(),
      'ʸ√x' => _nthRoot(a, b),
      _ => b,
    };
    _setResult(result);
  }

  double _nthRoot(double value, double degree) {
    if (degree == 0) return double.nan;
    if (value < 0) {
      if (degree != degree.truncateToDouble() || degree.abs() % 2 == 0) {
        return double.nan;
      }
      return -math.pow(-value, 1 / degree).toDouble();
    }
    return math.pow(value, 1 / degree).toDouble();
  }

  void _setResult(double value, {String? historyExpression}) {
    if (value.isNaN || value.isInfinite) {
      _setError();
      return;
    }
    _display = _format(value);
    _startNewNumber = true;
    if (historyExpression != null) {
      _addHistory(historyExpression);
    }
  }

  void _addHistory(String expression) {
    _history.insert(
      0,
      CalculationHistoryEntry(
        expression: expression,
        result: _display,
        timestamp: DateTime.now(),
      ),
    );
  }

  double _parseDisplay() => double.parse(_display.replaceFirst('×10^', 'e'));

  void _setError() {
    _display = 'Error';
    _firstOperand = null;
    _operator = null;
    _startNewNumber = true;
  }

  String _format(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == value.truncateToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    if (value.abs() >= 1e15 || (value != 0 && value.abs() < 1e-9)) {
      final parts = value.toStringAsExponential(9).split('e');
      var mantissa = parts.first.replaceFirst(RegExp(r'\.?0+$'), '');
      return '$mantissa×10^${int.parse(parts.last)}';
    }
    var text = value.toStringAsFixed(10);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}
