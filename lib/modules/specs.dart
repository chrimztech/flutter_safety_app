import 'package:flutter/material.dart';

import '../data/fields.dart';
import '../data/models.dart';
import '../data/json.dart';
import '../ui/format.dart';
import 'module_spec.dart';

/// Record types that use the generic screens. Fields, options and permissions follow the web app's pages and the
/// backend's checks (`@PreAuthorize` and the company-user allow-list).
///
/// Permissions (see DataInitializer): officers have employers/incidents/inspections/complaints read+write,
/// analytics and medical read, reports read; administrators have everything in their agency. Company users read their
/// own company's records only.

bool _companyOnly(AppUser me, Json r) => me.isEmployer;

String _today() => DateTime.now().toIso8601String().substring(0, 10);

const _company = FieldSpec('employerId', 'Company', FieldKind.company, required: true);
const _companyOptional = FieldSpec('employerId', 'Company', FieldKind.company);

// ---------------------------------------------------------------- accident investigations

final investigationsSpec = ModuleSpec(
  id: 'accidentinvestigation',
  title: 'Accident investigations',
  singular: 'Investigation',
  icon: Icons.manage_search,
  path: 'accident-investigations',
  titleOf: (r) => text(r['title'], 'Investigation'),
  subtitleOf: (r) => [text(r['referenceNumber']), if (r['accidentDate'] != null) fmtDate(date(r['accidentDate']))].join(' · '),
  statusKey: 'status',
  statusFilters: const ['OPEN', 'IN_PROGRESS', 'COMPLETED', 'CLOSED'],
  toneKey: 'severity',
  attachmentType: 'INVESTIGATION',
  canCreate: (me) => me.isStaff && me.can('incidents:write'),
  canEdit: (me) => me.isStaff && me.can('incidents:write'),
  canDelete: (me) => me.isStaff && me.can('incidents:write'),
  details: const [
    DetailItem('Reference', 'referenceNumber'),
    DetailItem('Company', 'employer', ShowAs.company),
    DetailItem('Accident date', 'accidentDate', ShowAs.date),
    DetailItem('Location', 'location'),
    DetailItem('Department', 'department'),
    DetailItem('Lead investigator', 'leadInvestigator'),
    DetailItem('Persons involved', 'personsInvolved', ShowAs.number),
    DetailItem('Fatalities', 'fatalities', ShowAs.number),
    DetailItem('Injuries', 'injuries', ShowAs.number),
    DetailItem('Estimated loss', 'estimatedLoss', ShowAs.money),
    DetailItem('Started', 'investigationStartDate', ShowAs.date),
    DetailItem('Finished', 'investigationEndDate', ShowAs.date),
    DetailItem('What happened', 'description', ShowAs.longText),
    DetailItem('Immediate actions', 'immediateActions', ShowAs.longText),
    DetailItem('Root cause', 'rootCause', ShowAs.longText),
    DetailItem('Contributing factors', 'contributingFactors', ShowAs.longText),
    DetailItem('Findings', 'findings', ShowAs.longText),
    DetailItem('Corrective actions', 'correctiveActions', ShowAs.longText),
    DetailItem('Preventive measures', 'preventiveMeasures', ShowAs.longText),
    DetailItem('Recommendations', 'recommendations', ShowAs.longText),
    DetailItem('Witnesses', 'witnesses', ShowAs.longText),
  ],
  createFields: [
    const FieldSpec('title', 'Title', FieldKind.text, required: true),
    _company,
    const FieldSpec('severity', 'Severity', FieldKind.choice, required: true, initial: 'MEDIUM', options: [('CRITICAL', 'Critical'), ('HIGH', 'High'), ('MEDIUM', 'Medium'), ('LOW', 'Low')]),
    const FieldSpec('accidentDate', 'Accident date', FieldKind.date, required: true),
    const FieldSpec('location', 'Location', FieldKind.text),
    const FieldSpec('department', 'Department', FieldKind.text),
    const FieldSpec('fatalities', 'Fatalities', FieldKind.integer, initial: 0, min: 0),
    const FieldSpec('injuries', 'Injuries', FieldKind.integer, initial: 0, min: 0),
    const FieldSpec('leadInvestigator', 'Lead investigator', FieldKind.text),
    const FieldSpec('description', 'What happened', FieldKind.multiline),
  ],
  editFields: const [],
  actions: [
    const ModuleAction(
      label: 'Update investigation',
      icon: Icons.edit_note,
      success: 'Investigation updated',
      fields: [
        FieldSpec('status', 'Status', FieldKind.choice, required: true, options: [('OPEN', 'Open'), ('IN_PROGRESS', 'In progress'), ('COMPLETED', 'Completed'), ('CLOSED', 'Closed')]),
        FieldSpec('rootCause', 'Root cause', FieldKind.multiline),
        FieldSpec('findings', 'Findings', FieldKind.multiline),
        FieldSpec('correctiveActions', 'Corrective actions', FieldKind.multiline),
        FieldSpec('preventiveMeasures', 'Preventive measures', FieldKind.multiline),
        FieldSpec('recommendations', 'Recommendations', FieldKind.multiline),
      ],
    ),
  ],
);

