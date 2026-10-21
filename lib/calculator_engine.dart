class CalculatorEngine {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _startNewNumber = false;

  String get display => _display;

  String get expression =>
      _operator == null ? '' : '${_format(_firstOperand!)} $_operator';

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
      default:
        return op;
    }
  }

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
      _calculate();
      if (_display == 'Error') return;
    }
    _firstOperand = double.parse(_display);
    _operator = normalized;
    _startNewNumber = true;
  }

  void equals() {
    if (_operator == null || _display == 'Error') return;
    _calculate();
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
    _display = _format(double.parse(_display) / 100);
  }

  void _calculate() {
    final a = _firstOperand;
    final op = _operator;
    if (a == null || op == null) return;

    final b = double.parse(_display);
    if (op == '÷' && b == 0) {
      _setError();
      return;
    }

    final result = switch (op) {
      '+' => a + b,
      '−' => a - b,
      '×' => a * b,
      '÷' => a / b,
      _ => b,
    };
    _display = _format(result);
  }

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
    var text = value.toStringAsFixed(10);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}
