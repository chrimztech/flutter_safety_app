import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../modules/specs.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/widgets.dart';
import '../companies/company_tools.dart';
import '../common/record_forms.dart';
import '../incidents/report_incident_screen.dart';
import '../inspections/inspections_screen.dart';
import '../iot/device_screens.dart';
import '../reports/report_tools.dart';

/// The web top bar's quick actions, for the signed-in role.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, this.onDone});

  /// Called after an action created something (to refresh the home screen).
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    Future<void> run(Future<bool> Function() action) async {
      if (await action()) onDone?.call();
    }

    final actions = <(IconData, String, Future<bool> Function())>[
      if (me.isEmployer || me.can('incidents:write'))
        (Icons.add_alert, 'Report incident', () async => await context.push<bool>(const ReportIncidentScreen()) == true),
      if (me.isStaff && me.can('inspections:write')) (Icons.event_available, 'Schedule inspection', () => scheduleInspection(context)),
      if (me.can('complaints:write')) (Icons.add_comment_outlined, 'New complaint', () => lodgeComplaint(context)),
      if (me.isStaff && me.can('employers:write')) (Icons.add_business, 'Register company', () => registerCompany(context)),
      (Icons.sensors, 'Register IoT device', () => registerDevice(context)),
      if (me.isEmployer)
        (Icons.edit_note, 'Update company profile', () async {
          final c = await context.api.myCompany();
          return context.mounted && await editCompany(context, c.raw, mine: true);
        }),
      if (me.isStaff) (Icons.gavel, 'Issue enforcement action', () => issueEnforcement(context)),
      if (me.isEmployer)
        (Icons.verified_outlined, 'Apply for a permit', () async {
          final saved = await context.push<Object?>(FormScreen(
            title: 'Apply for a permit',
            sections: [FieldSection('', '', '', permitsSpec.companyCreateFields!)],
            submitLabel: 'Submit application',
            onSubmit: (p) => context.api.create(permitsSpec.path, p),
          ));
          if (saved != null && context.mounted) showMessage(context, 'Application submitted - the inspectorate has been notified');
          return saved != null;
        }),
      if (me.isStaff && me.can('employers:write'))
        (Icons.verified_outlined, 'Issue permit', () async {
          final saved = await context.push<Object?>(FormScreen(
            title: 'Issue permit',
            sections: [FieldSection('', '', '', permitsSpec.createFields)],
            submitLabel: 'Issue permit',
            onSubmit: (p) => context.api.create(permitsSpec.path, {...permitsSpec.createExtras, ...p}),
          ));
          if (saved != null && context.mounted) showMessage(context, 'Permit issued');
          return saved != null;
        }),
      if (me.isStaff) (Icons.add_task, 'Raise corrective action', () => raiseCorrectiveAction(context)),
      if (me.can('reports:write')) (Icons.add_chart, 'Generate report', () async {
        await generateReport(context);
        return true;
      }),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return Section(title: 'Quick actions', children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (icon, label, action) in actions)
          ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: () => run(action)),
      ]),
    ]);
  }
}