// ---------------------------------------------------------------- risk assessments

const _likelihood = [('1', '1 — Rare'), ('2', '2 — Unlikely'), ('3', '3 — Possible'), ('4', '4 — Likely'), ('5', '5 — Almost certain')];
const _severity = [('1', '1 — Insignificant'), ('2', '2 — Minor'), ('3', '3 — Moderate'), ('4', '4 — Major'), ('5', '5 — Catastrophic')];

String riskBand(num score) => score >= 15 ? 'EXTREME' : score >= 10 ? 'HIGH' : score >= 5 ? 'MEDIUM' : 'LOW';

String _riskLabel(Json r, String l, String s) {
  final a = integer(r[l]), b = integer(r[s]);
  if (a == null || b == null) return '—';
  return '${a * b} (${humanize(riskBand(a * b))})';
}

final riskAssessmentsSpec = ModuleSpec(
  reviewType: 'RISK_ASSESSMENT',
  canCreate: companyKeeps,
  canEdit: companyKeeps,
  canDelete: companyKeeps,
  id: 'risk-assessments',
  title: 'Risk assessments',
  singular: 'Risk assessment',
  icon: Icons.casino_outlined,
  path: 'risk-assessments',
  titleOf: (r) => text(r['title'], text(r['hazard'], 'Risk assessment')),
  subtitleOf: (r) => 'Risk ${_riskLabel(r, 'likelihood', 'severity')} → ${_riskLabel(r, 'residualLikelihood', 'residualSeverity')}',
  statusKey: 'status',
  statusFilters: const ['draft', 'active', 'under_review', 'closed'],
  attachmentType: 'RISK_ASSESSMENT',
  description: 'Risk = likelihood × severity (1–25). Residual risk is after the additional controls.',
  details: const [
    DetailItem('Reference', 'referenceNumber'),
    DetailItem('Company', 'employer', ShowAs.company),
    DetailItem('Hazard', 'hazard'),
    DetailItem('Activity', 'activity'),
    DetailItem('Location', 'location'),
    DetailItem('Persons at risk', 'personsAtRisk'),
    DetailItem('Likelihood', 'likelihood', ShowAs.number),
    DetailItem('Severity', 'severity', ShowAs.number),
    DetailItem('Residual likelihood', 'residualLikelihood', ShowAs.number),
    DetailItem('Residual severity', 'residualSeverity', ShowAs.number),
    DetailItem('Owner', 'owner'),
    DetailItem('Assessed by', 'assessedBy'),
    DetailItem('Assessed', 'assessmentDate', ShowAs.date),
    DetailItem('Review by', 'reviewDate', ShowAs.date),
    DetailItem('Description', 'description', ShowAs.longText),
    DetailItem('Existing controls', 'existingControls', ShowAs.longText),
    DetailItem('Additional controls', 'additionalControls', ShowAs.longText),
  ],
  createFields: [
    const FieldSpec('title', 'Title', FieldKind.text, required: true),
    _company,
    const FieldSpec('hazard', 'Hazard', FieldKind.text, required: true),
    const FieldSpec('activity', 'Activity', FieldKind.text),
    const FieldSpec('location', 'Location', FieldKind.text),
    const FieldSpec('personsAtRisk', 'Persons at risk', FieldKind.text),
    const FieldSpec('description', 'Description', FieldKind.multiline),
    const FieldSpec('likelihood', 'Likelihood', FieldKind.choice, required: true, initial: '3', options: _likelihood),
    const FieldSpec('severity', 'Severity', FieldKind.choice, required: true, initial: '3', options: _severity),
    const FieldSpec('existingControls', 'Existing controls', FieldKind.multiline),
    const FieldSpec('additionalControls', 'Additional controls', FieldKind.multiline),
    const FieldSpec('residualLikelihood', 'Residual likelihood', FieldKind.choice, initial: '2', options: _likelihood),
    const FieldSpec('residualSeverity', 'Residual severity', FieldKind.choice, initial: '3', options: _severity),
    const FieldSpec('owner', 'Owner', FieldKind.text),
    const FieldSpec('reviewDate', 'Review date', FieldKind.date),
    const FieldSpec('status', 'Status', FieldKind.choice, initial: 'active', options: [('draft', 'Draft'), ('active', 'Active'), ('under_review', 'Under review'), ('closed', 'Closed')]),
  ],
);

// ---------------------------------------------------------------- permits

const _permitStatuses = ['PENDING', 'APPROVED', 'ACTIVE', 'EXPIRED', 'SUSPENDED', 'REVOKED', 'RENEWAL_PENDING'];

