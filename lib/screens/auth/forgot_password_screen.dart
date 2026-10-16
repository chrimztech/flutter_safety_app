import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../ui/widgets.dart';

/// Emails a single-use reset link (valid 30 minutes). The reset itself is completed in the browser from that link.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.email = ''});

  final String email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  String? _sent;
  bool _busy = false;

  Future<void> _send() async {
    if (!_email.text.contains('@')) {
      showMessage(context, 'Enter the email address of your account', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final message = await context.api.forgotPassword(_email.text);
      setState(() => _sent = message);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        if (_sent == null) ...[
          const Text('Enter your account email. We will send a link to choose a new password. The link works once and expires after 30 minutes.'),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _send, child: Text(_busy ? 'Sending...' : 'Send reset link')),
        ] else ...[
          const Icon(Icons.mark_email_read_outlined, size: 56),
          const SizedBox(height: 12),
          Text(_sent!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text('Open the link on this phone or a computer, choose a new password, then sign in here.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back to sign in')),
        ],
      ]),
    );
  }
}
