import 'json.dart';

// ---------------------------------------------------------------- account

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    this.firstName,
    this.lastName,
    this.employerId,
    this.employerName,
    this.tenantName,
    this.tenantCode,
    this.mustChangePassword = false,
  });

  factory AppUser.fromJson(Json j) => AppUser(
        id: text(j['id']),
        name: text(j['name'], text(j['email'])),
        email: text(j['email']),
        firstName: str(j['firstName']),
        lastName: str(j['lastName']),
        role: text(j['role']).toLowerCase(),
        permissions: ((j['permissions'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        employerId: str(j['employerId']),
        employerName: str(j['employerName']),
        tenantName: str(j['tenantName']),
        tenantCode: str(j['tenantCode']),
        mustChangePassword: flag(j['mustChangePassword']),
      );

  final String id;
  final String name;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role;
  final Set<String> permissions;
  final String? employerId;
  final String? employerName;
  final String? tenantName;
  final String? tenantCode;
  final bool mustChangePassword;

  bool get isEmployer => role == 'employer';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || isSuperAdmin;
  bool get isStaff => role == 'admin' || role == 'officer';
  bool can(String permission) => permissions.contains(permission);

  String get roleLabel => switch (role) {
        'admin' => 'Administrator',
        'officer' => 'OHS Officer',
        'employer' => 'Company user',
        'super_admin' => 'Platform super-admin',
        _ => role,
      };

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  AppUser copyWith({String? role, String? tenantName}) => AppUser(
        id: id,
        name: name,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role ?? this.role,
        permissions: permissions,
        employerId: employerId,
        employerName: employerName,
        tenantName: tenantName ?? this.tenantName,
        tenantCode: tenantCode,
        mustChangePassword: mustChangePassword,
      );

  Json toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'permissions': permissions.toList(),
        'employerId': employerId,
        'employerName': employerName,
        'tenantName': tenantName,
        'tenantCode': tenantCode,
        'mustChangePassword': mustChangePassword,
      };
}

class AuthResult {
  AuthResult({required this.token, required this.user, this.idleMinutes, this.expiresAt});

  factory AuthResult.fromJson(Json j) => AuthResult(
        token: text(j['token'] ?? j['accessToken']),
        user: AppUser.fromJson(obj(j['user']) ?? const {}),
        idleMinutes: integer(j['idleTimeoutMinutes']),
        expiresAt: date(j['sessionExpiresAt']),
      );

  final String token;
  final AppUser user;
  final int? idleMinutes;
  final DateTime? expiresAt;
}

class UserSession {
  UserSession.fromJson(Json j)
      : id = text(j['id']),
        device = text(j['device'], 'Unknown device'),
        ipAddress = str(j['ipAddress']),
        createdAt = date(j['createdAt']),
        lastSeenAt = date(j['lastSeenAt']),
        expiresAt = date(j['expiresAt']),
        active = flag(j['active']),
        current = flag(j['current']),
        endReason = str(j['endReason']);

  final String id;
  final String device;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final DateTime? expiresAt;
  final bool active;
  final bool current;
  final String? endReason;
}

class Profile {
  Profile.fromJson(Json j)
      : fullName = text(j['fullName']),
        email = text(j['email']),
        phoneNumber = str(j['phoneNumber']),
        department = str(j['department']),
        location = str(j['location']),
        role = text(j['role']),
        employeeId = str(j['employeeId']),
        dateJoined = date(j['dateJoined']),
        lastLogin = date(j['lastLogin']),
        stats = obj(j['stats']) ?? const {};

  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? department;
  final String? location;
  final String role;
  final String? employeeId;
  final DateTime? dateJoined;
  final DateTime? lastLogin;
  final Json stats;
}

// ---------------------------------------------------------------- records

class CompanyRef {
  CompanyRef(this.id, this.name);

  static CompanyRef? from(Object? v) {
    final m = obj(v);
    if (m == null || m['id'] == null) return null;
    return CompanyRef(m['id'].toString(), text(m['name'], 'Company'));
  }

  final String id;
  final String name;
}

class Incident {
  Incident.fromJson(Json j)
      : id = text(j['id']),
        reference = text(j['referenceNumber']),
        type = text(j['type']),
        status = text(j['status']),
        severity = text(j['severity']),
        title = text(j['title'], 'Incident'),
        description = text(j['description']),
        location = text(j['location']),
        incidentDate = date(j['incidentDate']),
        reportedDate = date(j['reportedDate'] ?? j['createdAt']),
        company = CompanyRef.from(j['employer']),
        personsAffected = integer(j['numberOfPersonsAffected']),
        lostWorkDays = integer(j['lostWorkDays']),
        investigationNotes = str(j['investigationNotes']),
        correctiveActions = str(j['correctiveActions']),
        anonymous = flag(j['anonymous']);

  final String id;
  final String reference;
  final String type;
  final String status;
  final String severity;
  final String title;
  final String description;
  final String location;
  final DateTime? incidentDate;
  final DateTime? reportedDate;
  final CompanyRef? company;
  final int? personsAffected;
  final int? lostWorkDays;
  final String? investigationNotes;
  final String? correctiveActions;
  final bool anonymous;

  static const types = ['FATALITY', 'SERIOUS_INJURY', 'INJURY', 'NEAR_MISS', 'HAZARD'];
  static const severities = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
  static const statuses = ['REPORTED', 'ASSIGNED', 'INVESTIGATING', 'RESOLVED', 'CLOSED'];
}

class Inspection {
  Inspection.fromJson(Json j)
      : id = text(j['id']),
        reference = text(j['referenceNumber']),
        type = text(j['type'], 'routine'),
        status = text(j['status'], 'scheduled'),
        scheduledDate = date(j['scheduledDate']),
        completedDate = date(j['completedDate']),
        complianceScore = number(j['complianceScore']),
        company = CompanyRef.from(j['employer']),
        inspectorName = str(j['inspectorName']),
        notes = str(j['notes']),
        findings = str(j['findings']),
        recommendations = str(j['recommendations']),
        violations = integer(j['violationsCount']);

  final String id;
  final String reference;
  final String type;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final double? complianceScore;
  final CompanyRef? company;
  final String? inspectorName;
  final String? notes;
  final String? findings;
  final String? recommendations;
  final int? violations;

  static const types = ['routine', 'follow_up', 'complaint_driven', 'special'];
  static const statuses = ['scheduled', 'in_progress', 'completed', 'cancelled'];
}

class Complaint {
  Complaint.fromJson(Json j)
      : id = text(j['id']),
        reference = text(j['referenceNumber']),
        type = text(j['type'], 'other'),
        status = text(j['status'], 'received'),
        urgency = text(j['urgency'], 'normal'),
        description = text(j['description']),
        location = str(j['location']),
        company = CompanyRef.from(j['employer']),
        reportedCompanyName = str(j['reportedEmployerName']),
        anonymous = flag(j['anonymous']),
        complainantName = str(j['complainantName']),
        complainantContact = str(j['complainantContact']),
        assignedTo = str(j['assignedTo']),
        resolutionNotes = str(j['resolutionNotes']),
        source = str(j['source']),
        createdAt = date(j['createdAt']);

  final String id;
  final String reference;
  final String type;
  final String status;
  final String urgency;
  final String description;
  final String? location;
  final CompanyRef? company;
  final String? reportedCompanyName;
  final bool anonymous;
  final String? complainantName;
  final String? complainantContact;
  final String? assignedTo;
  final String? resolutionNotes;
  final String? source;
  final DateTime? createdAt;

  String get companyLabel => company?.name ?? reportedCompanyName ?? 'Company not identified';

  static const statuses = ['received', 'assigned', 'investigating', 'resolved', 'closed'];
}

class EnforcementNotice {
  EnforcementNotice.fromJson(Json j)
      : id = text(j['id']),
        reference = text(j['referenceNumber']),
        company = CompanyRef.from(j['employer']),
        violation = text(j['violation'], 'Violation'),
        details = str(j['details']),
        penalty = str(j['penalty']),
        status = text(j['status'], 'issued'),
        actionType = text(j['actionType'], 'warning'),
        dueDate = date(j['dueDate']),
        appealDeadline = date(j['appealDeadline']),
        notes = str(j['notes']),
        inspector = obj(j['inspector']) == null
            ? null
            : '${text(obj(j['inspector'])!['firstName'])} ${text(obj(j['inspector'])!['lastName'])}'.trim(),
        createdAt = date(j['createdAt']);

  final String id;
  final String reference;
  final CompanyRef? company;
  final String violation;
  final String? details;
  final String? penalty;
  final String status;
  final String actionType;
  final DateTime? dueDate;
  final DateTime? appealDeadline;
  final String? notes;
  final String? inspector;
  final DateTime? createdAt;

  static const statuses = ['issued', 'active', 'under_appeal', 'resolved', 'closed'];
}

class CorrectiveAction {
  CorrectiveAction.fromJson(Json j)
      : id = text(j['id']),
        reference = text(j['referenceNumber']),
        title = text(j['title'], 'Corrective action'),
        description = str(j['description']),
        sourceType = str(j['sourceType']),
        sourceReference = str(j['sourceReference']),
        company = CompanyRef.from(j['employer']),
        assignedTo = str(j['assignedTo']),
        priority = text(j['priority'], 'medium'),
        status = text(j['status'], 'open'),
        dueDate = date(j['dueDate']),
        completedDate = date(j['completedDate']),
        completionNotes = str(j['completionNotes']),
        verifiedBy = str(j['verifiedBy']),
        verifiedDate = date(j['verifiedDate']),
        verificationNotes = str(j['verificationNotes']);

  final String id;
  final String reference;
  final String title;
  final String? description;
  final String? sourceType;
  final String? sourceReference;
  final CompanyRef? company;
  final String? assignedTo;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String? completionNotes;
  final String? verifiedBy;
  final DateTime? verifiedDate;
  final String? verificationNotes;

  bool get isOverdue {
    final due = dueDate;
    if (due == null || const ['completed', 'verified', 'cancelled'].contains(status.toLowerCase())) return false;
    final today = DateTime.now();
    return due.isBefore(DateTime(today.year, today.month, today.day));
  }

  static const statuses = ['open', 'in_progress', 'completed', 'verified', 'cancelled'];
}

class Company {
  Company.fromJson(Json j)
      : id = text(j['id']),
        name = text(j['name'], 'Company'),
        registrationNumber = str(j['registrationNumber']),
        sector = str(j['sector']),
        district = str(j['district']),
        province = str(j['province']),
        address = str(j['address']),
        email = str(j['email']),
        phone = str(j['phoneNumber']),
        employees = integer(j['numberOfEmployees']),
        riskLevel = text(j['riskLevel'], 'LOW'),
        complianceScore = number(j['complianceScore']),
        status = text(j['status'], 'ACTIVE'),
        safetyOfficerName = str(j['safetyOfficerName']),
        safetyOfficerPhone = str(j['safetyOfficerPhone']),
        emergencyContactName = str(j['emergencyContactName']),
        emergencyContactPhone = str(j['emergencyContactPhone']),
        profileCompleteness = integer(j['profileCompleteness']),
        incidentsCount = integer(j['incidentsCount']),
        inspectionsCount = integer(j['inspectionsCount']),
        complaintsCount = integer(j['complaintsCount']),
        mainHazards = str(j['mainHazards']),
        raw = j;

  final String id;
  final String name;
  final String? registrationNumber;
  final String? sector;
  final String? district;
  final String? province;
  final String? address;
  final String? email;
  final String? phone;
  final int? employees;
  final String riskLevel;
  final double? complianceScore;
  final String status;
  final String? safetyOfficerName;
  final String? safetyOfficerPhone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final int? profileCompleteness;
  final int? incidentsCount;
  final int? inspectionsCount;
  final int? complaintsCount;
  final String? mainHazards;
  final Json raw;
}

class AppNotification {
  AppNotification.fromJson(Json j)
      : id = text(j['id']),
        title = text(j['title'], 'Notification'),
        message = text(j['message']),
        type = text(j['type'], 'INFO'),
        read = flag(j['read']),
        entityType = str(j['entityType']),
        entityId = str(j['entityId']),
        actionUrl = str(j['actionUrl']),
        createdAt = date(j['createdAt']);

  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final String? entityType;
  final String? entityId;
  final String? actionUrl;
  final DateTime? createdAt;
}

// ---------------------------------------------------------------- IoT

class HazardEvent {
  HazardEvent.fromJson(Json j)
      : id = text(j['id']),
        reference = text(j['referenceNumber']),
        deviceName = text(obj(j['device'])?['name'], 'Sensor'),
        deviceType = str(obj(j['device'])?['deviceType']),
        zone = str(obj(j['device'])?['zone']),
        company = CompanyRef.from(j['employer'] ?? obj(j['device'])?['employer']),
        metric = text(j['metric']),
        value = number(j['value']),
        threshold = number(j['threshold']),
        unit = str(j['unit']),
        severity = text(j['severity'], 'MEDIUM'),
        source = str(j['source']),
        ruleName = str(j['ruleName']),
        message = text(j['message']),
        guidance = str(j['guidance']),
        status = text(j['status'], 'OPEN'),
        occurrences = integer(j['occurrences']) ?? 1,
        detectedAt = date(j['detectedAt']),
        lastTriggeredAt = date(j['lastTriggeredAt']),
        acknowledgedBy = str(j['acknowledgedBy']),
        resolvedBy = str(j['resolvedBy']),
        notes = str(j['notes']),
        incidentReference = str(j['incidentReference']);

  final String id;
  final String reference;
  final String deviceName;
  final String? deviceType;
  final String? zone;
  final CompanyRef? company;
  final String metric;
  final double? value;
  final double? threshold;
  final String? unit;
  final String severity;
  final String? source;
  final String? ruleName;
  final String message;
  final String? guidance;
  final String status;
  final int occurrences;
  final DateTime? detectedAt;
  final DateTime? lastTriggeredAt;
  final String? acknowledgedBy;
  final String? resolvedBy;
  final String? notes;
  final String? incidentReference;

  bool get isOpen => status == 'OPEN' || status == 'ACKNOWLEDGED';
}

class IotDevice {
  IotDevice.fromJson(Json j)
      : id = text(j['id']),
        name = text(j['name'], 'Device'),
        deviceType = text(j['deviceType']),
        zone = str(j['zone']),
        location = str(j['locationDescription']),
        status = text(j['status']),
        online = flag(j['online']),
        lastSeenAt = date(j['lastSeenAt']),
        company = CompanyRef.from(j['employer']);

  final String id;
  final String name;
  final String deviceType;
  final String? zone;
  final String? location;
  final String status;
  final bool online;
  final DateTime? lastSeenAt;
  final CompanyRef? company;
}

class Recommendation {
  Recommendation.fromJson(Json j)
      : key = text(j['key']),
        category = text(j['category']),
        priority = text(j['priority'], 'MEDIUM'),
        title = text(j['title']),
        rationale = text(j['rationale']),
        actions = ((j['actions'] as List?) ?? const [])
            .whereType<Map>()
            .map((a) => (action: text(a['action']), level: text(a['level'])))
            .toList(),
        companyName = nestedName(j['employer']),
        deviceName = str(j['deviceName']),
        zone = str(j['zone']),
        confidence = number(j['confidence']);

  final String key;
  final String category;
  final String priority;
  final String title;
  final String rationale;
  final List<({String action, String level})> actions;
  final String? companyName;
  final String? deviceName;
  final String? zone;
  final double? confidence;
}

// ---------------------------------------------------------------- reports

class ReportSummary {
  ReportSummary.fromJson(Json j)
      : id = text(j['id']),
        reference = text(j['referenceNumber']),
        title = text(j['title'], 'Report'),
        type = text(j['type']),
        category = text(j['category']),
        status = text(j['status'], 'DRAFT'),
        periodFrom = str(j['periodFrom']),
        periodTo = str(j['periodTo']),
        district = str(j['district']),
        sector = str(j['sector']),
        employerName = str(j['employerName']),
        version = integer(j['version']) ?? 1,
        summary = str(j['summary']),
        findings = str(j['findings']),
        recommendations = str(j['recommendations']),
        preparedByName = str(j['preparedByName']),
        preparedById = str(j['preparedById']),
        approvedByName = str(j['approvedByName']),
        reviewComment = str(j['reviewComment']),
        createdAt = date(j['createdAt']),
        updatedAt = date(j['updatedAt']),
        publishedAt = date(j['publishedAt']),
        content = obj(j['content']);

  final String id;
  final String reference;
  final String title;
  final String type;
  final String category;
  final String status;
  final String? periodFrom;
  final String? periodTo;
  final String? district;
  final String? sector;
  final String? employerName;
  final int version;
  final String? summary;
  final String? findings;
  final String? recommendations;
  final String? preparedByName;
  final String? preparedById;
  final String? approvedByName;
  final String? reviewComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  /// Frozen figures — present only when loaded through the document endpoint.
  final Json? content;

  String get period => periodFrom == null && periodTo == null ? 'All time' : '${periodFrom ?? 'start'} to ${periodTo ?? 'today'}';

  String get scope {
    final parts = [
      if (employerName != null) 'Company: $employerName',
      if (district != null) 'District: $district',
      if (sector != null) 'Sector: $sector',
    ];
    return parts.isEmpty ? 'Whole agency' : parts.join(' · ');
  }

  List<({String label, Object? value})> get kpis => ((content?['kpis'] as List?) ?? const [])
      .whereType<Map>()
      .map((k) => (label: text(k['label']), value: k['value']))
      .toList();

  List<Json> get sections => items(content?['sections']);

  List<String> get autoFindings => ((content?['findings'] as List?) ?? const []).map((e) => e.toString()).toList();
}

// ---------------------------------------------------------------- public portal

class Agency {
  Agency.fromJson(Json j)
      : name = text(j['name']),
        code = text(j['code']),
        country = str(j['country']);

  final String name;
  final String code;
  final String? country;
}