final permitsSpec = ModuleSpec(
  id: 'permits',
  title: 'Permits & licences',
  singular: 'Permit',
  icon: Icons.verified_outlined,
  path: 'permits',
  titleOf: (r) => text(r['title'], text(r['type'], 'Permit')),
  subtitleOf: (r) => [text(r['permitNumber']), if (r['expiryDate'] != null) 'Expires ${fmtDate(date(r['expiryDate']))}'].join(' · '),
  statusKey: 'status',
  statusFilters: _permitStatuses,
  canCreate: (me) => me.isStaff && me.can('employers:write'),
  canEdit: (me) => me.isStaff && me.can('employers:write'),
  canDelete: (me) => me.isStaff && me.can('employers:write'),
  sort: (a, b) => text(a['expiryDate'], '9999').compareTo(text(b['expiryDate'], '9999')),
  createExtras: const {'status': 'ACTIVE'},
  details: const [
    DetailItem('Permit number', 'permitNumber'),
    DetailItem('Company', 'employer', ShowAs.company),
    DetailItem('Type', 'type'),
    DetailItem('Category', 'category'),
    DetailItem('Activity', 'activity'),
    DetailItem('Issued', 'issuedDate', ShowAs.date),
    DetailItem('Expires', 'expiryDate', ShowAs.date),
    DetailItem('Renewed', 'renewalDate', ShowAs.date),
    DetailItem('Issuing authority', 'issuingAuthority'),
    DetailItem('Issued by', 'issuedBy'),
    DetailItem('Fee', 'fee', ShowAs.money),
    DetailItem('Fee status', 'feeStatus', ShowAs.tag),
    DetailItem('Description', 'description', ShowAs.longText),
    DetailItem('Conditions', 'conditions', ShowAs.longText),
    DetailItem('Notes', 'notes', ShowAs.longText),
  ],
  createFields: [
    _company,
    const FieldSpec('type', 'Type', FieldKind.choice, required: true, initial: 'Operating License', options: [
      ('Operating License', 'Operating licence'), ('Factory Registration', 'Factory registration'), ('Hot Work Permit', 'Hot work permit'),
      ('Confined Space Permit', 'Confined space permit'), ('Work at Height Permit', 'Work at height permit'), ('Explosives Permit', 'Explosives permit'),
      ('Boiler Certificate', 'Boiler certificate'), ('Other', 'Other'),
    ]),
    const FieldSpec('title', 'Title', FieldKind.text, required: true),
    const FieldSpec('category', 'Category', FieldKind.text, initial: 'General'),
    const FieldSpec('activity', 'Activity', FieldKind.text),
    const FieldSpec('issuedDate', 'Issued', FieldKind.date),
    const FieldSpec('expiryDate', 'Expires', FieldKind.date, required: true),
    const FieldSpec('issuingAuthority', 'Issuing authority', FieldKind.text, initial: 'Zambia Occupational Health & Safety Board'),
    const FieldSpec('fee', 'Fee (K)', FieldKind.decimal, initial: 0),
    const FieldSpec('feeStatus', 'Fee status', FieldKind.choice, initial: 'PENDING', options: [('PENDING', 'Pending'), ('PAID', 'Paid'), ('WAIVED', 'Waived')]),
    const FieldSpec('description', 'Description', FieldKind.multiline),
    const FieldSpec('conditions', 'Conditions', FieldKind.multiline),
  ],
  editFields: [
    const FieldSpec('title', 'Title', FieldKind.text, required: true),
    FieldSpec('status', 'Status', FieldKind.choice, required: true, options: opts(_permitStatuses)),
    const FieldSpec('expiryDate', 'Expires', FieldKind.date),
    const FieldSpec('conditions', 'Conditions', FieldKind.multiline),
    const FieldSpec('description', 'Description', FieldKind.multiline),
  ],
  actions: [
    ModuleAction(
      label: 'Renew',
      icon: Icons.autorenew,
      success: 'Permit renewed',
      fields: const [FieldSpec('expiryDate', 'New expiry date', FieldKind.date, required: true)],
      fixed: const {'status': 'ACTIVE'},
      computeFixed: (_) => {'renewalDate': _today()},
      visible: (me, r) => me.isStaff && me.can('employers:write'),
    ),
  ],
);

// ---------------------------------------------------------------- emergency response

const _responseTypes = [('FIRE', 'Fire'), ('CHEMICAL_SPILL', 'Chemical spill'), ('MEDICAL', 'Medical emergency'), ('EXPLOSION', 'Explosion'), ('STRUCTURAL', 'Structural collapse'), ('OTHER', 'Other')];

