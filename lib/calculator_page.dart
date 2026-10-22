import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calc_button.dart';
import 'calculator_engine.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with WidgetsBindingObserver {
  final _engine = CalculatorEngine();
  bool _secondFunctions = false;
  bool _isLoading = true;
  SharedPreferences? _preferences;
  Future<void> _pendingSave = Future<void>.value();

  static const _savedStateKey = 'calculator_state_v1';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveState();
    }
  }

  Future<void> _restoreState() async {
    Object? loadError;
    try {
      final preferences = await SharedPreferences.getInstance();
      _preferences = preferences;
      final savedState = preferences.getString(_savedStateKey);
      if (savedState != null) {
        final decoded = jsonDecode(savedState);
        if (decoded is! Map<String, dynamic> ||
            decoded['engine'] is! Map<String, dynamic> ||
            decoded['secondFunctions'] is! bool) {
          throw const FormatException('Saved calculator state is invalid.');
        }
        _engine.restoreState(decoded['engine'] as Map<String, dynamic>);
        _secondFunctions = decoded['secondFunctions'] as bool;
      }
    } catch (error) {
      loadError = error;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (loadError != null) {
      _showStorageError('load', loadError);
    }
  }

  void _saveState() {
    final preferences = _preferences;
    if (preferences == null) return;
    late final String snapshot;
    try {
      snapshot = jsonEncode({
        'engine': _engine.exportState(),
        'secondFunctions': _secondFunctions,
      });
    } catch (error) {
      _showStorageError('save', error);
      return;
    }
    _pendingSave = _pendingSave
        .then<void>((_) async {
          final saved = await preferences.setString(_savedStateKey, snapshot);
          if (!saved) {
            throw StateError('The saved calculator state was not written.');
          }
        })
        .catchError((Object error) {
          _showStorageError('save', error);
        });
  }

  void _showStorageError(String action, Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Could not $action calculator data: $error')),
      );
  }

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
    if (originalLabel.isEmpty || _isLoading) return;
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
    _saveState();
  }

  bool _isOperator(String label) => '÷×−+='.contains(label);

  bool _isAction(String label) =>
      {'AC', 'CE', 'C', '⌫', '±', '%', 'RAD', '2nd', 'MC', 'MR', 'M+', 'M−'}
          .contains(label);

  String _buttonLabel(String label) =>
      label == 'RAD' ? _engine.angleUnit : _visibleLabel(label);

  Future<void> _showHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                child: Row(
                  children: [
                    Text('History', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      key: const Key('clear_history'),
                      onPressed: _engine.history.isEmpty
                          ? null
                          : () {
                              setState(_engine.clearHistory);
                              _saveState();
                              Navigator.pop(sheetContext);
                            },
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _engine.history.isEmpty
                    ? const Center(child: Text('No calculations yet'))
                    : ListView.separated(
                        itemCount: _engine.history.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = _engine.history[index];
                          final localTime = entry.timestamp.toLocal();
                          final time =
                              '${localTime.hour.toString().padLeft(2, '0')}:'
                              '${localTime.minute.toString().padLeft(2, '0')}';
                          return ListTile(
                            key: ValueKey('history_$index'),
                            title: Text(entry.expression),
                            subtitle: Text(time),
                            trailing: Text(
                              entry.result,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            onTap: () {
                              setState(() => _engine.useHistoryEntry(entry));
                              _saveState();
                              Navigator.pop(sheetContext);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scientific calculator'),
        actions: [
          IconButton(
            key: const Key('history_button'),
            tooltip: 'History',
            onPressed: _isLoading ? null : _showHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
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
              child: IgnorePointer(
                ignoring: _isLoading,
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
            ),
          ],
        ),
      ),
    );
  }
}
