import 'package:flutter/material.dart';

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