final emergencySpec = ModuleSpec(
  reviewType: 'EMERGENCY_RESPONSE',
  canCreate: companyKeeps,
  canEdit: companyKeeps,
  canDelete: companyKeeps,
  id: 'emergency',
  title: 'Emergency response',
  singular: 'Emergency response',
  icon: Icons.local_fire_department_outlined,
  path: 'emergency-response',
  titleOf: (r) => '${_responseTypes.firstWhere((t) => t.$1 == text(r['responseType']), orElse: () => (text(r['responseType']), humanize(text(r['responseType'])))).$2} — ${text(r['location'], 'location not given')}',
  subtitleOf: (r) => fmtDateTime(date(r['responseTime'] ?? r['createdAt'])),
  statusKey: 'status',
  statusFilters: const ['ACTIVE', 'CONTAINED', 'RESOLVED'],
  details: const [
    DetailItem('Company', 'employer', ShowAs.company),
    DetailItem('Incident', 'incident.referenceNumber'),
    DetailItem('Type', 'responseType', ShowAs.tag),
    DetailItem('Location', 'location'),
    DetailItem('Responded', 'responseTime', ShowAs.dateTime),
    DetailItem('Duration', 'responseDuration'),
    DetailItem('Responders', 'responders', ShowAs.list),
    DetailItem('Actions taken', 'actionsTaken', ShowAs.list),
    DetailItem('Equipment used', 'equipmentUsed', ShowAs.list),
    DetailItem('Notes', 'notes', ShowAs.longText),
  ],
  createFields: const [
    FieldSpec('responseType', 'Type', FieldKind.choice, required: true, initial: 'FIRE', options: _responseTypes),
    _companyOptional,
    FieldSpec('location', 'Location', FieldKind.text, required: true),
    FieldSpec('responseDuration', 'Duration', FieldKind.text, hint: 'e.g. 45 minutes'),
    FieldSpec('responders', 'Responders', FieldKind.multiline, help: 'Separate with commas'),
    FieldSpec('actionsTaken', 'Actions taken', FieldKind.multiline, help: 'Separate with commas'),
    FieldSpec('equipmentUsed', 'Equipment used', FieldKind.text, help: 'Separate with commas'),
    FieldSpec('notes', 'Notes', FieldKind.multiline),
  ],
  editFields: const [],
  actions: const [
    ModuleAction(
      label: 'Update status',
      visible: _companyOnly,
      icon: Icons.flag_outlined,
      success: 'Response updated',
      fields: [
        FieldSpec('status', 'Status', FieldKind.choice, required: true, options: [('ACTIVE', 'Active'), ('CONTAINED', 'Contained'), ('RESOLVED', 'Resolved')]),
        FieldSpec('notes', 'Notes', FieldKind.multiline),
      ],
    ),
  ],
);

// ---------------------------------------------------------------- safety culture

const _scoreKeys = [
  ('leadershipScore', 'Leadership'), ('communicationScore', 'Communication'), ('employeeEngagementScore', 'Employee engagement'),
  ('hazardReportingScore', 'Hazard reporting'), ('trainingScore', 'Training'), ('incidentResponseScore', 'Incident response'),
];

final safetyCultureSpec = ModuleSpec(
  reviewType: 'SAFETY_CULTURE',
  canCreate: companyKeeps,
  canEdit: companyKeeps,
  canDelete: companyKeeps,
  id: 'safetyculture',
  title: 'Safety culture',
  singular: 'Safety culture assessment',
  icon: Icons.groups_outlined,
  path: 'safety-culture',
  titleOf: (r) => text(r['assessmentTitle'], '${humanize(text(r['assessmentType'], 'Assessment'))} assessment'),
  subtitleOf: (r) => 'Overall ${fmtNum(r['overallScore'] ?? 0)}/100 · ${humanize(text(r['rating'], 'unrated'))} · ${fmtDate(date(r['assessmentDate']))}',
  statusKey: 'rating',
  details: [
    const DetailItem('Company', 'employer', ShowAs.company),
    const DetailItem('Type', 'assessmentType', ShowAs.tag),
    const DetailItem('Date', 'assessmentDate', ShowAs.date),
    const DetailItem('Conducted by', 'conductedBy'),
    const DetailItem('Employees surveyed', 'totalEmployeesSurveyed', ShowAs.number),
    const DetailItem('Response rate (%)', 'responseRate', ShowAs.number),
    const DetailItem('Overall score', 'overallScore', ShowAs.number),
    for (final (k, l) in _scoreKeys) DetailItem(l, k, ShowAs.number),
    const DetailItem('Strengths', 'strengths', ShowAs.longText),
    const DetailItem('Areas for improvement', 'areasForImprovement', ShowAs.longText),
    const DetailItem('Recommendations', 'recommendations', ShowAs.longText),
    const DetailItem('Action plan', 'actionPlan', ShowAs.longText),
  ],
  createFields: [
    _company,
    const FieldSpec('assessmentType', 'Type', FieldKind.choice, required: true, initial: 'ANNUAL',
        options: [('ANNUAL', 'Annual'), ('QUARTERLY', 'Quarterly'), ('FOLLOW_UP', 'Follow-up'), ('INCIDENT_DRIVEN', 'Incident-driven')]),
    const FieldSpec('assessmentDate', 'Date', FieldKind.date),
    const FieldSpec('conductedBy', 'Conducted by', FieldKind.text),
    const FieldSpec('totalEmployeesSurveyed', 'Employees surveyed', FieldKind.integer, initial: 0, min: 0),
    for (final (k, l) in _scoreKeys) FieldSpec(k, l, FieldKind.score, initial: 0, min: 0, max: 100),
    const FieldSpec('recommendations', 'Recommendations', FieldKind.multiline),
  ],
);

