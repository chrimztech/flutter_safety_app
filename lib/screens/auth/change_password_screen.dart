import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../ui/widgets.dart';

/// Change password. When [forced] (first sign-in with a one-time password) it is the only screen available until done.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = false});

  final bool forced;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;

  String? _rule(String? v) {
    final p = v ?? '';
    if (p.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) return 'Use letters and numbers';
    if (p == _current.text) return 'Choose a different password from the current one';
    final name = context.session.user?.email.split('@').first.toLowerCase();
    if (name != null && name.length >= 3 && p.toLowerCase().contains(name)) return 'Must not contain your email name';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.session.changePassword(_current.text, _next.text);
      if (!mounted) return;
      showMessage(context, 'Password changed. Other devices have been signed out.');
      if (!widget.forced) Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forced ? 'Choose your password' : 'Change password'),
        automaticallyImplyLeading: !widget.forced,
        actions: [
          if (widget.forced) TextButton(onPressed: () => context.session.signOut(), child: const Text('Sign out')),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (widget.forced)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text('Welcome, ${context.session.user?.name ?? ''}. You signed in with a one-time password. '
                    'Choose your own password to continue.'),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _current,
            obscureText: true,
            decoration: InputDecoration(labelText: widget.forced ? 'One-time password' : 'Current password'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(controller: _next, obscureText: true, decoration: const InputDecoration(labelText: 'New password'), validator: _rule),
          const SizedBox(height: 14),
          TextFormField(
            controller: _again,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Repeat new password'),
            validator: (v) => v != _next.text ? 'The passwords do not match' : null,
          ),
          const SizedBox(height: 8),
          Text('At least 8 characters, with letters and numbers, not containing your email name.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12.5)),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Saving...' : 'Save password')),
        ]),
      ),
    );
  }
}
