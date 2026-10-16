import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/ohs_api.dart';
import 'session.dart';

extension SessionContext on BuildContext {
  OhsApi get api => read<SessionController>().api;

  SessionController get session => read<SessionController>();

  /// The signed-in user (screens behind the sign-in gate only).
  AppUser get me => read<SessionController>().user!;

  Future<T?> push<T>(Widget screen) => Navigator.of(this).push<T>(_route(screen));
}

PageRoute<T> _route<T>(Widget screen) => MaterialPageRoute<T>(builder: (_) => screen);
