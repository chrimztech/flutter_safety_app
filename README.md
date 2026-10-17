# OHS Mobile

The mobile app of the Occupational Health and Safety regulatory platform. It talks to the same Spring Boot backend as the
web console (`ohs-gvt-frontend/backend-springboot`), so every rule — who sees which agency's or company's data, sessions,
permissions — is enforced by the server exactly as on the web.

## Who uses it

The app has every screen of the web console, with the same role rules (taken from the web's navigation config and the
backend's permission checks):

| Section | Screens | Officer | Administrator | Company user |
|---|---|---|---|---|
| Main | Dashboard + quick actions, Analytics (government dashboard, statistics & injury rates, risk heat map), Employers (register with the full company profile, edit, sites, delete), Inspections (schedule, **checklist conducted on site**, outcome, photos), Inspection checklists, Compliance tracking, Compliance calendar | ✓ | ✓ (+ delete companies) | Own inspections, own company profile (editable fields only), own sites |
| Operations | Incidents, Complaints, Accident investigation, Corrective actions, Risk assessments, Enforcement, Permits & licences (issue, renew), Emergency response, Safety culture | ✓ create / edit / delete | ✓ | Own records; report incidents; complete actions with evidence |
| Health | Medical surveillance (record results), Equipment certification (renew), Hazardous materials | ✓ (medical: view) | ✓ | Equipment and materials of own company |
| Regulation | Legal & regulatory documents | ✓ add / delete | ✓ | read |
| Intelligence | IoT hazard alerts (acknowledge / resolve / false alarm, AI recommendations), devices (register, edit, new key, readings), Reports (generate, edit, submit, approve, publish, archive, CSV), Scheduled reports | ✓ (reports: read) | ✓ (+ schedules, approve) | Own alerts and devices |
| Training | Training & resources, Training programmes (enrol, completions) | ✓ | ✓ | resources, enrol |
| System | User management (one-time passwords, roles, reset, sign out, deactivate, delete), Audit log (filters, detail, verify integrity), Settings (agency profile, sign-in & session security), Notifications, My account | notifications, account | ✓ | notifications, account |

**Platform super-admin:** agencies (approve / reject applications, add, edit, suspend / reactivate, add administrators
and officers, delete with code confirmation), platform users, active sessions, platform audit, companies across
agencies, and **support mode** — enter an agency to work in it as its administrator (a banner shows it; everything is
recorded in that agency's audit log).

**No account:** report a safety concern anonymously (or with contact details) and track it with the reference number
and tracking code.

Everyone: first sign-in forces a password change, forgot password, signed-in devices (sign others out), change password,
server address, sign out. When the server ends a session (idle timeout, signed out elsewhere, password changed,
account deactivated) the app returns to the sign-in screen and says why.

## Working in the field

* **Offline checklists.** Each inspection checklist is saved on the phone when it is opened. Without a connection the
  inspector can still record Pass / Fail / N/A and notes; the results are kept on the phone and sent automatically
  when the connection returns (next time the checklist is opened, or by the background check every minute). A banner
  shows when results are waiting to be sent.
* **Phone notifications.** While the app is open or in the background it checks for new notifications every minute
  and shows new ones (hazard alerts, regulator reviews, permit decisions…) as phone notifications. Delivery when the app
  has been closed needs push messaging (Firebase Cloud Messaging) — see *Before publishing*.
* **Duty holder.** Companies keep their own registers (risk assessments, chemicals, equipment, emergency log, medical
  surveillance, safety culture), apply for permits and register their own sensors; inspectors review the registers and
  decide applications. Each register record shows its current regulator review.

## Release build

1. Create an upload key once (keep it safe — it signs every future update):

   ```
   keytool -genkey -v -keystore %USERPROFILE%\ohs-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (it is git-ignored):

   ```
   storeFile=C:\\Users\\<you>\\ohs-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

3. Build against the agency's **https** server (release builds refuse plain http):

   ```
   flutter build appbundle --dart-define=OHS_API_URL=https://ohs.example.gov
   ```

Without `key.properties` a release build is signed with the debug key — fine for testing, not accepted by the Play Store.

## Before publishing

* **Application ID** — still `com.example.flutter_app_scaffold` (Android `applicationId`/`namespace` in
  `android/app/build.gradle.kts`, the `MainActivity.kt` package folder, and iOS `PRODUCT_BUNDLE_IDENTIFIER`). It is
  permanent once published. The Firebase project (`android/app/google-services.json`) is registered for the current ID,
  so register the new ID in Firebase and download a new `google-services.json` when you change it.
* **Push when the app is closed** — needs Firebase Cloud Messaging: the server sends to device tokens the app registers.

## Running

1. Start the backend (see the platform's `GETTING_STARTED.md`). It listens on port 8080.
2. Run the app:

   ```
   flutter pub get
   flutter run                      # pick an emulator, a phone, Chrome or Windows
   ```

3. Server address — tap the server icon on the sign-in screen, or build with a default:
   * Android emulator → `http://10.0.2.2:8080` (the default on Android)
   * Chrome / Windows / iOS simulator on the same computer → `http://localhost:8080` (the default elsewhere)
   * A real phone → the computer's LAN address, e.g. `http://192.168.1.20:8080` (same Wi-Fi)
   * Production → `https://…` of the agency's server, or `flutter build apk --dart-define=OHS_API_URL=https://ohs.example.gov`

   "Test connection" checks the address before saving.

`http://` is allowed for development (Android `usesCleartextTraffic`, iOS local networking). Use `https://` in production.

## Structure

```
lib/
  data/       pure Dart — no Flutter imports
    fields.dart       declarative form fields (backend keys, kinds, options)
    company_profile.dart  GENERATED from the web app's companyProfile.ts (same 94 company fields)
    api_client.dart   HTTP (dio): token, server error messages, session-ended callback, background requests
    ohs_api.dart      every backend call the app makes
    models.dart       typed records (incidents, inspections, alerts, reports, …)
    json.dart         tolerant JSON readers
  app/        session (secure token storage, validation at start-up, unread-notification polling), server config
  ui/         theme, formatting, shared widgets, searchable/filterable record list
  modules/    data-driven record types (investigations, risk assessments, permits, emergency, safety culture,
              medical, equipment, hazardous materials, legal, training) — one spec each, generic list/detail/form
  screens/    auth, public, home (role-specific menu + quick actions), incidents, inspections (+ checklist),
              iot (+ devices), complaints, companies (+ register, sites), enforcement, actions, reports
              (+ generate, schedules), intelligence (analytics, calendar, compliance), admin (users, audit,
              settings), platform (console, support mode), notifications, account
```

Lists come from the backend in full and are searched and filtered on the device. Background polling sends
`X-Background: 1` so it does not keep an idle session alive.

## Tests

```
flutter analyze
flutter test                                              # models, formatting, sign-in screen

# Against a running TEST backend with the regression fixture accounts:
dart run tool/api_smoke_test.dart http://localhost:8081   # every endpoint the app uses, all three kinds of account
flutter test test/live_backend_test.dart --dart-define=OHS_LIVE_URL=http://localhost:8081   # every screen renders on real data, per role
flutter test test/live_modules_test.dart --dart-define=OHS_LIVE_URL=http://localhost:8081   # every form's payload accepted by the backend (creates and deletes records)
```

The smoke test is read-only except that it submits one public test report and adds a note to one hazard alert —
run it against a test backend, not production.

To regenerate the company profile fields after changing the web form:
`node --experimental-strip-types tool/gen_company_profile.mjs <web app>/src/constants/companyProfile.ts`
(writes `lib/data/company_profile.dart`).
