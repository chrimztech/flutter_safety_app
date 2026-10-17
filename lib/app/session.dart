import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../data/ohs_api.dart';
import 'config.dart';
import 'local_alerts.dart';
import 'offline_queue.dart';

enum SessionStatus { starting, signedOut, signedIn }

/// The signed-in account and the API it talks through.
///
/// The token lives in secure storage. On start the stored session is checked with the server; whenever the server
/// refuses it (signed out elsewhere, idle too long, password changed, account deactivated) the app returns to the
/// sign-in screen and shows the server's reason.
class SessionController extends ChangeNotifier {
  SessionController() {
    api = OhsApi(ApiClient(baseUrl: ServerConfig.defaultUrl, readToken: () async => _token, onUnauthorized: _sessionEnded));
  }

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'ohs_token';
  static const _userKey = 'ohs_user';

  late final OhsApi api;
  String? _token;
  AppUser? _user;
  SessionStatus _status = SessionStatus.starting;
  String? _signOutReason;
  int _unread = 0;
  bool _announce = false;
  Timer? _poll;
  String _serverUrl = ServerConfig.defaultUrl;

  String? _actingTenantId;
  String? _actingTenantName;

  SessionStatus get status => _status;

  /// The signed-in account. In support mode a platform super-admin works as the agency's administrator.
  AppUser? get user => _user != null && _actingTenantId != null ? _user!.copyWith(role: 'admin', tenantName: _actingTenantName) : _user;

  /// The real account, regardless of support mode.
  AppUser? get account => _user;

  bool get supportMode => _actingTenantId != null;
  String? get supportAgencyName => _actingTenantName;

  /// Platform super-admin only: work inside an agency (every request carries its id; the server checks the role
  /// and records everything in that agency's audit log).
  void enterAgency(String id, String name) {
    _actingTenantId = id;
    _actingTenantName = name;
    api.client.actingTenant = id;
    notifyListeners();
  }

  void exitAgency() {
    _actingTenantId = null;
    _actingTenantName = null;
    api.client.actingTenant = null;
    notifyListeners();
  }
  String get serverUrl => _serverUrl;
  int get unreadNotifications => _unread;

  /// Why the user was signed out, shown once on the sign-in screen.
  String? takeSignOutReason() {
    final r = _signOutReason;
    _signOutReason = null;
    return r;
  }

  Future<void> start() async {
    _serverUrl = await ServerConfig.load();
    api.client.baseUrl = _serverUrl;
    _token = await _read(_tokenKey);
    final cached = await _read(_userKey);
    if (_token == null) {
      _set(SessionStatus.signedOut);
      return;
    }
    if (cached != null) _user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    try {
      final check = await api.validate();
      if (check.user == null) {
        await _clear(check.reason ?? 'Your session has ended. Please sign in again.');
        return;
      }
      _user = check.user;
      await _write(_userKey, jsonEncode(_user!.toJson()));
      _set(SessionStatus.signedIn);
      _startPolling();
    } on ApiException catch (e) {
      if (e.isOffline && _user != null) {
        // Offline at start-up: keep the cached account; requests will report the connection problem.
        _set(SessionStatus.signedIn);
      } else {
        await _clear(e.isUnauthorized ? e.message : null);
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    final result = await api.login(email, password);
    await _adopt(result);
  }

  /// Also used for the forced first-sign-in change: the server returns a fresh token for this device.
  Future<void> changePassword(String current, String next) async {
    final result = await api.changePassword(current, next);
    await _adopt(result);
  }

  Future<void> signOut() async {
    try {
      await api.logout();
    } catch (_) {
      // Signing out locally must always work, even offline.
    }
    await _clear(null);
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url.trim();
    api.client.baseUrl = _serverUrl;
    await ServerConfig.save(_serverUrl);
    notifyListeners();
  }

  Future<void> refreshUnread() async {
    if (_status != SessionStatus.signedIn) return;
    try {
      final n = await api.unreadNotifications();
      if (n > _unread && _announce) {
        // Something new arrived since the last check: show it as a phone notification.
        final newest = (await api.notifications()).where((x) => !x.read).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        if (newest.isNotEmpty) {
          await LocalAlerts.show(newest.first.title, n - _unread > 1 ? '${newest.first.message} (+${n - _unread - 1} more)' : newest.first.message);
        }
      }
      _announce = true; // the first check after sign-in only sets the baseline
      if (n != _unread) {
        _unread = n;
        notifyListeners();
      }
    } catch (_) {
      // Polling failures are silent; a real session end arrives through _sessionEnded.
    }
  }

  Future<void> _adopt(AuthResult result) async {
    _token = result.token;
    _user = result.user;
    await _write(_tokenKey, result.token);
    await _write(_userKey, jsonEncode(result.user.toJson()));
    _set(SessionStatus.signedIn);
    _startPolling();
  }

  void _sessionEnded(String message) {
    if (_status == SessionStatus.signedIn) unawaited(_clear(message));
  }

  Future<void> _clear(String? reason) async {
    _poll?.cancel();
    _actingTenantId = null;
    _actingTenantName = null;
    api.client.actingTenant = null;
    _token = null;
    _user = null;
    _unread = 0;
    _signOutReason = reason;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {
      // Storage unavailable: nothing persisted to remove.
    }
    _set(SessionStatus.signedOut);
  }

  void _startPolling() {
    _poll?.cancel();
    _announce = false;
    unawaited(LocalAlerts.init());
    unawaited(refreshUnread());
    _poll = Timer.periodic(const Duration(seconds: 60), (_) {
      refreshUnread();
      // Checklist results saved offline are sent once the connection is back.
      OfflineQueue.syncAll(api);
    });
  }

  void _set(SessionStatus s) {
    _status = s;
    notifyListeners();
  }

  static Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Storage unavailable (e.g. some desktop setups): the session still works until the app closes.
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
