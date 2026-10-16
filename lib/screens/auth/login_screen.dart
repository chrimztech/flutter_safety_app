import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/api_client.dart';
import '../../ui/theme.dart';
import '../public/public_report_screen.dart';
import '../public/track_report_screen.dart';
import 'forgot_password_screen.dart';
import 'server_settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _notice;
  bool _noticeIsError = false;

  @override
  void initState() {
    super.initState();
    // Why the previous session ended (idle, signed out elsewhere, password changed...).
    _notice = context.session.takeSignOutReason();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await context.session.signIn(_email.text, _password.text);
    } on ApiException catch (e) {
      setState(() {
        _notice = e.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Server address',
                      icon: const Icon(Icons.dns_outlined),
                      onPressed: () => context.push(const ServerSettingsScreen()),
                    ),
                  ),
                  const Icon(Icons.health_and_safety, size: 64, color: OhsColors.brand),
                  const SizedBox(height: 12),
                  Text('OHS Mobile', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Occupational Health and Safety', textAlign: TextAlign.center, style: TextStyle(color: scheme.outline)),
                  const SizedBox(height: 28),
                  if (_notice != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_noticeIsError ? scheme.errorContainer : scheme.secondaryContainer),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(_noticeIsError ? Icons.error_outline : Icons.info_outline,
                            color: _noticeIsError ? scheme.onErrorContainer : scheme.onSecondaryContainer),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_notice!)),
                      ]),
                    ),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter your email address' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _hide,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _hide = !_hide)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(ForgotPasswordScreen(email: _email.text)),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Text('Sign in'),
                  ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('No account? Workers and the public can report a safety concern anonymously.',
                      textAlign: TextAlign.center, style: TextStyle(color: scheme.outline)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.push(const PublicReportScreen()),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Report a safety concern'),
                  ),
                  TextButton(onPressed: () => context.push(const TrackReportScreen()), child: const Text('Track a report')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