// ---------------------------------------------------------------- medical surveillance

const _examTypes = ['PRE_EMPLOYMENT', 'PERIODIC', 'RETURN_TO_WORK', 'EXIT', 'SPECIAL', 'POST_INCIDENT'];
const _fitness = ['FIT', 'FIT_WITH_RESTRICTIONS', 'TEMPORARILY_UNFIT', 'PERMANENTLY_UNFIT', 'PENDING_REVIEW'];

final medicalSpec = ModuleSpec(
  reviewType: 'MEDICAL_SURVEILLANCE',
  canView: (me) => me.isEmployer || me.can('medical:read'),
  canCreate: companyKeeps,
  canEdit: companyKeeps,
  canDelete: companyKeeps,
  id: 'medical',
  title: 'Medical surveillance',
  singular: 'Medical examination',
  icon: Icons.medical_services_outlined,
  path: 'medical-surveillance',
  titleOf: (r) => text(r['employeeName'], 'Employee'),
  subtitleOf: (r) => '${humanize(text(r['examinationType']))} · ${fmtDate(date(r['examinationDate']))}'
      '${r['fitnessDecision'] == null ? '' : ' · ${humanize(text(r['fitnessDecision']))}'}',
  statusKey: 'status',
  statusFilters: const ['PENDING', 'SCHEDULED', 'COMPLETED', 'OVERDUE', 'CANCELLED'],
  description: 'Kept by each company with its occupational health provider. The inspectorate sees the fitness outcome; '
      'clinical findings, vitals and test results stay confidential to the company.',
  details: const [
    DetailItem('Record', 'recordNumber'),
    DetailItem('Company', 'employer', ShowAs.company),
    DetailItem('Employee ID', 'employeeId'),
    DetailItem('Position', 'employeePosition'),
    DetailItem('Department', 'department'),
    DetailItem('Examination', 'examinationType', ShowAs.tag),
    DetailItem('Date', 'examinationDate', ShowAs.date),
    DetailItem('Next due', 'nextExaminationDate', ShowAs.date),
    DetailItem('Doctor', 'examiningDoctor'),
    DetailItem('Facility', 'medicalFacility'),
    DetailItem('Fitness', 'fitnessDecision', ShowAs.tag),
    DetailItem('Follow-up required', 'followUpRequired', ShowAs.boolean),
    DetailItem('Follow-up date', 'followUpDate', ShowAs.date),
    DetailItem('Blood pressure', 'bloodPressure'),
    DetailItem('Heart rate', 'heartRate', ShowAs.number),
    DetailItem('BMI', 'bmi', ShowAs.number),
    DetailItem('Vision', 'visionTest'),
    DetailItem('Hearing', 'hearingTest'),
    DetailItem('Lung function', 'lungFunctionTest'),
    DetailItem('Clinical findings', 'clinicalFindings', ShowAs.longText),
    DetailItem('Restrictions', 'restrictions', ShowAs.longText),
    DetailItem('Recommendations', 'recommendations', ShowAs.longText),
  ],
  createFields: [
    const FieldSpec('employeeName', 'Employee name', FieldKind.text, required: true),
    const FieldSpec('employeeId', 'Employee ID', FieldKind.text),
    const FieldSpec('employeePosition', 'Position', FieldKind.text),
    const FieldSpec('department', 'Department', FieldKind.text),
    _company,
    FieldSpec('examinationType', 'Examination', FieldKind.choice, required: true, initial: 'PERIODIC', options: opts(_examTypes)),
    const FieldSpec('examinationDate', 'Examination date', FieldKind.date, required: true),
    const FieldSpec('examiningDoctor', 'Examining doctor', FieldKind.text),
    const FieldSpec('medicalFacility', 'Medical facility', FieldKind.text),
  ],
  editFields: const [],
  actions: [
    ModuleAction(
      label: 'Record result',
      icon: Icons.assignment_turned_in_outlined,
      success: 'Result recorded',
      visible: (me, r) => me.isEmployer,
      fields: [
        FieldSpec('status', 'Status', FieldKind.choice, required: true, options: opts(const ['SCHEDULED', 'COMPLETED', 'OVERDUE', 'CANCELLED'])),
        FieldSpec('fitnessDecision', 'Fitness decision', FieldKind.choice, options: opts(_fitness)),
        const FieldSpec('clinicalFindings', 'Clinical findings', FieldKind.multiline),
        const FieldSpec('restrictions', 'Restrictions', FieldKind.multiline),
        const FieldSpec('recommendations', 'Recommendations', FieldKind.multiline),
        const FieldSpec('nextExaminationDate', 'Next examination', FieldKind.date),
        const FieldSpec('followUpRequired', 'Follow-up required', FieldKind.boolean),
      ],
    ),
  ],
);

