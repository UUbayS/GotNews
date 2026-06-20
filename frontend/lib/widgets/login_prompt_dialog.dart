import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

class LoginPromptDialog extends StatelessWidget {
  final String message;
  final String actionLabel;

  const LoginPromptDialog({
    super.key,
    this.message = 'Login untuk mengakses fitur ini.',
    this.actionLabel = 'Login',
  });

  static Future<bool> show(
    BuildContext context, {
    String message = 'Login untuk mengakses fitur ini.',
    String actionLabel = 'Login',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => LoginPromptDialog(
        message: message,
        actionLabel: actionLabel,
      ),
    );
    return result ?? false;
  }

  void _onLogin(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_outline, size: 48, color: Colors.blue),
      title: const Text('Login Diperlukan'),
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Nanti'),
        ),
        ElevatedButton(
          onPressed: () => _onLogin(context),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
