import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/session.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/platform/platform_screens.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => SessionController()..start(), child: const OhsApp()));
}

final _navigator = GlobalKey<NavigatorState>();

class OhsApp extends StatelessWidget {
  const OhsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OHS Mobile',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigator,
      theme: buildTheme(),
      themeMode: ThemeMode.dark,
      home: const _Gate(),
    );
  }
}

/// Chooses the first screen from the session: sign-in, the forced password change, or the app.
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  SessionStatus? _last;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final status = session.status;
    if (_last != status) {
      // When the session ends (sign-out, or the server ended it), close any open screens on top of this one.
      if (_last == SessionStatus.signedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _navigator.currentState?.popUntil((r) => r.isFirst));
      }
      _last = status;
    }
    switch (status) {
      case SessionStatus.starting:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionStatus.signedOut:
        return const LoginScreen(key: ValueKey('login'));
      case SessionStatus.signedIn:
        final user = session.user!;
        if (user.mustChangePassword) return const ChangePasswordScreen(forced: true);
        if (session.account!.isSuperAdmin && !session.supportMode) return const PlatformShell();
        return HomeShell(key: ValueKey('${user.id}-${session.supportAgencyName ?? ''}'));
    }
  }
}