// ---------------------------------------------------------------- equipment certification

final equipmentSpec = ModuleSpec(
  reviewType: 'EQUIPMENT_CERTIFICATION',
  canCreate: companyKeeps,
  canEdit: companyKeeps,
  canDelete: companyKeeps,
  id: 'equipment',
  title: 'Equipment certification',
  singular: 'Equipment certificate',
  icon: Icons.build_circle_outlined,
  path: 'equipment-certifications',
  titleOf: (r) => text(r['equipmentName'], 'Equipment'),
  subtitleOf: (r) => [text(r['equipmentType']), text(r['certificateNumber']), if (r['expiryDate'] != null) 'Expires ${fmtDate(date(r['expiryDate']))}']
      .where((s) => s.isNotEmpty)
      .join(' · '),
  statusKey: 'status',
  statusFilters: const ['PENDING', 'CERTIFIED', 'EXPIRED', 'SUSPENDED', 'REJECTED', 'RENEWAL_PENDING'],
  sort: (a, b) => text(a['expiryDate'], '9999').compareTo(text(b['expiryDate'], '9999')),
  details: const [
    DetailItem('Certificate', 'certificateNumber'),
    DetailItem('Company', 'employer', ShowAs.company),
    DetailItem('Type', 'equipmentType'),
    DetailItem('Manufacturer', 'manufacturer'),
    DetailItem('Model', 'model'),
    DetailItem('Serial number', 'serialNumber'),
    DetailItem('Certified by', 'certificationBody'),
    DetailItem('Standard', 'certificationStandard'),
    DetailItem('Issued', 'issuedDate', ShowAs.date),
    DetailItem('Expires', 'expiryDate', ShowAs.date),
    DetailItem('Last inspection', 'lastInspectionDate', ShowAs.date),
    DetailItem('Next inspection', 'nextInspectionDate', ShowAs.date),
    DetailItem('Location', 'location'),
    DetailItem('Inspector', 'inspectorName'),
    DetailItem('Safe to operate', 'safeToOperate', ShowAs.boolean),
    DetailItem('Findings', 'findings', ShowAs.longText),
    DetailItem('Limitations', 'limitations', ShowAs.longText),
    DetailItem('Maintenance', 'maintenanceRequirements', ShowAs.longText),
    DetailItem('Notes', 'notes', ShowAs.longText),
  ],
  createFields: const [
    FieldSpec('equipmentName', 'Equipment', FieldKind.text, required: true),
    _company,
    FieldSpec('equipmentType', 'Type', FieldKind.text, hint: 'e.g. Boiler, Crane, Pressure vessel'),
    FieldSpec('manufacturer', 'Manufacturer', FieldKind.text),
    FieldSpec('model', 'Model', FieldKind.text),
    FieldSpec('serialNumber', 'Serial number', FieldKind.text),
    FieldSpec('certificationBody', 'Certification body', FieldKind.text),
    FieldSpec('certificationStandard', 'Standard', FieldKind.text),
    FieldSpec('issuedDate', 'Issued', FieldKind.date),
    FieldSpec('expiryDate', 'Expires', FieldKind.date),
    FieldSpec('notes', 'Notes', FieldKind.multiline),
  ],
  actions: [
    ModuleAction(
      label: 'Renew certificate',
      icon: Icons.autorenew,
      success: 'Certification renewed',
      fields: const [FieldSpec('expiryDate', 'New expiry date', FieldKind.date, required: true)],
      fixed: const {'status': 'CERTIFIED'},
      visible: (me, r) => me.isEmployer,
    ),
  ],
);

// ---------------------------------------------------------------- hazardous materials

