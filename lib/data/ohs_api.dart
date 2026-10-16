import 'dart:typed_data';

import 'api_client.dart';
import 'json.dart';
import 'models.dart';

/// Every backend call the mobile app makes, in one place. Pure Dart.
///
/// The backend scopes everything by the signed-in account: officers and administrators see their own agency,
/// company users only their own company (the server enforces this; the app never filters for security).
class OhsApi {
  OhsApi(this.client);

  final ApiClient client;

  // ---------------------------------------------------------------- generic records (data-driven modules)

  Future<List<Json>> list(String path, {Map<String, dynamic>? query}) async => items(await client.get(path, query: query));

  Future<Json> one(String path) async => record(await client.get(path));

  Future<Json> create(String path, Map<String, dynamic> body) async => record(await client.post(path, body));

  Future<Json> update(String path, Map<String, dynamic> body) async => record(await client.patch(path, body));

  Future<void> remove(String path) => client.delete(path);

  Future<dynamic> action(String path, [Map<String, dynamic>? body]) => client.post(path, body);

  // ---------------------------------------------------------------- authentication

  Future<AuthResult> login(String email, String password) async =>
      AuthResult.fromJson(obj(await client.post('auth/login', {'email': email.trim(), 'password': password}, false))!);

  /// Checks the stored token. Returns the user, or null with the server's reason when the session has ended.
  Future<({AppUser? user, String? reason})> validate() async {
    final j = obj(await client.get('auth/validate')) ?? const {};
    if (flag(j['valid']) && obj(j['user']) != null) return (user: AppUser.fromJson(obj(j['user'])!), reason: null);
    return (user: null, reason: str(j['reason']));
  }

  Future<void> logout() => client.post('auth/logout');

  /// Changing the password ends every other session; the server returns a fresh token for this one.
  Future<AuthResult> changePassword(String current, String next) async =>
      AuthResult.fromJson(obj(await client.post('auth/change-password', {'currentPassword': current, 'newPassword': next}))!);

  Future<String> forgotPassword(String email) async =>
      text(obj(await client.post('auth/forgot-password', {'email': email.trim()}, false))?['message'],
          'If an account exists for that email, a reset link is on its way.');

  Future<({List<UserSession> sessions, Json policy})> sessions() async {
    final j = obj(await client.get('auth/sessions')) ?? const {};
    return (sessions: items(j['sessions']).map(UserSession.fromJson).toList(), policy: obj(j['policy']) ?? const <String, dynamic>{});
  }

  Future<void> endSession(String id) => client.delete('auth/sessions/$id');

  Future<void> endOtherSessions() => client.post('auth/sessions/end-others');

  Future<Profile> profile() async => Profile.fromJson(obj(await client.get('profile'))!);

  Future<void> updateProfile(Map<String, dynamic> changes) => client.patch('profile', changes);

  // ---------------------------------------------------------------- dashboard

  Future<Json> dashboard() async => obj(await client.get('analytics/dashboard')) ?? const {};

  Future<Json> iotStats() async => obj(await client.get('iot/stats')) ?? const {};

  Future<int> unreadNotifications({bool background = true}) async =>
      integer(obj(await client.get('notifications/stats', background: background))?['unread']) ?? 0;

  // ---------------------------------------------------------------- incidents

  Future<List<Incident>> incidents() async => items(await client.get('incidents')).map(Incident.fromJson).toList();

  Future<Incident> incident(String id) async => Incident.fromJson(obj(await client.get('incidents/$id'))!);

  /// Statutory incident notification. Company users' reports are tied to their own company by the server.
  Future<Incident> reportIncident({
    required String type,
    required String severity,
    required String title,
    required String description,
    required String location,
    required DateTime incidentDate,
    required int personsAffected,
    String? employerId,
    int? lostWorkDays,
  }) async =>
      Incident.fromJson(obj(await client.post('incidents', {
        'type': type,
        'severity': severity,
        'title': title,
        'description': description,
        'location': location,
        'incidentDate': _dateTime(incidentDate),
        'numberOfPersonsAffected': personsAffected,
        'employerId': employerId ?? '',
        if (lostWorkDays != null) 'lostWorkDays': lostWorkDays,
      }))!);

  Future<Incident> updateIncident(String id, Map<String, dynamic> changes) async =>
      Incident.fromJson(obj(await client.patch('incidents/$id', changes))!);

  // ---------------------------------------------------------------- inspections

  Future<List<Inspection>> inspections() async => items(await client.get('inspections')).map(Inspection.fromJson).toList();

  Future<Inspection> inspection(String id) async => Inspection.fromJson(obj(await client.get('inspections/$id'))!);

  Future<Inspection> scheduleInspection({required String employerId, required String type, required DateTime date, String? notes}) async =>
      Inspection.fromJson(obj(await client.post('inspections', {
        'employerId': employerId,
        'type': type,
        'scheduledDate': _dateTime(date),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }))!);

  Future<Inspection> updateInspection(String id, Map<String, dynamic> changes) async =>
      Inspection.fromJson(obj(await client.patch('inspections/$id', changes))!);

  // ---------------------------------------------------------------- complaints

  Future<List<Complaint>> complaints() async => items(await client.get('complaints')).map(Complaint.fromJson).toList();

  Future<Complaint> complaint(String id) async => Complaint.fromJson(obj(await client.get('complaints/$id'))!);

  Future<Complaint> updateComplaint(String id, Map<String, dynamic> changes) async =>
      Complaint.fromJson(obj(await client.patch('complaints/$id', changes))!);

  // ---------------------------------------------------------------- companies

  Future<List<Company>> companies() async => items(await client.get('employers')).map(Company.fromJson).toList();

  Future<Company> company(String id) async => Company.fromJson(obj(await client.get('employers/$id'))!);

