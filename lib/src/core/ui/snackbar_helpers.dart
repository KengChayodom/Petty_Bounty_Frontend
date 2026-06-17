import 'package:flutter/material.dart';

/// Shared SnackBar helpers so success/error toasts look consistent across
/// screens. Call sites keep their own `mounted` / `context.mounted` guard —
/// these only build and show the bar.
extension SnackBarX on BuildContext {
  void showSuccessSnackBar(String message) =>
      _showSnackBar(message, Colors.green);

  void showErrorSnackBar(String message) =>
      _showSnackBar(message, Colors.red);

  void _showSnackBar(String message, Color background) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }
}
