// Generates lib/data/company_profile.dart from the web app's company profile definition,
// so both apps ask for exactly the same company fields.
//   node --experimental-strip-types tool/gen_company_profile.mjs <path to web app>/src/constants/companyProfile.ts
import { writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
const source = process.argv[2];
if (!source) {
  console.error('Usage: node --experimental-strip-types tool/gen_company_profile.mjs <web app>/src/constants/companyProfile.ts');
  process.exit(1);
}
const m = await import(pathToFileURL(source).href);

const q = (s) => s == null ? 'null' : `'${String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$')}'`;
const opts = (o) => !o ? 'null' : `[${o.map(([v, l]) => `(${q(v)}, ${q(l)})`).join(', ')}]`;

let out = `// GENERATED from the web app's src/constants/companyProfile.ts — do not edit by hand.
// Regenerate with: node --experimental-strip-types tool/gen_company_profile.mjs <web app>/src/constants/companyProfile.ts
import 'fields.dart';

/// The company registration profile, section by section. [FieldSpec.employerEditable] marks what a company may
/// update itself (the server enforces the same list).
const companyProfileSections = <FieldSection>[
`;
for (const s of m.PROFILE_SECTIONS) {
  out += `  FieldSection(${q(s.id)}, ${q(s.title)}, ${q(s.description)}, [\n`;
  for (const f of s.fields) {
    const kind = { text: 'text', email: 'email', tel: 'phone', number: 'integer', decimal: 'decimal', date: 'date', url: 'url',
      textarea: 'multiline', select: 'choice', bool: 'boolean', multiselect: 'multiChoice' }[f.type] ?? 'text';
    out += `    FieldSpec(${q(f.key)}, ${q(f.label)}, FieldKind.${kind}` +
      (f.required ? ', required: true' : '') +
      (f.options ? `, options: ${opts(f.options)}` : '') +
      (f.placeholder ? `, hint: ${q(f.placeholder)}` : '') +
      (f.help ? `, help: ${q(f.help)}` : '') +
      (f.employer ? ', employerEditable: true' : '') + '),\n';
  }
  out += '  ]),\n';
}
out += '];\n\n/// Every profile field, flat.\nfinal companyProfileFields = [for (final s in companyProfileSections) ...s.fields];\n\n';
out += `const companySiteTypes = ${opts(m.SITE_TYPES)};\n`;
writeFileSync(new URL('../lib/data/company_profile.dart', import.meta.url), out);
console.log('sections', m.PROFILE_SECTIONS.length, 'fields', m.PROFILE_SECTIONS.reduce((a, s) => a + s.fields.length, 0));