  /// The signed-in company user's own company.
  Future<Company> myCompany() async => Company.fromJson(obj(await client.get('employers/me'))!);

  Future<Company> updateMyCompany(Map<String, dynamic> changes) async =>
      Company.fromJson(obj(await client.patch('employers/me', changes))!);

  // ---------------------------------------------------------------- enforcement

  Future<List<EnforcementNotice>> enforcement() async =>
      items(await client.get('enforcement')).map(EnforcementNotice.fromJson).toList();

  Future<EnforcementNotice> enforcementNotice(String id) async =>
      EnforcementNotice.fromJson(obj(await client.get('enforcement/$id'))!);

  Future<EnforcementNotice> updateEnforcement(String id, Map<String, dynamic> changes) async =>
      EnforcementNotice.fromJson(obj(await client.patch('enforcement/$id', changes))!);

  // ---------------------------------------------------------------- corrective actions

  Future<List<CorrectiveAction>> correctiveActions() async =>
      items(await client.get('corrective-actions')).map(CorrectiveAction.fromJson).toList();

  Future<CorrectiveAction> correctiveAction(String id) async =>
      CorrectiveAction.fromJson(obj(await client.get('corrective-actions/$id'))!);

  Future<CorrectiveAction> updateCorrectiveAction(String id, Map<String, dynamic> changes) async =>
      CorrectiveAction.fromJson(obj(await client.patch('corrective-actions/$id', changes))!);

  // ---------------------------------------------------------------- attachments (evidence)

  Future<List<Json>> attachments(String entityType, String entityId) async =>
      items(await client.get('attachments', query: {'entityType': entityType, 'entityId': entityId}));

  Future<Uint8List> downloadAttachment(String id) => client.getBytes('attachments/$id/download');

  Future<void> uploadAttachment({
    required String entityType,
    required String entityId,
    required Uint8List bytes,
    required String filename,
    String? description,
  }) =>
      client.upload('attachments', bytes: bytes, filename: filename, fields: {
        'entityType': entityType,
        'entityId': entityId,
        if (description != null && description.isNotEmpty) 'description': description,
      });

  // ---------------------------------------------------------------- notifications

  Future<List<AppNotification>> notifications() async =>
      items(await client.get('notifications')).map(AppNotification.fromJson).toList();

  Future<void> markNotificationRead(String id) => client.patch('notifications/$id/read');

  Future<void> markAllNotificationsRead() => client.patch('notifications/read-all');

  Future<void> deleteNotification(String id) => client.delete('notifications/$id');

  // ---------------------------------------------------------------- IoT hazard monitoring

  Future<List<HazardEvent>> hazardEvents() async => items(await client.get('iot/events')).map(HazardEvent.fromJson).toList();

  Future<HazardEvent> hazardEvent(String id) async => HazardEvent.fromJson(obj(await client.get('iot/events/$id'))!);

  Future<List<Recommendation>> eventRecommendations(String id) async =>
      items(await client.get('iot/events/$id/recommendations')).map(Recommendation.fromJson).toList();

  /// Company users may only acknowledge (and add notes); OHS staff resolve or mark false alarms.
  Future<HazardEvent> updateHazardEvent(String id, {String? status, String? notes}) async =>
      HazardEvent.fromJson(obj(await client.patch('iot/events/$id', {
        if (status != null) 'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }))!);

  Future<List<IotDevice>> devices() async => items(await client.get('iot/devices')).map(IotDevice.fromJson).toList();

  Future<List<Recommendation>> recommendations() async =>
      items(await client.get('iot/recommendations')).map(Recommendation.fromJson).toList();

  // ---------------------------------------------------------------- reports

  Future<List<ReportSummary>> reports() async => items(await client.get('reports')).map(ReportSummary.fromJson).toList();

  Future<ReportSummary> reportDocument(String id) async => ReportSummary.fromJson(obj(await client.get('reports/$id/document'))!);

  Future<void> submitReport(String id) => client.post('reports/$id/submit');

  Future<void> approveReport(String id, {String? comment}) => client.post('reports/$id/approve', {'comment': comment});

  Future<void> returnReport(String id, String comment) => client.post('reports/$id/return', {'comment': comment});

  Future<void> publishReport(String id) => client.patch('reports/$id/publish');

  // ---------------------------------------------------------------- public portal (no account)

  Future<List<Agency>> agencies() async => items(await client.get('public/tenants', auth: false)).map(Agency.fromJson).toList();

  Future<List<CompanyRef>> publicCompanies(String agency) async =>
      items(await client.get('public/$agency/employers', auth: false)).map((j) => CompanyRef(text(j['id']), text(j['name']))).toList();

  /// Returns the reference number and tracking code the reporter keeps.
  Future<({String reference, String trackingCode, String message})> submitPublicComplaint(
    String agency, {
    required String description,
    required String urgency,
    String? companyName,
    String? location,
    bool anonymous = true,
    String? name,
    String? contact,
  }) async {
    final j = obj(await client.post('public/$agency/complaints', {
      'description': description,
      'urgency': urgency,
      if (companyName != null && companyName.isNotEmpty) 'employerName': companyName,
      if (location != null && location.isNotEmpty) 'location': location,
      'anonymous': anonymous,
      if (!anonymous) 'name': name,
      if (!anonymous) 'contact': contact,
    }, false))!;
    return (reference: text(j['referenceNumber']), trackingCode: text(j['trackingCode']), message: text(j['message']));
  }

  Future<Json> trackComplaint(String agency, String reference, String code) async =>
      obj(await client.get('public/$agency/complaints/track', query: {'reference': reference.trim(), 'code': code.trim()}, auth: false)) ??
      const {};

  static String _dateTime(DateTime d) => d.toIso8601String().split('.').first;
}
