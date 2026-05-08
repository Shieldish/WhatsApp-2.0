import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for enabling/disabling two-step verification with a 6-digit PIN.
///
/// Requirements: 12.4, 12.5
class TwoStepVerificationScreen extends ConsumerStatefulWidget {
  const TwoStepVerificationScreen({super.key});

  @override
  ConsumerState<TwoStepVerificationScreen> createState() =>
      _TwoStepVerificationScreenState();
}

class _TwoStepVerificationScreenState
    extends ConsumerState<TwoStepVerificationScreen> {
  bool _isEnabled = false;
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two-step verification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info card ─────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isEnabled ? Icons.verified_user : Icons.info_outline,
                    color: _isEnabled ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEnabled
                          ? 'Two-step verification is enabled. '
                              'You\'ll be asked to enter your PIN when '
                              're-registering your phone number.'
                          : 'Protect your account with a 6-digit PIN. '
                              'You\'ll need this to verify your phone number.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (!_isEnabled) ...[
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter PIN',
                helperText: '6-digit PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _enableTwoStep,
              child: const Text('Enable'),
            ),
          ],

          if (_isEnabled) ...[
            OutlinedButton(
              onPressed: _disableTwoStep,
              child: const Text('Disable'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _changePin,
              child: const Text('Change PIN'),
            ),
          ],
        ],
      ),
    );
  }

  void _enableTwoStep() {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length != 6 || confirm.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 6 digits')),
      );
      return;
    }

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }

    setState(() => _isEnabled = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Two-step verification enabled')),
    );
  }

  void _disableTwoStep() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable two-step verification?'),
        content: const Text(
          'You will no longer be asked for a PIN when re-registering.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isEnabled = false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-step verification disabled'),
                ),
              );
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _changePin() {
    // In production, show a change PIN dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change PIN not yet implemented')),
    );
  }
}