final hazmatSpec = ModuleSpec(
  reviewType: 'HAZARDOUS_MATERIAL',
  canCreate: companyKeeps,
  canEdit: companyKeeps,
  canDelete: companyKeeps,
  id: 'hazardousmaterials',
  title: 'Hazardous materials',
  singular: 'Hazardous material',
  icon: Icons.science_outlined,
  path: 'hazardous-materials',
  titleOf: (r) => text(r['name'], 'Material'),
  subtitleOf: (r) => [text(r['chemicalName']), if (r['quantity'] != null) '${fmtNum(r['quantity'])} ${text(r['unit'])}', text(r['storageLocation'])]
      .where((s) => s.trim().isNotEmpty)
      .join(' · '),
  statusKey: 'status',
  statusFilters: const ['ACTIVE', 'EXPIRED', 'DISPOSED', 'QUARANTINED'],
  toneKey: 'hazardLevel',
  details: const [
    DetailItem('Reference', 'referenceNumber'),
    DetailItem('Company', 'employer', ShowAs.company),
    DetailItem('Chemical name', 'chemicalName'),
    DetailItem('Classification', 'classification'),
    DetailItem('Hazard class', 'hazardClass'),
    DetailItem('Hazard level', 'hazardLevel', ShowAs.tag),
    DetailItem('UN number', 'unNumber'),
    DetailItem('CAS number', 'casNumber'),
    DetailItem('Quantity', 'quantity', ShowAs.number),
    DetailItem('Unit', 'unit'),
    DetailItem('Storage', 'storageLocation'),
    DetailItem('Supplier', 'supplier'),
    DetailItem('Expires', 'expirationDate', ShowAs.date),
    DetailItem('PPE required', 'ppeRequired', ShowAs.longText),
    DetailItem('Handling', 'handlingInstructions', ShowAs.longText),
    DetailItem('Emergency procedures', 'emergencyProcedures', ShowAs.longText),
    DetailItem('Disposal', 'disposalMethod', ShowAs.longText),
  ],
  createFields: [
    const FieldSpec('name', 'Name', FieldKind.text, required: true),
    _company,
    const FieldSpec('chemicalName', 'Chemical name', FieldKind.text),
    const FieldSpec('classification', 'Classification', FieldKind.text),
    const FieldSpec('hazardClass', 'Hazard class', FieldKind.text),
    const FieldSpec('hazardLevel', 'Hazard level', FieldKind.choice, required: true, initial: 'MEDIUM', options: [('LOW', 'Low'), ('MEDIUM', 'Medium'), ('HIGH', 'High'), ('EXTREME', 'Extreme')]),
    const FieldSpec('unNumber', 'UN number', FieldKind.text),
    const FieldSpec('casNumber', 'CAS number', FieldKind.text),
    const FieldSpec('quantity', 'Quantity', FieldKind.decimal, initial: 0),
    const FieldSpec('unit', 'Unit', FieldKind.choice, initial: 'kg', options: [('kg', 'kg'), ('L', 'litres'), ('tonnes', 'tonnes'), ('units', 'units')]),
    const FieldSpec('storageLocation', 'Storage location', FieldKind.text),
    const FieldSpec('supplier', 'Supplier', FieldKind.text),
    const FieldSpec('expirationDate', 'Expires', FieldKind.date),
    const FieldSpec('ppeRequired', 'PPE required', FieldKind.text),
    const FieldSpec('handlingInstructions', 'Handling instructions', FieldKind.multiline),
    const FieldSpec('emergencyProcedures', 'Emergency procedures', FieldKind.multiline),
  ],
);

// ---------------------------------------------------------------- legal & regulatory documents

final legislationSpec = ModuleSpec(
  id: 'legal',
  title: 'Legal & standards',
  singular: 'Legal instrument',
  icon: Icons.menu_book_outlined,
  path: 'legal/legislation',
  titleOf: (r) => text(r['title'], 'Legislation'),
  subtitleOf: (r) => [humanize(text(r['type'])), text(r['reference']), text(r['date'])].where((s) => s.isNotEmpty && s != '—').join(' · '),
  statusKey: 'status',
  statusFilters: const ['active', 'amended', 'repealed'],
  sort: (a, b) => text(a['title']).compareTo(text(b['title'])),
  details: const [
    DetailItem('Type', 'type', ShowAs.tag),
    DetailItem('Reference', 'reference'),
    DetailItem('Date', 'date'),
    DetailItem('Category', 'category'),
    DetailItem('Summary', 'description', ShowAs.longText),
    DetailItem('Full text', 'documentUrl', ShowAs.link),
  ],
  createFields: const [
    FieldSpec('title', 'Title', FieldKind.text, required: true),
    FieldSpec('type', 'Type', FieldKind.choice, required: true, initial: 'act',
        options: [('act', 'Act'), ('regulation', 'Regulation'), ('statutory_instrument', 'Statutory instrument'), ('ilo_convention', 'ILO convention')]),
    FieldSpec('reference', 'Reference', FieldKind.text, hint: 'e.g. Act No. 36 of 2010'),
    FieldSpec('date', 'Date', FieldKind.text, hint: 'e.g. 2010'),
    FieldSpec('status', 'Status', FieldKind.choice, initial: 'active', options: [('active', 'Active'), ('amended', 'Amended'), ('repealed', 'Repealed')]),
    FieldSpec('category', 'Category', FieldKind.text),
    FieldSpec('documentUrl', 'Link to full text', FieldKind.url),
    FieldSpec('description', 'Summary', FieldKind.multiline),
  ],
  editFields: const [], // the backend has no edit endpoint for legislation
);

