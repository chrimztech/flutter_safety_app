import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import '../data/json.dart';
import '../data/ohs_api.dart';

/// Inspection checklists work without a connection: the last loaded checklist is kept on the device, and results
/// saved offline are queued and sent when the connection returns (on the next save, when the checklist is opened
/// again, or by the background check every minute).
class OfflineQueue {
  static const _itemsPrefix = 'checklist_items_';
  static const _pendingPrefix = 'checklist_pending_';

  /// Any JSON the field screens need offline (the inspections list, an inspection).
  static Future<void> cacheJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_$key', jsonEncode(value));
  }

  static Future<Object?> cachedJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('offline_$key');
    return raw == null ? null : jsonDecode(raw);
  }

  /// Loads from the server and keeps a copy; without a connection returns the copy (or rethrows when there is none).
  static Future<T> withOfflineCopy<T>(String key, Future<Object?> Function() fetch, T Function(Object? json) parse) async {
    try {
      final fresh = await fetch();
      if (fresh != null) await cacheJson(key, fresh);
      return parse(fresh);
    } on ApiException catch (e) {
      if (!e.isOffline) rethrow;
      final copy = await cachedJson(key);
      if (copy == null) rethrow;
      return parse(copy);
    }
  }

  static Future<void> cacheChecklist(String inspectionId, List<Json> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_itemsPrefix$inspectionId', jsonEncode(items));
  }

  static Future<List<Json>?> cachedChecklist(String inspectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_itemsPrefix$inspectionId');
    return raw == null ? null : (jsonDecode(raw) as List).whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
  }

  static Future<void> queueResults(String inspectionId, Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_pendingPrefix$inspectionId', jsonEncode({...body, 'queuedAt': DateTime.now().toIso8601String()}));
  }

  static Future<Json?> pending(String inspectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_pendingPrefix$inspectionId');
    return raw == null ? null : (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  static Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.startsWith(_pendingPrefix)).length;
  }

  /// Sends queued results for one inspection. Returns the server's summary, or null if still offline / nothing queued.
  static Future<Json?> sync(OhsApi api, String inspectionId) async {
    final body = await pending(inspectionId);
    if (body == null) return null;
    try {
      final summary = obj(await api.client.patch('inspections/$inspectionId/checklist', {
        'results': body['results'],
        'createActions': body['createActions'] == true,
      }));
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_pendingPrefix$inspectionId');
      if (summary != null) await cacheChecklist(inspectionId, items(summary['items']));
      return summary;
    } on ApiException catch (e) {
      if (e.isOffline) return null;
      // The server refused the results (e.g. inspection deleted): drop them so they don't retry forever.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_pendingPrefix$inspectionId');
      rethrow;
    }
  }

  /// Background: send everything that is queued.
  static Future<void> syncAll(OhsApi api) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_pendingPrefix)).toList()) {
      try {
        await sync(api, key.substring(_pendingPrefix.length));
      } catch (_) {
        // reported when the user opens that checklist
      }
    }
  }
}