// ---------------------------------------------------------------- training

final trainingProgramsSpec = ModuleSpec(
  id: 'trainingprograms',
  title: 'Training programmes',
  singular: 'Training programme',
  icon: Icons.school_outlined,
  path: 'training/courses',
  titleOf: (r) => text(r['title'], 'Course'),
  subtitleOf: (r) => [humanize(text(r['category'])), humanize(text(r['level'])), text(r['duration']), '${integer(r['enrolled']) ?? 0} enrolled']
      .where((s) => s.isNotEmpty && s != '—')
      .join(' · '),
  statusKey: 'status',
  statusFilters: const ['ACTIVE', 'INACTIVE'],
  details: const [
    DetailItem('Category', 'category', ShowAs.tag),
    DetailItem('Level', 'level', ShowAs.tag),
    DetailItem('Duration', 'duration'),
    DetailItem('Instructor', 'instructor'),
    DetailItem('Venue', 'venue'),
    DetailItem('Starts', 'startDate'),
    DetailItem('Places', 'maxParticipants', ShowAs.number),
    DetailItem('Enrolled', 'enrolled', ShowAs.number),
    DetailItem('Completed', 'completed', ShowAs.number),
    DetailItem('Cost', 'cost', ShowAs.money),
    DetailItem('About', 'description', ShowAs.longText),
  ],
  createFields: const [
    FieldSpec('title', 'Title', FieldKind.text, required: true),
    FieldSpec('category', 'Category', FieldKind.choice, initial: 'safety', options: [
      ('safety', 'Safety'), ('health', 'Health'), ('emergency', 'Emergency response'), ('first_aid', 'First aid'),
      ('fire_safety', 'Fire safety'), ('chemical', 'Chemical handling'), ('other', 'Other'),
    ]),
    FieldSpec('level', 'Level', FieldKind.choice, initial: 'beginner', options: [('beginner', 'Beginner'), ('intermediate', 'Intermediate'), ('advanced', 'Advanced')]),
    FieldSpec('duration', 'Duration', FieldKind.text, hint: 'e.g. 2 days'),
    FieldSpec('instructor', 'Instructor', FieldKind.text),
    FieldSpec('venue', 'Venue', FieldKind.text),
    FieldSpec('startDate', 'Start date', FieldKind.date),
    FieldSpec('maxParticipants', 'Places', FieldKind.integer, initial: 20, min: 1),
    FieldSpec('cost', 'Cost (K)', FieldKind.decimal, initial: 0),
    FieldSpec('status', 'Status', FieldKind.choice, initial: 'ACTIVE', options: [('ACTIVE', 'Active'), ('INACTIVE', 'Inactive')]),
    FieldSpec('description', 'About the course', FieldKind.multiline),
  ],
  editFields: const [], // the backend has no edit endpoint for courses
  actions: [
    ModuleAction(label: 'Enrol', icon: Icons.how_to_reg, postAction: 'enroll', success: 'Enrolled', visible: (me, r) => text(r['status'], 'ACTIVE') == 'ACTIVE'),
    ModuleAction(label: 'Record a completion', icon: Icons.school, postAction: 'complete', success: 'Completion recorded', visible: (me, r) => me.isStaff),
  ],
);

final resourcesSpec = ModuleSpec(
  id: 'training',
  title: 'Training & resources',
  singular: 'Resource',
  icon: Icons.library_books_outlined,
  path: 'resources',
  titleOf: (r) => text(r['title'], 'Resource'),
  subtitleOf: (r) => [text(r['type']), text(r['category']), '${integer(r['downloads']) ?? 0} downloads'].where((s) => s.isNotEmpty).join(' · '),
  statusKey: 'type',
  statusFilters: const ['Guide', 'Checklist', 'Template', 'Video', 'Course', 'Poster'],
  sort: (a, b) => text(a['title']).compareTo(text(b['title'])),
  details: const [
    DetailItem('Type', 'type'),
    DetailItem('Category', 'category'),
    DetailItem('Downloads', 'downloads', ShowAs.number),
    DetailItem('About', 'description', ShowAs.longText),
    DetailItem('Content', 'content', ShowAs.longText),
    DetailItem('Open resource', 'url', ShowAs.link),
  ],
  createFields: const [
    FieldSpec('title', 'Title', FieldKind.text, required: true),
    FieldSpec('type', 'Type', FieldKind.choice, initial: 'Guide',
        options: [('Guide', 'Guide'), ('Checklist', 'Checklist'), ('Template', 'Template'), ('Video', 'Video'), ('Course', 'Course'), ('Poster', 'Poster')]),
    FieldSpec('category', 'Category', FieldKind.text),
    FieldSpec('url', 'Link', FieldKind.url),
    FieldSpec('description', 'Description', FieldKind.multiline),
    FieldSpec('content', 'Content', FieldKind.multiline),
  ],
);
